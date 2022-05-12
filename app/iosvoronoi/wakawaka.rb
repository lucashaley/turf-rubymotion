# Wakawaka
#
# This is the cell created by the Voronoi process.

class Wakawaka # < Cell
  include VoronoiUtilities

  attr_accessor :cell,
                :pylon,
                :site

  DEBUGGING = false

  def initialize(in_cell, in_pylon)
    puts "WAKAWAKA: INITIALIZE".green if DEBUGGING
    @cell = in_cell
    @pylon = in_pylon
  end

  def color
    puts "WAKAWAKA: COLOR: #{@cell.site.color.stringRepresentation}".blue if DEBUGGING
    @cell.site.color
  end

  def edges
    @cell.halfedges
  end

  def vertices
    puts 'WAKAWAKA: VERTICES'.blue if DEBUGGING
    vertices_from_cell(@cell)
  end

  def overlay
    puts "WAKAWAKA: OVERLAY".blue if DEBUGGING
    # THIS IS OTHER PLACES TOO?
    overlay = overlay_from_vertices(vertices)
    # puts "Wakawaka overlay before setting color: #{overlay}".focus
    overlay.overlayColor = self.color
    # puts "Wakawaka overlay after setting color: #{overlay}".focus
    overlay
  end

  def to_s
    puts "Wakawaka! cell: #{@cell}; cell site: #{@cell.site}; vertices: #{vertices}; edges: #{edges}; pylon: #{@pylon}"
  end
end
