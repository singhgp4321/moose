[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 1
    ny = 1
    nz = 1
    xmax = 1.0
    ymax = 1.0
    zmax = 1.0
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
    type = ADComputeSmearedCrackingStress
    cracking_stress = 10e6
    cracked_elasticity_type = FULL
    softening_models = exp_softening
    outputs = all
  []
  [exp_softening]
    type = ADExponentialSoftening
    residual_stress = 0.2
    outputs = all
    beta = 0.2
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
  [pull_z]
    type = ADFunctionDirichletBC
    variable = disp_z
    boundary = front
    function = '0.01*t'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  dt = 0.01
  end_time = 10.0
  dtmin = 1e-6
  [TimeSteppers]
    [adaptive]
      type = IterationAdaptiveDT
      dt = 0.01
      optimal_iterations = 8
      growth_factor = 2.0
      cutback_factor = 0.5
    []
  []
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
  [stress_zz]
    type = ElementAverageValue
    variable = stress_zz
  []
  [strain_zz]
    type = ElementAverageValue
    variable = strain_zz
  []
[]

[Outputs]
  exodus = true
  csv = true
[]
