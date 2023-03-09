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
    # mp __method__
    vertices_from_cell(@cell)
  end

  def overlay
    # mp __method__
    # THIS IS OTHER PLACES TOO?
    overlay = overlay_from_vertices(vertices)
    overlay.overlayColor = self.color
    overlay
  end

  def to_s
    puts "VoronoiCell! cell: #{@cell}; cell site: #{@cell.site}; vertices: #{vertices}; edges: #{edges}; pylon: #{@pylon}"
  end
end
