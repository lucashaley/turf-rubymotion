# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiCell.h
class PylonCell # < NSObject
  include VoronoiUtilities

  attr_accessor :cell, :pylon

  DEBUGGING = true

  def initialize(cell, pylon)
    puts "PYLONCELL INITIALIZE".green if DEBUGGING
    # this wraps around cell, because we need to add a color?
    # but why can't we subclass?
    # puts "PylonCell::initialize: cell: #{cell}; pylon: #{pylon}"
    @cell = cell
    @pylon = pylon
    # @color = pylon.color

    # puts "\n\nPylonCell::initialize cell:#{@cell.description} site:#{@cell.site.description}"
  end

  def edges
    cell.halfedges
  end

  def vertices
    vertices_from_cell(@cell)
  end

  def overlay
    puts "PYLONCELL OVVERLAY".blue if DEBUGGING
    overlay = overlay_from_vertices(vertices)
    overlay.overlayColor = pylon.get_uicolor
    overlay
  end
end
