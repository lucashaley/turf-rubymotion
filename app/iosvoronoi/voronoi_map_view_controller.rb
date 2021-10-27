class VoronoiMapViewController < UIViewController
  extend IB
  
  attr_accessor :voronoi_map

  outlet :map_view, MKMapView
end
