class Delaunaycore
  def delaunay_edges(super_triangle, triangles)
    edges = []
    triangles.each do |triangle|
      edge1 = Edge.new(triangle.vertex1, trianlge.vertex2)
      edge2 = Edge.new(triangle.vertex2, triangle.vertex3)
      edge3 = Edge.new(triangle.vertex3, triangle.vertex1)
    end
    edges
  end

  def triangulate(super_triangle, points)
    triangles = []

    # better way of doing this… maybe all this stuff in geodata
    Geodata.instance.all_triangles = []

    open = []
    closed = []

    # set up the arrays with super_triangle
    Geodata.instance.all_triangles << super_triangle
    open << 0

    points.each do |point|
      polygon = []

      # can we use open.reverse_each.with_index do |o, i|
      open.reverse.each_index do |index|
        tri_o = Geodata.instance.all_triangles[open[index]]
        dx = point.x - tri_o.center.x

        if dx > 0.0 && dx ** 2 > tri_o.radius ** 2
          closed << tri_o
          open.delete_at(index)
          next # what is this for?
        end

        if tri_o.contains_in_circumcircle(point)
          polygon << Edge.new(tri_o.vertex1, tri_o.vertex2)
          polygon << Edge.new(tri_o.vertex2, tri_o.vertex3)
          polygon << Edge.new(tri_o.vertex3, tri_o.vertex1)

          points[tri_o.vertex1].adjoin_triangles.remove(tri_o)
          points[tri_o.vertex2].adjoin_triangles.remove(tri_o)
          points[tri_o.vertex3].adjoin_triangles.remove(tri_o)

          open.delete_at(index)
        end

        # This is really messy
        for j in polygon.count-2..0 do
          for k in polygon.count-1..0 do
            polygon.remove(k)
            polygon.remove(j)

            # what is this doing
            # k--
            next
          end
        end

        polygon.each do |p|
          # tri = Triangle.new
        end
      end
    end
  end

  def super_triangle(points)
    puts "super_triangle start"
    m = points[0].x

    points.each do |point|
      absx = Math.abs(point.x)
      absy = Math.abs(point.y)

      m = absx if absx > m
      m = absy if absy > m
    end

    sp1= Point.new(100 * m, 0)
    points << sp1
    sp2= Point.new(0, 100 * m)
    points << sp2
    sp3 = Point.new(-100 * m, -100 * m)
    points << sp3

    puts "super_triangle end"

    c = points.count
    return Triangle.new(c-3, c-2, c-1)
  end
end
