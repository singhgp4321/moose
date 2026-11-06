length = 1.0

[GlobalParams]
  absolute_value_vector_tags = 'ref'
  displacements = 'disp_x disp_y disp_z'
[]

[Problem]
  type = ReferenceResidualProblem
  extra_tag_vectors = 'ref'
  reference_vector = 'ref'
  group_variables = 'disp_x disp_y disp_z'
[]

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 10
    xmax = ${length}
    ymax = ${length}
    zmax = ${length}
  []
[]

[AuxVariables]
  [cracking_strength_x]
    order = CONSTANT
    family = MONOMIAL
    initial_condition = 220e6
  []
  [cracking_strength_y]
    order = CONSTANT
    family = MONOMIAL
  []
  [cracking_strength_z]
    order = CONSTANT
    family = MONOMIAL
  []
  [crack_damage_1]
    order = CONSTANT
    family = MONOMIAL
  []
  [crack_damage_2]
    order = CONSTANT
    family = MONOMIAL
  []
  [crack_damage_3]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[ICs]
  [random_strength_y]
    type = VolumeWeightedWeibull
    variable = cracking_strength_y
    reference_volume = 1e-3
    weibull_modulus = 10.0
    median = 75e6
  []
  [random_strength_z]
    type = VolumeWeightedWeibull
    variable = cracking_strength_z
    reference_volume = 1e-3
    weibull_modulus = 10.0
    median = 600e6
  []
[]

[AuxKernels]
  [crack_damage_1]
    type = ADMaterialRealVectorValueAux
    property = crack_damage
    variable = crack_damage_1
    component = 0
    execute_on = 'initial timestep_end'
  []
  [crack_damage_2]
    type = ADMaterialRealVectorValueAux
    property = crack_damage
    variable = crack_damage_2
    component = 1
    execute_on = 'initial timestep_end'
  []
  [crack_damage_3]
    type = ADMaterialRealVectorValueAux
    property = crack_damage
    variable = crack_damage_3
    component = 2
    execute_on = 'initial timestep_end'
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = FINITE
        add_variables = true
        use_automatic_differentiation = true
        generate_output = 'stress_xx stress_yy stress_zz strain_xx strain_yy strain_zz'
        volumetric_locking_correction = true
        incremental = true
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
    cracking_stress = 'cracking_strength_x cracking_strength_y cracking_strength_z'
    prescribed_crack_directions = 'x y z'
    cracked_elasticity_type = FULL
    softening_models = exp_softening
    inelastic_models = 'pseudo_plasticity'
    shear_retention_factor = 0.01
    max_stress_correction = 0.0
    max_iterations = 50
    absolute_tolerance = 1e-16
    outputs = all
  []
  [exp_softening]
    type = ADExponentialSoftening
    residual_stress = 0.0001
    beta = 0.2
  []
  [hill_tensor]
    type = ADHillConstants
    hill_constants = "0.5 0.5 0.5 1.5 1.5 1.5"
  []
  [pseudo_plasticity]
    type = ADHillElastoPlasticityStressUpdate
    hardening_constant = 1.5e10
    hardening_exponent = 1.0
    yield_stress = 85e6
    absolute_tolerance = 1e-15
    relative_tolerance = 1e-13
    internal_solve_full_iteration_history = true
    max_inelastic_increment = 2e-5
    internal_solve_output_on = on_error
  []
[]

[BCs]
  # Loading direction: x
  [fix_x]
    type = ADDirichletBC
    variable = disp_x
    boundary = left
    value = 0
    extra_vector_tags = 'ref'
  []
  [pull_x]
    type = ADFunctionDirichletBC
    variable = disp_x
    boundary = right
    function = '0.01*t'
    extra_vector_tags = 'ref'
  []
  # Prevent rigid body motion in lateral directions
  [fix_y]
    type = ADDirichletBC
    variable = disp_y
    boundary = bottom
    value = 0
    extra_vector_tags = 'ref'
  []
  [fix_z]
    type = ADDirichletBC
    variable = disp_z
    boundary = back
    value = 0
    extra_vector_tags = 'ref'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  end_time = 1.0
  dtmin = 1e-6
  dtmax = 0.01
  [TimeSteppers]
    [adaptive]
      type = IterationAdaptiveDT
      dt = 0.01
      optimal_iterations = 8
      growth_factor = 2.0
      cutback_factor = 0.5
      timestep_limiting_postprocessor = material_timestep_min
    []
  []
  petsc_options_iname = '-ksp_gmres_restart -pc_type'
  petsc_options_value = '101                lu'
  line_search = 'none'
  l_max_its = 100
  l_tol = 1e-6
  nl_max_its = 10
  nl_rel_tol = 1e-10
  nl_abs_tol = 1e-6
[]

[Postprocessors]
  [material_timestep_min]
    type = MaterialTimeStepPostprocessor
  []
  [stress_xx]
    type = SideAverageValue
    boundary = right
    variable = stress_xx
    execute_on = 'initial timestep_end'
  []
  [stress_yy]
    type = SideAverageValue
    boundary = right
    variable = stress_yy
    execute_on = 'initial timestep_end'
  []
  [stress_zz]
    type = SideAverageValue
    boundary = right
    variable = stress_zz
    execute_on = 'initial timestep_end'
  []
  [avg_disp_x]
    type = SideAverageValue
    boundary = right
    variable = disp_x
    execute_on = 'initial timestep_end'
  []
  [strain_xx]
    type = ParsedPostprocessor
    expression = 'avg_disp_x / ${length}'
    pp_names = 'avg_disp_x'
  []
  [max_crack_damage_1]
    type = ElementExtremeValue
    variable = crack_damage_1
    execute_on = 'initial timestep_end'
  []
  [max_crack_damage_2]
    type = ElementExtremeValue
    variable = crack_damage_2
    execute_on = 'initial timestep_end'
  []
  [max_crack_damage_3]
    type = ElementExtremeValue
    variable = crack_damage_3
    execute_on = 'initial timestep_end'
  []
[]

[Outputs]
  exodus = true
  csv = true
[]
