//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "InterfaceMaterial.h"

/**
 * Declares material properties on an interface boundary with values drawn from
 * a standard (non-volume-weighted) Weibull distribution. Each property receives
 * its own median and Weibull modulus. Values are drawn once during
 * initialization and held constant thereafter via stateful properties.
 */
class WeibullInterfaceMaterial : public InterfaceMaterial
{
public:
  static InputParameters validParams();
  WeibullInterfaceMaterial(const InputParameters & parameters);

protected:
  void initQpStatefulProperties() override;
  void computeQpProperties() override;

private:
  /// Median values for each property
  const std::vector<Real> & _medians;

  /// Weibull moduli for each property
  const std::vector<Real> & _weibull_moduli;

  /// Declared material properties (current)
  std::vector<MaterialProperty<Real> *> _properties;

  /// Declared material properties (old, for stateful persistence)
  std::vector<const MaterialProperty<Real> *> _properties_old;
};
