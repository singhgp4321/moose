//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "LinearRegressionTrainer.h"

#include <mlpack/methods/linear_regression/linear_regression.hpp>

registerMooseObject("StochasticToolsApp", LinearRegressionTrainer);

InputParameters
LinearRegressionTrainer::validParams()
{
  InputParameters params = SurrogateTrainer::validParams();
  params.addClassDescription("Performs machine learning based linear regression using mlpack.");
  params.addRequiredParam<VectorPostprocessorName>(
      "input_vpp", "Vectorpostprocessor containing the data for the trainer.");
  params.addRequiredParam<std::string>(
      "independent_vector", "The vector name from 'input_vpp' to use as the independent variable.");
  params.addRequiredParam<std::string>(
      "dependent_vector", "The vector name from 'input_vpp' to use as the dependent variable.");
  return params;
}

LinearRegressionTrainer::LinearRegressionTrainer(const InputParameters & parameters)
  : SurrogateTrainer(parameters),
    _independent_variable(getVectorPostprocessorValue("input_vpp", "independent_vector")),
    _dependent_variable(getVectorPostprocessorValue("input_vpp", "dependent_vector"))
{
}

void
LinearRegressionTrainer::initialSetup()
{
}

void
LinearRegressionTrainer::initialize()
{
}

void
LinearRegressionTrainer::execute()
{
}

void
LinearRegressionTrainer::finalize()
{
}
