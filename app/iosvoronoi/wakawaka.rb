class Wakawaka # < Cell
  include VoronoiUtilities

  attr_accessor :cell, :pylon, :site

  def initialize(in_cell, in_pylon)
    # puts "Wakawaka::initialize: pylon: #{in_pylon} cell:#{in_cell}"
    @cell = in_cell
    @pylon = in_pylon
  end

  def color
    @pylon.color
  end

  def edges
    # puts "\n\nWakawaka::edges"
    @cell.halfedges
  end

  def vertices
    # puts "\n\nWakawaka::vertices"
    verts = vertices_from_cell(@cell)
    # puts "Verts: #{verts}"
    verts
  end

  def overlay
    # puts "\n\nWakawaka::overlay"
    overlay = overlay_from_vertices(vertices)
    overlay.overlayColor = color
    overlay
  end

  def to_s
    puts "Wakawaka! cell: #{@cell}; cell site: #{@cell.site}; vertices: #{vertices}; edges: #{edges}; pylon: #{@pylon}"
  end
end
