//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "EnthalpyMaterial.h"

registerMooseObject("HeatTransferApp", EnthalpyMaterial);

InputParameters
EnthalpyMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes enthalpy and its derivative with respect to concentration "
      "from coupled temperature and concentration variables.");
  params.addRequiredCoupledVar("temperature", "The temperature variable");
  params.addRequiredCoupledVar("concentration", "The concentration variable");
  return params;
}

EnthalpyMaterial::EnthalpyMaterial(const InputParameters & parameters)
  : Material(parameters),
    _temperature(coupledValue("temperature")),
    _concentration(coupledValue("concentration")),
    _enthalpy(declareProperty<Real>("enthalpy")),
    _dH_dc(declareProperty<Real>("dH_dc"))
{
}

void
EnthalpyMaterial::computeQpProperties()
{
  _enthalpy[_qp] = 200.0 * _temperature[_qp] + 300.0 * _concentration[_qp];
  _dH_dc[_qp] = 300.0;
}
