class Geodata
  attr_accessor :all_points, :all_triangles
  
  #####################
  # SINGLETON
  def self.instance
    @instance ||= self.new
  end
end
