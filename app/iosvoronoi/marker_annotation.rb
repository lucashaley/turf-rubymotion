class MarkerAnnotation < MKPointAnnotation
  attr_accessor :color

  def description
    retrun "MarkerAnnotation: #{@color.to_s}"
  end
end
