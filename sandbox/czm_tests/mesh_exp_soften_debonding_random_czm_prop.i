pitch = 6.0
radius = 2.0

z_length = 10

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
  [bl]
    type = ConcentricCircleMeshGenerator
    num_sectors = 8
    radii = ${radius}
    rings = '3 2'
    has_outer_square = true
    pitch = ${pitch}
    preserve_volumes = true
    # portion = top_right
  []
  [br]
    type = ConcentricCircleMeshGenerator
    num_sectors = 8
    radii = ${radius}
    rings = '3 2'
    has_outer_square = true
    pitch = ${pitch}
    preserve_volumes = true
    # portion = top_left
  []
  [tl]
    type = ConcentricCircleMeshGenerator
    num_sectors = 8
    radii = ${radius}
    rings = '3 2'
    has_outer_square = true
    pitch = ${pitch}
    preserve_volumes = true
    # portion = bottom_right
  []
  [tr]
    type = ConcentricCircleMeshGenerator
    num_sectors = 8
    radii = ${radius}
    rings = '3 2'
    has_outer_square = true
    pitch = ${pitch}
    preserve_volumes = true
    # portion = bottom_left
  []
  [combine]
    type = PatternedMeshGenerator
    inputs = 'bl br tl tr'
    pattern = '2 3 ;
               0 1'
  []
  [extrude]
    type = AdvancedExtruderGenerator
    input = combine
    heights = ${z_length}
    num_layers = '10'
    direction = '0 0 1'
  []
  [rename]
    type = RenameBoundaryGenerator
    input = extrude
    old_boundary = '5 6'
    new_boundary = 'back front'
  []
  [interface_sideset]
    type = SideSetsBetweenSubdomainsGenerator
    input = rename
    primary_block = 1
    paired_block = 2
    new_boundary = 'fiber_matrix_interface'
  []
  [fiber_front]
    type = SideSetsAroundSubdomainGenerator
    input = interface_sideset
    block = 1
    new_boundary = 'fiber_front'
    normal = '0 0 1'
  []
  [break]
    type = BreakMeshByBlockGenerator
    input = fiber_front
  []
[]

[AuxVariables]
  [crack_damage_1]
    order = CONSTANT
    family = MONOMIAL
    block = 2
  []
  [crack_damage_2]
    order = CONSTANT
    family = MONOMIAL
    block = 2
  []
  [crack_damage_3]
    order = CONSTANT
    family = MONOMIAL
    block = 2
  []
  [cracking_strength]
    order = CONSTANT
    family = MONOMIAL
    block = 2
  []
  [czm_damage]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[ICs]
  [random1]
    type = VolumeWeightedWeibull
    variable = cracking_strength
    reference_volume = 2.5e-8 # Nominal element size to avoid scaling
    weibull_modulus = 12.0
    median = 200e6
    block = 2
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
        automatic_eigenstrain_names = true
        volumetric_locking_correction = true
        incremental = true
      []
    []
    [CohesiveZone]
      [czm_ik]
        boundary = 'Block1_Block2'
        strain = FINITE
      []
    []
  []
[]

[AuxKernels]
  [crack_damage_1]
    type = ADMaterialRealVectorValueAux
    property = crack_damage
    variable = crack_damage_1
    component = 0
    execute_on = 'initial timestep_end'
    block = 2
  []
  [crack_damage_2]
    type = ADMaterialRealVectorValueAux
    property = crack_damage
    variable = crack_damage_2
    component = 1
    execute_on = 'initial timestep_end'
    block = 2
  []
  [crack_damage_3]
    type = ADMaterialRealVectorValueAux
    property = crack_damage
    variable = crack_damage_3
    component = 2
    execute_on = 'initial timestep_end'
    block = 2
  []
  [czm_damage]
    type = MaterialRealAux
    property = damage
    variable = czm_damage
    boundary = 'Block1_Block2'
    execute_on = 'initial timestep_end'
  []
[]

[Materials]
  [elasticity_fiber]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 300e9
    poissons_ratio = 0.17
    block = 1
  []
  [elasticity_matrix]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 400e9
    poissons_ratio = 0.3
    block = 2
  []
  [stress_fiber]
    type = ADComputeLinearElasticStress
    block = 1
    outputs = all
  []
  [stress_matrix]
    type = ADComputeSmearedCrackingStress
    cracking_stress = cracking_strength
    cracked_elasticity_type = FULL
    softening_models = exp_softening
    shear_retention_factor = 0.01
    max_stress_correction = 0.0
    block = 2
    outputs = all
  []
  [exp_softening]
    type = ADExponentialSoftening
    outputs = all
    residual_stress = 0.2
    beta = 0.2
  []
  [czm_strengths]
    type = WeibullInterfaceMaterial
    boundary = 'Block1_Block2'
    prop_names = 'random_normal_strength random_shear_strength'
    medians = '100e6 50e6'
    weibull_moduli = '12.0 12.0'
  []
  [czm_mat]
    type = BiLinearMixedModeTraction
    boundary = 'Block1_Block2'
    penalty_stiffness = 1e12
    GI_c = 10.0
    GII_c = 10.0
    normal_strength = random_normal_strength
    shear_strength = random_shear_strength
    eta = 1.45
    viscosity = 1e-3
    displacements = 'disp_x disp_y disp_z'
  []
[]

[BCs]
  [fix_x]
    type = ADDirichletBC
    variable = disp_x
    boundary = left
    value = 0
    extra_vector_tags = 'ref'
  []
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
  [pull_z]
    type = ADFunctionDirichletBC
    variable = disp_z
    boundary = fiber_front
    function = '0.01*t'
    extra_vector_tags = 'ref'
  []
[]

[Preconditioning]
  [smp]
    type = SMP
    full = true
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
  nl_max_its = 10
  nl_rel_tol = 1e-10
  nl_abs_tol = 1e-6
[]

[Postprocessors]
  [stress_zz]
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
  [avg_disp_z]
    type = SideAverageValue
    boundary = front
    variable = disp_z
    execute_on = 'initial timestep_end'
  []
  [strain_zz_dispBased]
    type = ParsedPostprocessor
    expression = 'avg_disp_z / ${z_length}'
    pp_names = 'avg_disp_z'
  []
  [evaluated_modulus_dispBased]
    type = ParsedPostprocessor
    expression = 'stress_zz / strain_zz_dispBased'
    pp_names = 'stress_zz strain_zz_dispBased'
  []
[]

[Outputs]
  exodus = true
  csv = true
[]
