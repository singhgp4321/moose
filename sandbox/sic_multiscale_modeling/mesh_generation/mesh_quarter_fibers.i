pitch = 6.0
radius = 2.5

[Mesh]
  # Bottom-left quadrant: quarter circle at the (-3,-3) corner
  [bl]
    type = ConcentricCircleMeshGenerator
    num_sectors = 8
    radii = ${radius}
    rings = '3 2'
    has_outer_square = true
    pitch = ${pitch}
    preserve_volumes = true
    portion = top_right
  []
  # Bottom-right quadrant: quarter circle at the (3,-3) corner
  # [br_raw]
  #   type = ConcentricCircleMeshGenerator
  #   num_sectors = 8
  #   radii = ${radius}
  #   rings = '3 2'
  #   has_outer_square = true
  #   pitch = ${pitch}
  #   preserve_volumes = true
  #   portion = top_left
  # []
  # # Translate from [-3,0]x[0,3] to [0,3]x[0,3]
  # [br]
  #   type = TransformGenerator
  #   input = br_raw
  #   transform = TRANSLATE
  #   vector_value = '3 0 0'
  # []
  [br]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 0
    xmax = 3
    ymin = 0
    ymax = 3
    nx = ${fparse pitch+1}
    ny = ${fparse pitch+1}
  []
  # Top-left quadrant: quarter circle at the (-3,3) corner
  # [tl_raw]
  #   type = ConcentricCircleMeshGenerator
  #   num_sectors = 8
  #   radii = ${radius}
  #   rings = '3 2'
  #   has_outer_square = true
  #   pitch = ${pitch}
  #   preserve_volumes = true
  #   portion = bottom_right
  # []
  # # Translate from [0,3]x[-3,0] to [0,3]x[0,3]
  # [tl]
  #   type = TransformGenerator
  #   input = tl_raw
  #   transform = TRANSLATE
  #   vector_value = '0 3 0'
  # []
  [tl]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 0
    xmax = 3
    ymin = 0
    ymax = 3
    nx = 7
    ny = 7
  []
  # Top-right quadrant: quarter circle at the (3,3) corner
  [tr_raw]
    type = ConcentricCircleMeshGenerator
    num_sectors = 8
    radii = ${radius}
    rings = '3 2'
    has_outer_square = true
    pitch = ${pitch}
    preserve_volumes = true
    portion = bottom_left
  []
  # Translate from [-3,0]x[-3,0] to [0,3]x[0,3]
  [tr]
    type = TransformGenerator
    input = tr_raw
    transform = TRANSLATE
    vector_value = '3 3 0'
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
[]

[Outputs]
  exodus = true
[]
