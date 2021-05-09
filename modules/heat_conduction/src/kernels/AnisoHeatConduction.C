//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "AnisoHeatConduction.h"
#include "MooseMesh.h"

registerMooseObject("HeatConductionApp", AnisoHeatConduction);

InputParameters
AnisoHeatConduction::validParams()
{
  InputParameters params = Kernel::validParams();
  params.set<bool>("use_displaced_mesh") = true;
  return params;
}

AnisoHeatConduction::AnisoHeatConduction(const InputParameters & parameters)
  : Kernel(parameters), _dim(_subproblem.mesh().dimension())
{
  _k = nullptr;
  _k_dT = nullptr;

  if (hasMaterialProperty<RankTwoTensor>("thermal_conductivity"))
    _k = &getMaterialProperty<RankTwoTensor>("thermal_conductivity");

  if (hasMaterialProperty<RankTwoTensor>("thermal_conductivity_dT"))
    _k_dT = &getMaterialProperty<RankTwoTensor>("thermal_conductivity_dT");

  if (!_k(0,0))
    mooseError("No thermal conductivity was defined");

  if (!_k(0,0) && _k(1,1))
    mooseError("Cannot define y conductivity but not x");

  if (_k(2,2) && (!_k(0,0) || !_k(1,1)))
    mooseError("Cannot define z conductivty but not x and y");

  if (_dim == 2 && !_k(1,1))
    mooseError("Must define x and y thermal conductivities for 2D");

  if (_dim == 3 && (!_k(1,1) || !_k(2,2)))
    mooseError("Must define x, y, and z thermal conductivities for 3D");

  if (_dim == 2 && !(_k_dT(0,0) && _k_dT(1,1)))
    mooseError("Must define k_dT_xx and k_dT_yy for 2D");

  if (_dim == 3 && !(_k_dT(0,0) && _k_dT(1,1) && _k_dT(2,2)))
    mooseError("Must define thermal_conductivity_x_dT, thermal_conductivity_y_dT
               and thermal_conductivity_z_dT for 3D");

}

Real
AnisoHeatConduction::computeQpResidual()
{
  Real res(0);
  //   r = _k[_qp]*Diffusion::computeQpResidual();
  //   if (!libmesh_isnan(r))
  //   {
  //   }
  //   else
  //   {
  //     Moose::err << "NaN found at " << __LINE__ << " in " << __FILE__ << "!\n"
  //               << "Processor: " << libMesh::processor_id() << "\n"
  //               << "_k[_qp]: " << _k[_qp] << "\n"
  //               << "Diffusion resid: " << Diffusion::computeQpResidual() << "\n"
  //               << "Elem: " << _current_elem->id() << "\n"
  //               << "Qp: " << _qp << "\n"
  //               << "Qpoint: " << _q_point[_qp] << "\n"
  //               << std::endl;
  //   }
  //   return r;
  for (unsigned i(0); i < _dim; ++i)
    for (unsigned j(0); j < _dim; ++j)
    {
      res += _grad_test[_i][_qp](i) * (*_k(i,j))[_qp] * _grad_u[_qp](j);
    }
  return res;
}

Real
AnisoHeatConduction::computeQpJacobian()
{
  Real jac(0);
  for (unsigned i(0); i < _dim; ++i)
    for (unsigned j(0); j < _dim; ++j)
    {
      jac += _grad_test[_i][_qp](i) * (*_k(i,j))[_qp] * _grad_phi[_j][_qp](j);
      if (_k_dT(i,j))
      {
        jac += (*_k_dT(i,j))[_qp] * _phi[_j][_qp] *
              (_grad_test[_i][_qp](i) *  _grad_u[_qp](j));
      }
    }
  return jac;
}
