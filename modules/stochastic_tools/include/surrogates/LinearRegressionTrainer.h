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

#include "mlpack/core.hpp"

#include "SurrogateTrainer.h"

class LinearRegressionTrainer : public SurrogateTrainer
{
public:
  static InputParameters validParams();
  LinearRegressionTrainer(const InputParameters & parameters);
  virtual void initialSetup() override;
  virtual void initialize() override;
  virtual void execute() override;
  virtual void finalize() override;

protected:
  /// Map containing sample points and the results
  // std::vector<std::vector<Real>> & _sample_points;

private:
  /// Sampler from which the parameters were perturbed
  // Sampler * _sampler = nullptr;

  ///@{
  /// VPP training data
  const arma::vec _dependent_variable;
  // const VectorPostprocessorValue & _independent_variable;
  const VectorPostprocessorValue & _dependent_variable;
  ///@}

  /// True when _sampler data is distributed
  // bool _values_distributed = false; // default to false; set in initialSetup
};
