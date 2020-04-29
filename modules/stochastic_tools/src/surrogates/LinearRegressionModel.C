//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "LinearRegressionModel.h"

#include <mlpack/methods/linear_regression/linear_regression.hpp>

registerMooseObject("StochasticToolsApp", LinearRegressionModel);

InputParameters
LinearRegressionModel::validParams()
{
  InputParameters params = SurrogateModel::validParams();
  params.addClassDescription("Surrogate model that evaluates a value from a linear regression "
                             "trainer [LinearRegressionTrainer.md]");
  return params;
}

LinearRegressionModel::LinearRegressionModel(const InputParameters & parameters)
  : SurrogateModel(parameters),
    _slope(getModelData<Real>("slope")),
    _intercept(getModelData<Real>("intercept"))
{
}

Real
LinearRegressionModel::evaluate(const std::vector<Real> & x) const
{
  mooseAssert(x.size() == 1, "The input vector must be a single value.");

  mlpack::regression::LinearRegression lr;
  arma::vec items = {_intercept, _slope};
  lr.Parameters() = items;

  arma::mat points(x);
  arma::rowvec predictions;
  lr.Predict(points, predictions);

  return predictions[0];
}
