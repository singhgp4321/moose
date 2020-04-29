//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "SurrogateModel.h"

#include <mlpack/methods/linear_regression/linear_regression.hpp>

class LinearRegressionModel : public SurrogateModel
{
public:
  static InputParameters validParams();
  LinearRegressionModel(const InputParameters & parameters);
  virtual Real evaluate(const std::vector<Real> & x) const override;

private:
  ///@{
  /// Slope/intercept from trainer
  const Real & _slope;
  const Real & _intercept;
  ///@}
};
