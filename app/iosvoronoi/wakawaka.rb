class Wakawaka # < Cell
  include VoronoiUtilities

  attr_accessor :cell, :pylon, :site

  DEBUGGING = true

  def initialize(in_cell, in_pylon)
    puts "WAKAWAKA: INITIALIZE" if DEBUGGING
    @cell = in_cell
    @pylon = in_pylon
  end

  # def color
  #   @pylon.color
  # end
  def color
    puts "WAKAWAKA: COLOR" if DEBUGGING
    puts @pylon if DEBUGGING
    @pylon.lifespan_color
  end

  def edges
    # puts "\n\nWakawaka::edges"
    @cell.halfedges
  end

  def vertices
    puts "WAKAWAKA: VERTICES" if DEBUGGING
    verts = vertices_from_cell(@cell)
  end

  def overlay
    puts "WAKAWAKA: OVERLAY" if DEBUGGING
    # THIS IS OTHER PLACES TOO?
    overlay = overlay_from_vertices(vertices)
    # puts "#{overlay}, #{@pylon.title}"
    overlay.overlayColor = color
    overlay
  end

  def to_s
    puts "Wakawaka! cell: #{@cell}; cell site: #{@cell.site}; vertices: #{vertices}; edges: #{edges}; pylon: #{@pylon}"
  end
end
