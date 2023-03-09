class PlayerAnnotation < MKPointAnnotation
  attr_accessor :color

  def description
    return "PlayerAnnotation: #{@color.to_s}"
  end
end
