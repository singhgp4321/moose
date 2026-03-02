//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "ADEnthalpyMaterial.h"

registerMooseObject("HeatTransferApp", ADEnthalpyMaterial);

InputParameters
ADEnthalpyMaterial::validParams()
{
  InputParameters params = ADMaterial::validParams();
  params.addClassDescription(
      "Computes enthalpy and its derivative with respect to concentration "
      "from coupled temperature and concentration variables.");
  params.addRequiredCoupledVar("temperature", "The temperature variable");
  params.addRequiredCoupledVar("concentration", "The concentration variable");
  return params;
}

ADEnthalpyMaterial::ADEnthalpyMaterial(const InputParameters & parameters)
  : ADMaterial(parameters),
    _temperature(adCoupledValue("temperature")),
    _concentration(adCoupledValue("concentration")),
    _enthalpy(declareADProperty<Real>("enthalpy")),
    _dH_dc(declareADProperty<Real>("dH_dc"))
{
}

void
ADEnthalpyMaterial::computeQpProperties()
{
  _enthalpy[_qp] = 200.0 * _temperature[_qp] + 300.0 * _concentration[_qp];
  _dH_dc[_qp] = 300.0;
}
