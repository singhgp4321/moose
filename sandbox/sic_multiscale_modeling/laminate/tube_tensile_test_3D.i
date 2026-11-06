# 3D uniaxial tensile test on a tubular specimen (isotropic approximation)
# Tube axis along z; cross-section in x-y plane
#
# Inner radius: 3.94 mm, Outer radius: 4.79 mm (wall = 0.85 mm)
# Tube length: 65 mm
# Applied axial strain: 0.05%

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

r_in = 3.94e-3
r_out = 4.79e-3
tube_length = 65e-3
applied_strain = 0.0005
applied_disp = ${fparse applied_strain * tube_length}

[Mesh]
  [annular]
    type = AnnularMeshGenerator
    rmin = ${r_in}
    rmax = ${r_out}
    nr = 20
    nt = 60
  []
  [extrude]
    type = MeshExtruderGenerator
    input = annular
    extrusion_vector = '0 0 ${tube_length}'
    num_layers = 325
    bottom_sideset = 'bottom'
    top_sideset = 'top'
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = SMALL
        add_variables = true
        use_automatic_differentiation = true
        generate_output = 'stress_zz strain_zz'
      []
    []
  []
[]

[Materials]
  # Isotropic approximation: E = 260 GPa, nu = 0.2
  [elasticity]
    type = ADComputeIsotropicElasticityTensor
    youngs_modulus = 260e9
    poissons_ratio = 0.2
  []
  [stress]
    type = ADComputeLinearElasticStress
  []
[]

[BCs]
  # Constrain in-plane displacements on bottom and top (matches RZ radial constraint)
  [fix_x_bottom]
    type = ADDirichletBC
    variable = disp_x
    boundary = bottom
    value = 0
  []
  [fix_y_bottom]
    type = ADDirichletBC
    variable = disp_y
    boundary = bottom
    value = 0
  []
  [fix_x_top]
    type = ADDirichletBC
    variable = disp_x
    boundary = top
    value = 0
  []
  [fix_y_top]
    type = ADDirichletBC
    variable = disp_y
    boundary = top
    value = 0
  []
  # Fix axial displacement on bottom
  [fix_z_bottom]
    type = ADDirichletBC
    variable = disp_z
    boundary = bottom
    value = 0
  []
  # Apply axial displacement on top (0.05% strain)
  [pull_z_top]
    type = ADDirichletBC
    variable = disp_z
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
  [sigma_zz]
    type = SideAverageValue
    boundary = top
    variable = stress_zz
    execute_on = 'initial timestep_end'
  []
  [strain_zz]
    type = SideAverageValue
    boundary = top
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
    boundary = top
    variable = disp_z
    execute_on = 'initial timestep_end'
  []
  [eval_strain_z]
    type = ParsedPostprocessor
    expression = 'avg_disp_z / ${tube_length}'
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
