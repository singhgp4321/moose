[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

z_length = 0.5e-2
layer_thickness = ${fparse z_length / 20}
y_length = ${fparse 2 * layer_thickness}
x_length = ${z_length}
y_mid = ${layer_thickness}

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 40
    ny = 20
    nz = 40
    xmax = ${x_length}
    ymax = ${y_length}
    zmax = ${z_length}
  []
  [bottom_layer]
    type = SubdomainBoundingBoxGenerator
    input = gen
    bottom_left = '0 0 0'
    top_right = '${x_length} ${y_mid} ${z_length}'
    block_id = 1
  []
  [top_layer]
    type = SubdomainBoundingBoxGenerator
    input = bottom_layer
    bottom_left = '0 ${y_mid} 0'
    top_right = '${x_length} ${y_length} ${z_length}'
    block_id = 2
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = FINITE
        add_variables = true
        use_automatic_differentiation = true
        generate_output = 'stress_zz strain_zz'
      []
    []
  []
[]

[Materials]
  # Coordinate mapping: x=t(in-plane), y=r(through-thickness), z=y(in-plane)
  # Voigt stiffness (symmetric9): C11 C12 C13 C22 C23 C33 C44 C55 C66
  #
  # Layer 1: 0/90 plain weave (E_r=80, E_t=E_y=260, G_ty=60, G_rt=G_ry=80)
  [elasticity_bottom]
    type = ADComputeElasticityTensor
    fill_method = symmetric9
    C_ijkl = '288.6836e9 45.6664e9 62.5966e9 91.8733e9 45.6664e9 288.6836e9 80e9 60e9 80e9'
    block = 1
  []
  # Layer 2: same weave rotated 45 deg about r(=y), from rotate_elasticity.py
  [elasticity_top]
    type = ADComputeElasticityTensor
    fill_method = symmetric9
    C_ijkl = '235.6401e9 45.6664e9 115.6401e9 91.8733e9 45.6664e9 235.6401e9 80e9 113.0435e9 80e9'
    block = 2
  []
  [stress]
    type = ADComputeFiniteStrainElasticStress
  []
[]

[BCs]
  [fix_x]
    type = ADDirichletBC
    variable = disp_x
    boundary = left
    value = 0
  []
  [fix_y]
    type = ADDirichletBC
    variable = disp_y
    boundary = bottom
    value = 0
  []
  [fix_z]
    type = ADDirichletBC
    variable = disp_z
    boundary = back
    value = 0
  []
  [Pressure]
    [pull]
      boundary = front
      factor = -1e6
    []
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
  [sigma_zz]
    type = SideAverageValue
    boundary = front
    variable = stress_zz
    execute_on = 'initial timestep_end'
  []
  [strain_zz]
    type = SideAverageValue
    boundary = front
    variable = strain_zz
    execute_on = 'initial timestep_end'
  []
  [evaluated_modulus]
    type = ParsedPostprocessor
    expression = 'sigma_zz / strain_zz'
    pp_names = 'sigma_zz strain_zz'
  []
  [avg_disp_z]
    type = SideAverageValue
    boundary = front
    variable = disp_z
    execute_on = 'initial timestep_end'
  []
  [eval_strain_z]
    type = ParsedPostprocessor
    expression = 'avg_disp_z / ${z_length}'
    pp_names = 'avg_disp_z'
  []
  [evaluated_modulus_dispBased]
    type = ParsedPostprocessor
    expression = 'sigma_zz / eval_strain_z'
    pp_names = 'sigma_zz eval_strain_z'
  []
[]

[Outputs]
  exodus = true
  csv = true
[]
