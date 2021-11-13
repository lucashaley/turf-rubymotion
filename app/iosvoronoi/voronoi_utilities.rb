# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEUtilities.m
module VoronoiUtilities

  DEBUGGING = true

  def vertices_from_cell(cell)
    puts "VORONOI_UTILITIES: VERTICES_FROM_CELL".blue if DEBUGGING
    vertices = []

    cell.halfedges.each do |halfedge|
      start_point = halfedge.getStartpoint
      end_point = halfedge.getEndpoint
      # puts "Points: #{start_point}, #{end_point}"

      # not sure if this is correct
      # add to array if not already there
      # https://stackoverflow.com/questions/14004325/add-element-to-an-array-if-its-not-there-already
      # vertices | [start_point]
      # vertices | [end_point]

      unless vertices.containsObject(start_point)
        vertices.addObject(start_point)
      end
      unless vertices.containsObject(end_point)
        vertices.addObject(end_point)
      end
    end
    puts "vertices:".red
    vertices.each do |v|
      puts v
    end
    vertices
  end
  alias :verticesFromCell :vertices_from_cell

  def overlay_from_vertices(vertices)
    puts "VORONOI_UTILITIES: OVERLAY_FROM_VERTICES".blue if DEBUGGING
    # puts "vertices: #{vertices.length}"
    points = []

    # can we use map here?
    # do we have to do the whole pointer array thing here?
    vertices.each do |vertex|
      mp = MKMapPointMake(vertex.x, vertex.y)
      # puts "mp: #{mp.x}, #{mp.y}".red
      # points << MKMapPointMake(vertex.x, vertex.y)
      points << mp
    end

    points_ptr = Pointer.new(MKMapPoint.type, points.length)
    points.each_with_index do |p, i|
      points_ptr[i] = p
    end

    # return MKPolygon.polygonWithPoints(points, count: vertices.length)
    return MKPolygon.polygonWithPoints(points_ptr, count: points.length)
  end
  alias :overlayFromVertices :overlay_from_vertices

  def site_from_pylon
    # puts "\n\nVoronoiUtilities::site_from_pylon"
  end

  def mkmaprect_for_coord_region(region)
    # puts "\nmkmaprect_for_coord_region region:#{region.center.latitude}, delta: #{region.span.latitudeDelta}"

    # this seems to work
    # ac = CLLocationCoordinate2DMake( \
    #       region.center.latitude + region.span.latitudeDelta / 2, \
    #       region.center.longitude - region.span.longitudeDelta / 2 )
    # puts "ac: #{ac.latitude}, #{ac.longitude}"
    # bc = CLLocationCoordinate2DMake( \
    #       region.center.latitude - region.span.latitudeDelta / 2, \
    #       region.center.longitude + region.span.longitudeDelta / 2 )
    # puts "bc: #{bc.latitude}, #{bc.longitude}"

    a = MKMapPointForCoordinate(CLLocationCoordinate2DMake( \
          region.center.latitude + region.span.latitudeDelta / 2, \
          region.center.longitude - region.span.longitudeDelta / 2 ))
    # puts "a: #{a.x}, #{a.y}"
    b = MKMapPointForCoordinate(CLLocationCoordinate2DMake( \
          region.center.latitude - region.span.latitudeDelta / 2, \
          region.center.longitude + region.span.longitudeDelta / 2 ))
    # puts "b: #{b.x}, #{b.y}"
    rect = MKMapRectMake([a.x, b.x].min, [a.y, b.y].min, (a.x - b.x).abs, (a.y - b.y).abs)
    # puts "rect: #{rect.origin.x}"

    # double_check = MKCoordinateRegionForMapRect(rect)
    # puts "coord check: #{double_check.center.latitude}, #{double_check.center.longitude}"
    return rect
  end
end
