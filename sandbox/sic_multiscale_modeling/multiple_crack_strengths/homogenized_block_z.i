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
    initial_condition = 200e6
  []
  [cracking_strength_y]
    order = CONSTANT
    family = MONOMIAL
    initial_condition = 400e6
  []
  [cracking_strength_z]
    order = CONSTANT
    family = MONOMIAL
    initial_condition = 600e6
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
    shear_retention_factor = 0.01
    max_stress_correction = 0.0
    outputs = all
  []
  [exp_softening]
    type = ADExponentialSoftening
    residual_stress = 0.0001
    beta = 0.2
  []
[]

[BCs]
  # Loading direction: z
  [fix_z]
    type = ADDirichletBC
    variable = disp_z
    boundary = back
    value = 0
    extra_vector_tags = 'ref'
  []
  [pull_z]
    type = ADFunctionDirichletBC
    variable = disp_z
    boundary = front
    function = '0.01*t'
    extra_vector_tags = 'ref'
  []
  # Constrained lateral faces
  [fix_x]
    type = ADDirichletBC
    variable = disp_x
    boundary = 'left right'
    value = 0
    extra_vector_tags = 'ref'
  []
  [fix_y]
    type = ADDirichletBC
    variable = disp_y
    boundary = 'bottom top'
    value = 0
    extra_vector_tags = 'ref'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  end_time = 3.0
  dtmin = 1e-6
  dtmax = 0.1
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
  nl_max_its = 10
  nl_rel_tol = 1e-10
  nl_abs_tol = 1e-6
[]

[Postprocessors]
  [stress_xx]
    type = SideAverageValue
    boundary = front
    variable = stress_xx
    execute_on = 'initial timestep_end'
  []
  [stress_yy]
    type = SideAverageValue
    boundary = front
    variable = stress_yy
    execute_on = 'initial timestep_end'
  []
  [stress_zz]
    type = SideAverageValue
    boundary = front
    variable = stress_zz
    execute_on = 'initial timestep_end'
  []
  [avg_disp_z]
    type = SideAverageValue
    boundary = front
    variable = disp_z
    execute_on = 'initial timestep_end'
  []
  [strain_zz]
    type = ParsedPostprocessor
    expression = 'avg_disp_z / ${length}'
    pp_names = 'avg_disp_z'
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
