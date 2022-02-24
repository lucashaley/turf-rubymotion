# Wakawaka
#
# This is the cell created by the Voronoi process.

class Wakawaka # < Cell
  include VoronoiUtilities

  attr_accessor :cell,
                :pylon,
                :site

  DEBUGGING = true

  def initialize(in_cell, in_pylon)
    puts "WAKAWAKA: INITIALIZE".green if DEBUGGING
    @cell = in_cell
    @pylon = in_pylon
  end

  # def color
  #   @pylon.color
  # end
  def color
    puts "WAKAWAKA: COLOR".blue if DEBUGGING
    # puts @pylon if DEBUGGING
    # @pylon.lifespan_color
    return CIColor.alloc.initWithColor(UIColor.systemYellowColor.colorWithAlphaComponent(0.2))
  end

  def edges
    # puts "\n\nWakawaka::edges"
    @cell.halfedges
  end

  def vertices
    puts "WAKAWAKA: VERTICES".blue if DEBUGGING
    verts = vertices_from_cell(@cell)
  end

  def overlay
    puts "WAKAWAKA: OVERLAY".blue if DEBUGGING
    # THIS IS OTHER PLACES TOO?
    overlay = overlay_from_vertices(vertices)
    puts "#{overlay}".focus
    overlay.overlayColor = self.color
    puts "#{overlay}".focus
    overlay
  end

  def to_s
    puts "Wakawaka! cell: #{@cell}; cell site: #{@cell.site}; vertices: #{vertices}; edges: #{edges}; pylon: #{@pylon}"
  end
end
