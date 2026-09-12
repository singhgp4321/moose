[Mesh]
  [circle_in_square]
    type = ConcentricCircleMeshGenerator
    num_sectors = 8
    radii = '1.0'
    rings = '3 2'
    has_outer_square = true
    pitch = 6.0
    preserve_volumes = true
  []
  [extrude]
    type = AdvancedExtruderGenerator
    input = circle_in_square
    heights = '10.0'
    num_layers = '10'
    direction = '0 0 1'
  []
[]

[Outputs]
  exodus = true
[]
