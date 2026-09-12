pitch = 6.0
radius = 2.0

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
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
    heights = '10.0'
    num_layers = '10'
    direction = '0 0 1'
  []
  [rename]
    type = RenameBoundaryGenerator
    input = extrude
    old_boundary = '5 6'
    new_boundary = 'back front'
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = FINITE
        add_variables = true
        use_automatic_differentiation = true
      []
    []
  []
[]

[Materials]
  [elasticity_fiber]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 60e9
    poissons_ratio = 0.17
    block = 1
  []
  [elasticity_matrix]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 70e9
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
    cracking_stress = 10e6
    cracked_elasticity_type = FULL
    softening_models = energy_softening
    block = 2
    outputs = all
  []
  [energy_softening]
    type = ADExponentialEnergyBasedSoftening
    fracture_toughness = 40 # J/m^2
    outputs = all
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

[Outputs]
  exodus = true
[]
