[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

z_length = 0.5e-2
y_length = 0.5e-3
x_length = ${z_length}

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 40
    ny = 4
    nz = 40
    xmax = ${x_length}
    ymax = ${y_length}
    zmax = ${z_length}
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
  [elasticity]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 70e9
    poissons_ratio = 0.3
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
