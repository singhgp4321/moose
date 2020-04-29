[Mesh]
  type = GeneratedMesh
  dim = 1
[]

[Problem]
  solve = false
  kernel_coverage_check = false
[]

[Executioner]
  type = Steady
[]

[Samplers]
  [line]
    type = CartesianProduct
    linear_space_items = "1.5 5 35"
  []
[]

[Surrogates]
  [linear]
    type = LinearRegressionModel
    filename = train_out_linear.rd
  []
[]

[VectorPostprocessors]
  [out]
    type = SurrogateTester
    model = linear
    sampler = line
    execute_on = INITIAL
  []
[]

[Outputs]
  csv = true
[]
