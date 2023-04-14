# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEUtilities.m
module VoronoiUtilities
  DEBUGGING = false

  def vertices_from_cell(cell)
    mp __method__

    vertices = []

    # puts 'Cell: '.red
    mp cell

    cell.halfedges.each do |halfedge|
      start_point = halfedge.getStartpoint
      end_point = halfedge.getEndpoint

      unless vertices.containsObject(start_point)
        vertices.addObject(start_point)
      end
      unless vertices.containsObject(end_point)
        vertices.addObject(end_point)
      end
    end

    mp vertices

    vertices
  end
  # is it better to use alias_method?
  # alias :verticesFromCell :vertices_from_cell
  alias_method :verticesFromCell, :vertices_from_cell

  def overlay_from_vertices(vertices)
    mp __method__

    if vertices.count <= 0
      mp 'there are no vertices'
      return
    end

    points = []
    coords = []

    # can we use map here?
    # do we have to do the whole pointer array thing here?
    vertices.each do |vertex|
      map_point = MKMapPointMake(vertex.x, vertex.y)
      # puts "mp: #{mp.x}, #{mp.y}".red
      # points << MKMapPointMake(vertex.x, vertex.y)
      coord = MKCoordinateForMapPoint(map_point)
      points << map_point
      coords << coord
    end
    # mp "#{__method__}: There are no points" if points.nil?
    # mp points
    # mp coords

    new_points = NSArray.arrayWithArray(points)
    # mp new_points
    new_coords = NSArray.arrayWithArray(coords)

    points_ptr = Pointer.new(MKMapPoint.type, new_points.length)
    new_points.each_with_index do |p, i|
      points_ptr[i] = p
    end

    coords_ptr = Pointer.new(CLLocationCoordinate2D.type, new_coords.length)
    new_coords.each_with_index do |c, i|
      coords_ptr[i] = c
    end

    # mp "#{__method__}: #{points_ptr}"
    # mp coords_ptr

    # New, more efficient way
    # new_ptr = Pointer.new(MKMapPoint.type, vertices.length)
    # vertices.reverse.each_with_index do |vertex, index|
    #   # vertices.each_with_index do |vertex, index|
    #   new_ptr[index] = MKMapPointMake(vertex.x, vertex.y)
    # end

    # return MKPolygon.polygonWithPoints(points, count: vertices.length)
    MKPolygon.polygonWithPoints(points_ptr, count: points.length)
    # MKPolygon.polygonWithPoints(new_ptr, count: vertices.length)

    MKPolygon.polygonWithCoordinates(coords_ptr, count: coords.length)
  end
  alias :overlayFromVertices :overlay_from_vertices

  def mkmaprect_for_coord_region(region)
    mp __method__
    mp region

    # a = MKMapPointForCoordinate(
    #   CLLocationCoordinate2DMake( \
    #     region.center.latitude + region.span.latitudeDelta / 2, \
    #     region.center.longitude - region.span.longitudeDelta / 2
    #   )
    # )
    a = MKMapPointForCoordinate(
      CLLocationCoordinate2DMake( \
        region.center.latitude + region.span.latitudeDelta, \
        region.center.longitude - region.span.longitudeDelta
      )
    )

    # b = MKMapPointForCoordinate(
    #   CLLocationCoordinate2DMake( \
    #     region.center.latitude - region.span.latitudeDelta / 2, \
    #     region.center.longitude + region.span.longitudeDelta / 2
    #   )
    # )
    b = MKMapPointForCoordinate(
      CLLocationCoordinate2DMake( \
        region.center.latitude - region.span.latitudeDelta, \
        region.center.longitude + region.span.longitudeDelta
      )
    )

    MKMapRectMake([a.x, b.x].min, [a.y, b.y].min, (a.x - b.x).abs, (a.y - b.y).abs)
  end
end
