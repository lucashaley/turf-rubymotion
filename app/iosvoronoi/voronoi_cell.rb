# This is the cell created by the Voronoi process.

class VoronoiCell # < Cell
  include VoronoiUtilities

  attr_accessor :cell,
                :pylon,
                :site

  def initialize(in_cell, in_pylon)
    mp __method__
    @cell = in_cell
    @pylon = in_pylon
  end

  def color
    # mp __method__
    @cell.site.color
  end

  def edges
    @cell.halfedges
  end

  def vertices
    mp __method__
    vertices_from_cell(@cell)
  end

  def overlay
    mp __method__

    # this is actually done in overlay_from_vertices
    # mp 'mapping vertices'
    vertices_coords = vertices.map do |v|
      # mp 'vertex'
      # mp v
      # we might need to construct using MKMapPointMake(x, y)
      map_point = MKMapPointMake(v.x, v.y)
      # mp MKCoordinateForMapPoint(map_point)
      MKCoordinateForMapPoint(map_point)
    end
    # mp vertices_coords

    # THIS IS OTHER PLACES TOO?
    overlay = overlay_from_vertices(vertices)
    overlay.overlayColor = self.color
    overlay
  end

  def to_s
    "VoronoiCell! #{@cell.description}; #{@cell.site.coord}; #{@cell.site.voronoiId}; vertices: #{vertices}; edges: #{edges}; pylon: #{@pylon}"
  end
end
