class Edge
  attr_reader :start, :end

  def initialize(s, e)
    @start = s
    @end = e
  end

  def contains_vertex(point)
    return true if @start == point || @end == point

    return false
  end

  def ==(other)
    return true if self == other
    return false if other == nil

    return ((@start == other.start && @end == other.end) || (@start == other.end && @end == other.start))
  end
end
