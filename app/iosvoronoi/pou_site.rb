class PouSite < Site
  attr_accessor :color

  def initialize(coordinate, color)
    initWithCoord(coordinate).tap do |ps|
      ps.color = color
    end
  end
end
