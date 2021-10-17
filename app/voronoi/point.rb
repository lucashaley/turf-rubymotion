class Point
  attr_accessor :x, :y, :adjoin_triangles

  def initialize (x, y)
    @x = x
    @y = y
    adjoin_triangles = []
  end

  def to_s
    return "Point: x=#{@x}; y=#{@y}"
  end

  def +(other)
    return Point.new(x + other.x, y + other.y)
  end

  def -(other)
    return Point.new(x - other.x, y - other.y)
  end

  def *(other)
    return Point.new(x * other, y * other)
  end

  def dot(other)
    return x * other.x + y * other.y
  end
end
