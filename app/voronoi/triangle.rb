class Triangle
  attr_accessor :vertex1, :vertex2, :vertex3
  attr_reader :center, :radius

  # def initialize
  #   @vertex1 = -1
  #   @vertex2 = -1
  #   @vertex3 = -1
  # end

  def initialize(v1, v2, v3)
    @vertex1 = v1
    @vertex2 = v2
    @vertex3 = v3

    x1 = Geodata.instance.all_points[@vertex1].x
    x2 = Geodata.instance.all_points[@vertex2].x
    x3 = Geodata.instance.all_points[@vertex3].x
    y1 = Geodata.instance.all_points[@vertex1].y
    y2 = Geodata.instance.all_points[@vertex2].y
    y3 = Geodata.instance.all_points[@vertex3].y

    x = ((y2 - y1) * (y3 * y3 - y1 * y1 + x3 * x3 - x1 * x1) - (y3 - y1) * (y2 * y2 - y1 * y1 + x2 * x2 - x1 * x1)) / (2 * (x3 - x1) * (y2 - y1) - 2 * ((x2 - x1) * (y3 - y1)));
    y = ((x2 - x1) * (x3 * x3 - x1 * x1 + y3 * y3 - y1 * y1) - (x3 - x1) * (x2 * x2 - x1 * x1 + y2 * y2 - y1 * y1)) / (2 * (y3 - y1) * (x2 - x1) - 2 * ((y2 - y1) * (x3 - x1)));

    @center = Point.new(x, y)
    @radius = Math.sqrt(Math.abs(Geodata.instance.all_points[@vertex1.x - x]) ** 2 + Math.abs(Geodata.instance.all_points[@vertex1.y - y]) ** 2)
  end

  def contains_in_circumcircle(point)
    d_squared = (point.x - @center.x) * (point.x - @center.x) + (point.y - @center.y) * (point.y - @center.y)
    radius_squared = @radius ** 2

    return d_squared < radius_squared
  end

  def shares_vertex_with(triangle)
    return true if (@vertex1 == triangle.vertex1)
    return true if (@vertex1 == triangle.vertex2)
    return true if (@vertex1 == triangle.vertex3)

    return true if (@vertex2 == triangle.vertex1)
    return true if (@vertex2 == triangle.vertex2)
    return true if (@vertex2 == triangle.vertex3)

    return true if (@vertex3 == triangle.vertex1)
    return true if (@vertex3 == triangle.vertex2)
    return true if (@vertex3 == triangle.vertex3)

    return false
  end

  def find_common_edge_with(triangle)
    # common_edge = Edge.new
    common_vertices = []

    common_vertices << @vertex1 if (@vertex1 == triangle.vertex1 || @vertex1 == triangle.vertex2 || @vertex1 == triangle.vertex3)
    common_vertices << @vertex2 if (@vertex2 == triangle.vertex1 || @vertex2 == triangle.vertex2 || @vertex2 == triangle.vertex3)
    common_vertices << @vertex3 if (@vertex3 == triangle.vertex1 || @vertex3 == triangle.vertex2 || @vertex3 == triangle.vertex3)

    if (common_vertices.Count == 2)
      common_edge = Edge.new(common_vertices[0], common_vertices[1])
      return common_edge
    end

    return nil
  end
end
