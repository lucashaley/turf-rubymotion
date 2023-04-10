class VoronoiSite < Site
  attr_accessor :color,
                :pouwhenua_key # TODO: rename this

  # rubocop:disable Lint/MissingSuper
  def initialize(coordinate, color, in_key)
    mp __method__
    mp "New VoronoiSite coordinate: #{coordinate.to_s}"

    return unless coordinate.is_a?(CGPoint) # Site requires a CGPoint

    initWithCoord(coordinate).tap do |ps|
      ps.color = color
      ps.pouwhenua_key = in_key
    end
  end
  # rubocop:enable Lint/MissingSuper

  def to_s
    self.description
    mp @color
    mp @pouwhenua_key
  end
end
