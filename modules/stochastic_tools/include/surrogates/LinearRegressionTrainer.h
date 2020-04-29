//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

/*
namespace arma
{
class vec;
}
*/

//#include "mlpack/core.hpp"

#include "SurrogateTrainer.h"

class LinearRegressionTrainer : public SurrogateTrainer
{
public:
  static InputParameters validParams();
  LinearRegressionTrainer(const InputParameters & parameters);
  virtual void execute() override;

private:
  /// Helper for performing optional error checking prior to training
  void errorCheckHelper() const;

  ///@{
  /// VPP training data
  const VectorPostprocessorValue & _independent_variable;
  const VectorPostprocessorValue & _dependent_variable;
  ///@}

  // The desired warnings to produce during training
  const MultiMooseEnum & _errors;

  // Storage for the trained data (slope/intercept for a linear equation)
  Real & _slope;
  Real & _intercept;
};
