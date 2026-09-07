//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "WeibullInterfaceMaterial.h"

registerMooseObject("SolidMechanicsApp", WeibullInterfaceMaterial);

InputParameters
WeibullInterfaceMaterial::validParams()
{
  InputParameters params = InterfaceMaterial::validParams();
  params.addClassDescription(
      "Declares interface material properties with values drawn from a Weibull distribution.");
  params.addRequiredParam<std::vector<MaterialPropertyName>>(
      "prop_names", "Names of the material properties to declare.");
  params.addRequiredParam<std::vector<Real>>(
      "medians",
      "Median value of each property (value at 50th percentile). One per property.");
  params.addRequiredParam<std::vector<Real>>(
      "weibull_moduli", "Weibull modulus (shape parameter) for each property. One per property.");
  return params;
}

WeibullInterfaceMaterial::WeibullInterfaceMaterial(const InputParameters & parameters)
  : InterfaceMaterial(parameters),
    _medians(getParam<std::vector<Real>>("medians")),
    _weibull_moduli(getParam<std::vector<Real>>("weibull_moduli"))
{
  const auto & prop_names = getParam<std::vector<MaterialPropertyName>>("prop_names");
  const auto n = prop_names.size();

  if (_medians.size() != n || _weibull_moduli.size() != n)
    mooseError("The lengths of 'prop_names', 'medians', and 'weibull_moduli' must match.");

  for (const auto i : make_range(n))
  {
    _properties.push_back(&declareProperty<Real>(prop_names[i]));
    _properties_old.push_back(&getMaterialPropertyOld<Real>(prop_names[i]));
  }

  setRandomResetFrequency(EXEC_INITIAL);
}

void
WeibullInterfaceMaterial::initQpStatefulProperties()
{
  // Draw from a standard Weibull distribution:
  //   value = median * (ln(U) / ln(0.5))^(1/m)
  // where U is uniform on (0,1) and m is the Weibull modulus.
  for (const auto i : index_range(_properties))
  {
    const Real U = getRandomReal();
    (*_properties[i])[_qp] =
        _medians[i] * std::pow(std::log(U) / std::log(0.5), 1.0 / _weibull_moduli[i]);
  }
}

void
WeibullInterfaceMaterial::computeQpProperties()
{
  // Preserve the initial random values across all timesteps
  for (const auto i : index_range(_properties))
    (*_properties[i])[_qp] = (*_properties_old[i])[_qp];
}
