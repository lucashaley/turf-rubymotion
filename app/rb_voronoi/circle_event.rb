class CircleEvent
  attr_accessor :next,
                :previous,
                :parent,
                :right,
                :left,
                :red,
                :coord,
                :arc,
                :site,
                :y_center

  DEBUGGING= true

  def set_coord_as_value(in_value)
    puts "CIRCLEEVENT SET_COORD_AS_VALUE".blue if DEBUGGING
    @coord = in_value.CGPointValue
  end

  def coord_as_value
    puts "CIRCLEEVENT COORD_AS_VALUE".blue if DEBUGGING
    NSValue.valueWithCGPoint(@coord)
  end

  def set_x(in_x)
    puts "CIRCLEEVENT SET_X".blue if DEBUGGING
    @coord = CGPointMake(in_x, @coord.y)
  end
  def x
    puts "CIRCLEEVENT X".blue if DEBUGGING
    @coord.x
  end

  def set_y(in_y)
    puts "CIRCLEEVENT SET_Y".blue if DEBUGGING
    @coord = CGPointMake(@coord.x, in_y)
  end
  def y
    puts "CIRCLEEVENT Y".blue if DEBUGGING
    @coord.y
  end
end
