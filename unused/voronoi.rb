class Voronoi
  attr_accessor :firstCircleEvent,
                :boundingBox,
                :edges,
                :cells,
                :beachsectionJunkyard,
                :circleEventJunkyard,
                :beachLine,
                :circleEvents,
                :firstCircleEvent,
                :boundingBox

  def initialize
    @edges = []
    @cells = []
    @beachsectionJunkyard = []
    @circleEventJunkyard = []
  end

  def computeWithSites(siteList, bbox)
    reset
    @boundingBox = bbox
  end

  def reset
    if @beachLine.nil?
      @beachline = RBTree.new
    end
  end
end