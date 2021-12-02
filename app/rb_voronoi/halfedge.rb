class Halfedge
  attr_accessor :site,
                :edge,
                :angle

  def initialize(in_edge, in_left_site, in_right_site = nil)
    puts "HALFEDGE INITIALIZE".green if DEBUGGING
    @site = in_left_site
    @edge = in_edge

    if in_right_site
      @angle = Math.atan2(in_right_site.y - in_left_site.y, in_right_site.x - in_left_site.x)
    else
      @angle = in_edge.left_site == in_left_site ?
        Math.atan2(in_edge.vertex_b.x - in_edge.vertex_a.x, in_edge.vertex_a.y - in_edge.vertex_b.y) :
        Math.atan2(in_edge.vertex_a.x - in_edge.vertex_b.x, in_edge.vertex_b.y - in_edge.vertex_a.y)
    end
  end

  def get_start_point
    puts "CIRCLEEVENT GET_START_POINT".blue if DEBUGGING
    @edge.left_site == @site ? @edge.vertex_a : @edge.vertex_b
  end

  def get_end_point
    puts "CIRCLEEVENT GET_END_POINT".blue if DEBUGGING
    @edge.left_site == @site ? @edge.vertex_b : @edge.vertex_a
  end

  def self.sort_array_of_halfedges(in_array)
    puts "CIRCLEEVENT SORT_ARRAY_OF_HALFEDGES".blue if DEBUGGING
    in_array.sortUsingSelector(:compare)
  end

  def compare(in_halfedge)
    puts "CIRCLEEVENT COMPARE".blue if DEBUGGING
    if @angle < in_halfedge.angle
      return NSOrderedDescending
    elsif @angle > in_halfedge.angle
      return NSOrderedAscending
    else
      return NSOrderedSame
    end
  end
end
