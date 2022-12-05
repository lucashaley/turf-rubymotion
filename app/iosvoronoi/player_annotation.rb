class PlayerAnnotation < MKPointAnnotation
  attr_accessor :color

  def description
    retrun "PlayerAnnotation: #{@color.to_s}"
  end
end
