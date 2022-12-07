class VoronoiSite < Site
  attr_accessor :color,
                :pouwhenua_key

  # rubocop:disable Lint/MissingSuper
  def initialize(coordinate, color, in_key)
    mp __method__
    initWithCoord(coordinate).tap do |ps|
      ps.color = color
      ps.pouwhenua_key = in_key
    end
  end
  # rubocop:enable Lint/MissingSuper
end
