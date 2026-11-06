# Uniaxial tensile test on a tubular specimen (single homogeneous orthotropic layer)
# Axisymmetric (RZ) formulation: x = r, y = z_axial, out-of-plane = theta
#
# Inner radius: 3.94 mm, Outer radius: 4.79 mm (wall = 0.85 mm)
# Tube length: 65 mm
# Applied axial strain: 0.05%

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

r_in = 3.94e-3
r_out = 4.79e-3
tube_length = 65e-3
applied_strain = 0.0005
applied_disp = ${fparse applied_strain * tube_length}

[Mesh]
  coord_type = RZ
  [gen]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = ${r_in}
    xmax = ${r_out}
    ymin = 0
    ymax = ${tube_length}
    nx = 10
    ny = 650
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = SMALL
        add_variables = true
        use_automatic_differentiation = true
        generate_output = 'stress_yy strain_yy'
      []
    []
  []
[]

[Materials]
  # Voigt stiffness (symmetric9) in RZ frame: x=r, y=z_axial, z=theta
  # 0/90 plain weave: E_r=80, E_z=E_theta=260 GPa
  # C11(rr) C12(rz) C13(r-theta) C22(zz) C23(z-theta) C33(theta-theta) C44 C55 C66
  [elasticity]
    type = ADComputeElasticityTensor
    fill_method = symmetric9
    C_ijkl = '91.8733e9 45.6664e9 45.6664e9 288.6836e9 62.5966e9 288.6836e9 60e9 80e9 80e9'
  []
  [stress]
    type = ADComputeLinearElasticStress
  []
[]

[BCs]
  # Constrain radial displacement on bottom and top to preserve cross-section shape
  [fix_r_bottom]
    type = ADDirichletBC
    variable = disp_x
    boundary = bottom
    value = 0
  []
  [fix_r_top]
    type = ADDirichletBC
    variable = disp_x
    boundary = top
    value = 0
  []
  # Fix axial displacement on bottom
  [fix_z_bottom]
    type = ADDirichletBC
    variable = disp_y
    boundary = bottom
    value = 0
  []
  # Apply axial displacement on top (0.05% strain)
  [pull_z_top]
    type = ADDirichletBC
    variable = disp_y
    boundary = top
    value = ${applied_disp}
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON

  petsc_options_iname = '-ksp_gmres_restart -pc_type'
  petsc_options_value = '101                lu'
  line_search = 'none'

  l_max_its = 100
  l_tol = 1e-6

  nl_max_its = 20
  nl_rel_tol = 1e-10
  nl_abs_tol = 1e-6
[]

[Postprocessors]
  [sigma_yy]
    type = SideAverageValue
    boundary = top
    variable = stress_yy
    execute_on = 'initial timestep_end'
  []
  [strain_yy]
    type = SideAverageValue
    boundary = top
    variable = strain_yy
    execute_on = 'initial timestep_end'
  []
  [evaluated_modulus]
    type = ParsedPostprocessor
    expression = 'sigma_yy / strain_yy'
    pp_names = 'sigma_yy strain_yy'
  []
  [avg_disp_y]
    type = SideAverageValue
    boundary = top
    variable = disp_y
    execute_on = 'initial timestep_end'
  []
  [eval_strain_y]
    type = ParsedPostprocessor
    expression = 'avg_disp_y / ${tube_length}'
    pp_names = 'avg_disp_y'
  []
  [evaluated_modulus_dispBased]
    type = ParsedPostprocessor
    expression = 'sigma_yy / eval_strain_y'
    pp_names = 'sigma_yy eval_strain_y'
  []
[]

[Outputs]
  exodus = true
  csv = true
[]
