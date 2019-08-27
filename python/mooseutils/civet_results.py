#!/usr/bin/env python
#* This file is part of the MOOSE framework
#* https://www.mooseframework.org
#*
#* All rights reserved, see COPYRIGHT for full restrictions
#* https://github.com/idaholab/moose/blob/master/COPYRIGHT
#*
#* Licensed under LGPL 2.1, please see LICENSE for details
#* https://www.gnu.org/licenses/lgpl-2.1.html
import os
import re
import enum
import glob
import tarfile
import urllib.request
import urllib.error
import collections
import logging

DEFAULT_JOBS_CACHE = os.path.join(os.getenv('HOME'), '.local', 'share', 'civet', 'jobs')
DEFAULT_CIVET_SITE = 'https://civet.inl.gov'
DEFAULT_CIVET_REPO = 'idaholab/moose'

TEST_RE = re.compile(r'^(?:\[(?P<time>.+?)s\])?'       # Optional test time
                     r' *(?P<status>[A-Z]+?)'          # Test status (e.g., OK)
                     r' +(?P<test>.*?)'                # Test name
                     r'(?: +(?P<reason>.*?))?'         # reason FAILED (FAILED (ERRORMSG))
                     r'(?: *\[(?P<caveats>.*?)\])?$',  # Test caveats (e.g., [min_cpus=1])
                     flags=re.MULTILINE)

JOB_RE = re.compile(r'id=\"job_(?P<job>\d+)\"')
RECIPE_RE = re.compile(r'results_(?P<number>\d+)_(?P<job>.*)/(?P<recipe>.*)')
RUN_TESTS_START_RE = re.compile(r'^.+?run_tests.+?$', flags=re.MULTILINE)
RUN_TESTS_END_RE = re.compile(r'^-{5,}$', flags=re.MULTILINE)

Test = collections.namedtuple('Test', 'recipe status caveats reason time url')
Job = collections.namedtuple('Job', 'number filename status url')

class JobFileStatus(enum.Enum):
    """Status flag for Job file downloads"""
    CACHE = 0
    DOWNLOAD = 1
    FAIL = 2

def _get_civet_jobs(hashes, site, repo, cache=DEFAULT_JOBS_CACHE, logger=None):
    """
    Get a list of Job objects for the supplied git SHA1 strings.
    """

    jobs = set()
    for sha1 in hashes:
        url = '{}/sha_events/{}/{}'.format(site, repo, sha1)

        # TODO: Error catch
        pid = urllib.request.urlopen(url)
        page = pid.read().decode('utf8')

        for match in JOB_RE.finditer(page):
            job = jobs.add(_download_job(int(match.group('job')), site, cache, logger))

    return sorted(jobs, key=lambda j: j.number)

def _download_job(job, site, cache, logger):
    """
    Download, if it doesn't already exist, the raw data file from CIVET testing given a Job object.
    """

    if not os.path.isdir(cache):
        os.makedirs(cache)

    url = '{}/job_results/{}'.format(site, job)
    filename = '{}/job_{}.tar.gz'.format(cache, job)

    status = None
    if os.path.isfile(filename):
        if logger:
            logger.debug('Using cached results for job %s', job)
        status = JobFileStatus.CACHE

    else:
        try:
            response = urllib.request.urlopen(url)
            if response.code == 200:
                if logger:
                    logger.debug('Downloading results for job %s', job)
                with open(filename, 'wb') as fid:
                    fid.write(response.read())
                status = JobFileStatus.DOWNLOAD

        except urllib.error.HTTPError:
            if logger:
                logger.warning('Failed to download results for job %s: %s', job, url)
            status = JobFileStatus.FAIL

    return Job(job, filename, status, site)

def _update_database_from_job(job, database, possible):
    """
    Update the test result database given a Job object.
    """

    if job.status == JobFileStatus.FAIL:
        return

    tar = tarfile.open(job.filename, 'r:gz')
    for member in tar.getmembers():
        match = RECIPE_RE.search(member.name)
        recipe = match.group('recipe')
        number = int(match.group('number'))

        f = tar.extractfile(member)
        if f is not None:
            content = f.read().decode('utf8')
            begin = RUN_TESTS_START_RE.search(content)
            if begin is None:
                continue
            end = RUN_TESTS_END_RE.search(content)
            if end is not None:
                _process_results(database, job, recipe, content[begin.end():end.start()], possible)

def _process_results(database, job, recipe, content, possible):
    """
    Extract results from run_tests and update the database.
    """
    for match in TEST_RE.finditer(content):
        caveats = match.group('caveats')
        reason = match.group('reason')
        if caveats is not None:
            caveats = caveats.split(',')

        time = match.group('time')
        if time is not None:
            time = float(time)

        tname = match.group('test').split(':')[-1]
        status = match.group('status')
        if (possible is None) or (status in possible):
            database[tname][job.number].append(Test(recipe, status, caveats, reason, time, job.url))

def get_civet_results(hashes, possible=None,
                      sites=[(DEFAULT_CIVET_SITE, DEFAULT_CIVET_REPO)],
                      cache=DEFAULT_JOBS_CACHE, logger=None):

    database = collections.defaultdict(lambda: collections.defaultdict(list))
    for site, repo in sites:
        jobs = _get_civet_jobs(hashes, site, repo, cache=cache, logger=logger)
        for job in jobs:
            _update_database_from_job(job, database, possible)
    return database


if __name__ == '__main__':
    database = civet_results(['681ba2f4274dc8465bb2a54e1353cfa24765a5c1',
                              'febe3476040fe6af1df1d67e8cc8c04c4760afb6'])
