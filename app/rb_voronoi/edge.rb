class Edge
  attr_accessor :left_site,
                :right_site,
                :vertex_a,
                :vertex_b

  DEBUGGING = true
  
  def initialize(in_left_site, in_right_site)
    puts "EDGE INITIALIZE".green if DEBUGGING
    @left_site = in_left_site
    @right_site = in_right_site
  end
end
