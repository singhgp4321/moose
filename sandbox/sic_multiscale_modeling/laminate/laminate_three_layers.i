[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

z_length = 0.5e-2
y_length = 0.5e-2
x_length = ${z_length}

y1 = 0.22e-2
y2 = 0.28e-2

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 40
    ny = 25
    nz = 40
    xmax = ${x_length}
    ymax = ${y_length}
    zmax = ${z_length}
  []
  [bottom_layer]
    type = SubdomainBoundingBoxGenerator
    input = gen
    bottom_left = '0 0 0'
    top_right = '${x_length} ${y1} ${z_length}'
    block_id = 1
  []
  [middle_layer]
    type = SubdomainBoundingBoxGenerator
    input = bottom_layer
    bottom_left = '0 ${y1} 0'
    top_right = '${x_length} ${y2} ${z_length}'
    block_id = 2
  []
  [top_layer]
    type = SubdomainBoundingBoxGenerator
    input = middle_layer
    bottom_left = '0 ${y2} 0'
    top_right = '${x_length} ${y_length} ${z_length}'
    block_id = 3
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
  [elasticity_outer]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 70e9
    poissons_ratio = 0.3
    block = '1 3'
  []
  [elasticity_middle]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 10e9
    poissons_ratio = 0.3
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
