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

  MultiMooseEnum errors("INPUT_EMPTY=1 INPUT_SIZE_MISMATCH=2 ALL=100 NONE=0", "ALL");
  params.addParam<MultiMooseEnum>(
      "errors", errors, "Dictate the errors to produce when performing training.");
  return params;
}

LinearRegressionTrainer::LinearRegressionTrainer(const InputParameters & parameters)
  : SurrogateTrainer(parameters),
    _independent_variable(
        getVectorPostprocessorValue("input_vpp", getParam<std::string>("independent_vector"))),
    _dependent_variable(
        getVectorPostprocessorValue("input_vpp", getParam<std::string>("dependent_vector"))),
    _errors(getParam<MultiMooseEnum>("errors")),
    _slope(declareModelData<Real>("slope")),
    _intercept(declareModelData<Real>("intercept"))
{
}

void
LinearRegressionTrainer::execute()
{
  errorCheckHelper();

  // Define the predictors with an Armadillo data "mat" data structure
  // The data must be provided in rows [_dependent_variable.size(), 1], but the std::vector
  // constructor creates a column vector.
  arma::mat predictors(_independent_variable);
  arma::inplace_trans(predictors);

  // Define the responses with an Armadillo rowvec
  arma::rowvec responses(_dependent_variable);

  // Train the model and store the results
  mlpack::regression::LinearRegression lr;
  lr.Train(predictors, responses, true);

  // Store the trained data
  _slope = lr.Parameters()[0];
  _intercept = lr.Parameters()[1];
}

void
LinearRegressionTrainer::errorCheckHelper() const
{
  if (_errors.contains(100) || _errors.contains(1))
  {
    if (_independent_variable.empty())
      paramError("independent_vector", "The independent variable data is empty.");
    if (_dependent_variable.empty())
      paramError("dependent_vector", "The independent variable data is empty.");
  }
  if (_errors.contains(100) || _errors.contains(2))
  {
    if (_independent_variable.size() != _independent_variable.size())
      paramError(
          "independent_vector",
          "The independent variable data must be the same size as the dependent variable data.");
  }
}
