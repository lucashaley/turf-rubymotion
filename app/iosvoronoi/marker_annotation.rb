class MarkerAnnotation < MKPointAnnotation
  attr_accessor :color

  def description
    return "MarkerAnnotation: #{@color.to_s}"
  end
end
