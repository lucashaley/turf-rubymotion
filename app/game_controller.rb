class GameController < UIViewController
  extend IB
  include VoronoiUtilities

  outlet :map_view, MKMapView
  outlet :button_pylon, UIButton

  attr_accessor :voronoi_map

  def viewWillAppear(animated)
    puts "\n\nGameController::viewWillAppear\n\n"
    @location_manager ||= CLLocationManager.alloc.init.tap do |lm|
      lm.requestWhenInUseAuthorization

      # constant needs to be capitalized because?
      lm.desiredAccuracy = KCLLocationAccuracyBest
      lm.startUpdatingLocation
      lm.delegate = self
    end

    # super

    # ask the map to generate tesselation
    @voronoi_map.voronoi_cells.each do |cell|
      @map_view.addOverlay(cell.overlay)
    end
    puts "Adding annotations"
    puts "annotations: #{@voronoi_map.annotations}"
    map_view.addAnnotations(@voronoi_map.annotations)
  end

  def viewDidLoad
    puts "\n\nGameController::viewDidLoad\n\n"
    # https://stackoverflow.com/questions/6020612/mkmapkit-not-showing-userlocation
    map_view.showsUserLocation = true
    map_view.showsPitchControl = true

    location = CLLocationCoordinate2D.new
    location.latitude = 37.33189332651307
    location.longitude = -122.03128724123847
    puts "Location: #{location}"

    span = MKCoordinateSpan.new
    span.latitudeDelta = 0.01
    span.longitudeDelta = 0.01
    puts "Span: #{span}"

    region = MKCoordinateRegion.new
    region.span = span
    region.center = location

    map_view.setRegion(region, animated:true)
    map_view.regionThatFits(region)

    @button_fsm = StateMachine::Base.new start_state: :up, verbose: true
    @button_fsm.when :up do |state|
      state.on_entry { set_button_color(UIColor.systemBlueColor) }
      state.transition_to :down,
        on: :button_down
    end
    @button_fsm.when :down do |state|
      state.on_entry { set_button_color(UIColor.systemRedColor) }
      state.transition_to :primed,
        after: 5
      state.transition_to :up,
        on: :button_up
    end
    @button_fsm.when :primed do |state|
      state.on_entry { set_button_color(UIColor.systemGreenColor) }
      state.transition_to :up,
        on: :button_up,
        action: proc { create_new_pylon }
    end

    puts "Starting button state machine\n\n"
    @button_fsm.start!

    coordRegion = MKCoordinateRegionForMapRect(mkmaprect_for_coord_region(region))
    puts "\ncorrdRegion: #{coordRegion.center}"
    # Machine.instance.bounding_box = map_view.convertRegion(coordRegion, toRectToView: map_view)
    Machine.instance.bounding_box = mkmaprect_for_coord_region(region)
    @voronoi_map = VoronoiMap.new
    # @voronoi_map

    test_dict = Hash.new
    test_pylon_01 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33374960204376, -122.03019990835675), UIColor.systemBlueColor, "Jenny")
    test_pylon_02 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.333062054067, -122.03113705459889), UIColor.systemBlueColor, "Gilbert")
    test_pylon_03 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33224134831166, -122.03311472880185), UIColor.systemBlueColor, "Jenny")
    test_pylon_04 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33077886077367, -122.03048131661657), UIColor.systemBlueColor, "Gilbert")
    test_pylon_05 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33316896808407, -122.02850863291272))
    test_pylon_06 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33085252713372, -122.02833842959912), UIColor.systemBlueColor, "Gilbert")
    test_pylon_07 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33432727342505, -122.03242334715573))
    test_pylon_08 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.33096123684747, -122.03426217107544))
    test_pylon_09 = Pylon.initWithLocation(CLLocationCoordinate2DMake(37.3357776539391, -122.02908752007481))
    test_dict[test_pylon_01.uuID] = test_pylon_01
    test_dict[test_pylon_02.uuID] = test_pylon_02
    test_dict[test_pylon_03.uuID] = test_pylon_03
    test_dict[test_pylon_04.uuID] = test_pylon_04
    test_dict[test_pylon_05.uuID] = test_pylon_05
    test_dict[test_pylon_06.uuID] = test_pylon_06
    test_dict[test_pylon_07.uuID] = test_pylon_07
    test_dict[test_pylon_08.uuID] = test_pylon_08
    test_dict[test_pylon_09.uuID] = test_pylon_09

    # test_dict.each do |k, v|
    #   puts "\ntest_dict::pylon: #{k.UUIDString}\n#{v}"
    # end
    # @pylon_annotation_view = MKAnnotationView.initWithAnnotation(PylonAnnotation, reuseIdentifier: "PylonAnnotationView")
    map_view.registerClass(PylonAnnotation, forAnnotationViewWithReuseIdentifier: "PylonAnnotation")
    test_dict.each do |k, v|
      @voronoi_map.pylons.setObject(v, forKey:k)
      map_view.addAnnotation(PylonAnnotation.new(v).annotation)
    end

    vcells = @voronoi_map.voronoi_cells_from_pylons(test_dict)

    vcells.each do |vc|
      # "GameController::viewDidLoad adding overlay: #{vc}"
      map_view.addOverlay(vc.overlay)

      # [self.vMap.cellTowers setObject:cellTower forKey:cellTower.uuID];
    end

    puts "Adding annotations"
    puts "annotations: #{@voronoi_map.annotations}"
    # map_view.addAnnotations(@voronoi_map.annotations)

    # map_view.addAnnotation(Pylon.new(-41.30201, 174.77322))
    # puts "Adding pylons"
    # @player_annotation_view = MKAnnotationView.initWithAnnotation(Pylon, reuseIdentifier: "PylonAnnotationView")
    # map_view.registerClass(MKUserLocation, forAnnotationViewWithReuseIdentifier: "PlayerAnnotation")
    # map_view.registerClass(Pylon, forAnnotationViewWithReuseIdentifier: "PylonAnnotation")
    # Pylon::Test_Pylons.each { |pylon| puts pylon.coordinate.longitude }
    # Pylon::Test_Pylons.each { |pylon| map_view.addAnnotation(pylon.annotation) }

    # puts "Adding overlay"
    # pol = MKPolygon.polygonWithPoints()
    # pt01 = MKMapPoint.new
    # pt01.x = 37.33224775088951
    # pt01.y = -122.03043116202183
    # pt02 = MKMapPoint.new
    # pt02.x = 37.33241108181487
    # pt02.y = -122.03069094931799
    # pt03 = MKMapPoint.new
    # pt03.x = 37.3327634456037
    # pt03.y = -122.02935601332467
    # pt04 = MKMapPoint.new
    # pt04.x = 37.3328
    # pt04.y = -122.031
    # pt_arr = [pt01, pt02, pt03, pt04]
    # pt_ptr = Pointer.new(MKMapPoint.type, pt_arr.length)
    # pt_ptr[0] = pt_arr[0]
    # pt_ptr[1] = pt_arr[1]
    # pt_ptr[2] = pt_arr[2]
    # pt_ptr[3] = pt_arr[3]
    # poly = MKPolyline.polylineWithPoints(pt_ptr, count:4)
    # puts poly
    # poly_over = MKOverlayRenderer.alloc.initWithOverlay(poly)
    # puts poly_over
    # map_view.addOverlay(poly)
    # puts "Overlays: #{map_view.overlays}"


    # co01 = CLLocationCoordinate2DMake(37.33510602017382, -122.0303608121068)
    # # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co01))
    # co02 = CLLocationCoordinate2DMake(37.336076101951534, -122.02405461862536)
    # # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co02))
    # co03 = CLLocationCoordinate2DMake(37.3327634456037, -122.02935601332467)
    # # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co03))
    # co04 = CLLocationCoordinate2DMake(37.336076101951534, -122.02405461862536)
    # # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co04))
    # co05 = CLLocationCoordinate2DMake(37.333062054067, -122.03113705459889)
    # # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co05))
    # co06 = CLLocationCoordinate2DMake(37.329422767200626, -122.0290652396243)
    # # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co06))
    # co07 = CLLocationCoordinate2DMake(37.32970834952277, -122.03300306881782)
    # # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co07))
    # co08 = CLLocationCoordinate2DMake(37.33402614123069, -122.03180114380011)
    # # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co08))
    # co09 = CLLocationCoordinate2DMake(37.33262534062823, -122.03418763374351)
    # # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co09))
    # co10 = CLLocationCoordinate2DMake(37.33556758275723, -122.03503708868698)
    # map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(co10))
    # co_arr = [co01, co02, co03]
    # co_ptr = Pointer.new(CLLocationCoordinate2D.type, co_arr.length)
    # co_ptr[0]= co_arr.clone[0]
    # co_ptr[1]= co_arr.clone[1]
    # co_ptr[2]= co_arr.clone[2]
    # coord = MKPolygon.polygonWithCoordinates(co_ptr, count:3)
    # coord_over = MKOverlayRenderer.alloc.initWithOverlay(coord)
    # map_view.addOverlay(coord)
    # puts "Overlays: #{map_view.overlays}"


    # mp01 = MKMapPointForCoordinate(co01)
    # mp02 = MKMapPointForCoordinate(co02)
    # mp03 = MKMapPointForCoordinate(co03)
    # mp04 = MKMapPointForCoordinate(co04)
    # mp05 = MKMapPointForCoordinate(co05)
    # mp06 = MKMapPointForCoordinate(co06)
    # mp07 = MKMapPointForCoordinate(co07)
    # mp08 = MKMapPointForCoordinate(co08)
    # mp09 = MKMapPointForCoordinate(co09)
    # mp10 = MKMapPointForCoordinate(co10)
    # mp_arr = [mp01, mp02, mp03, mp04, mp05, mp06, mp07, mp08, mp09, mp10]
    #
    # tris = Delaunay::triangulate(mp_arr)
    # # puts "Tris.verts: #{tris[0]}"
    # # puts "Tris.tris: #{tris[1]}"

    # tris[1].each do |tri|
    #   # puts "Current tri: #{tri}"
    #   # puts "Current tri complete: #{tri.complete}"
    #   # puts "WHAT: #{tris[0][tri.p1]}"
    #   # puts "#{tris[0][tri.p1]}, #{tris[0][tri.p2]}, #{tris[0][tri.p3]}"
    #   unless tri.complete == false or tris[0][tri.p1] == nil or tris[0][tri.p2] == nil or tris[0][tri.p3] == nil
    #     tri01 = MKCoordinateForMapPoint(tris[0][tri.p1])
    #     puts "tri01: #{tri01.longitude}"
    #     tri02 = MKCoordinateForMapPoint(tris[0][tri.p2])
    #     puts "tri02: #{tri02.longitude}"
    #     tri03 = MKCoordinateForMapPoint(tris[0][tri.p3])
    #     puts "tri03: #{tri03.longitude}"
    #     tri_ptr = Pointer.new(CLLocationCoordinate2D.type, 3)
    #     tri_ptr[0] = tri01
    #     tri_ptr[1] = tri02
    #     tri_ptr[2] = tri03
    #     tri_poly = MKPolygon.polygonWithCoordinates(tri_ptr, count:3)
    #     puts "tri_poly: #{tri_poly}"
    #     puts "tri_poly pointCount: #{tri_poly.pointCount}"
    #     puts "tri_poly points: #{tri_poly.points}"
    #     puts "tri_poly points: #{tri_poly.locationAtPointIndex(0)}, #{tri_poly.locationAtPointIndex(1)}, #{tri_poly.locationAtPointIndex(2)}"
    #     map_view.addOverlay(tri_poly)
    #   end
    # end

    # center_mappoints = tris[2].map { |center| MKMapPointMake(center.x, center.y) }
    # center_coords = center_mappoints.map { |mappoint| MKCoordinateForMapPoint(mappoint) }
    # center_coords.each do |center|
    #   puts "Center: #{center.longitude}"
    # end
    #
    # tris[2].each do |center|
    #   mp = MKMapPointMake(center.x, center.y)
    #   puts "mp: #{mp}"
    #   map_view.addAnnotation(MKPointAnnotation.alloc.initWithCoordinate(MKCoordinateForMapPoint(mp)))
    # end
  end

  # def locationManager(manager, didUpdateLocations:locations)
  #   puts "GameController.didUpdateLocations: #{locations}"
  # end

  # https://github.com/HipByte/RubyMotionSamples/blob/a387842594fd0ac9d8560d2dc64eff4d87534093/ios/Locations/app/locations_controller.rb
  def locationManager(manager, didUpdateToLocation:newLocation, fromLocation:oldLocation)
    # puts "GameController.didUpdateLocation: #{newLocation} to: #{oldLocation}"
    locationUpdate(newLocation)
  end

  def locationUpdate(location)
    loc = location.coordinate
    map_view.setCenterCoordinate(loc)
  end

  PylonViewIdentifier = 'PylonViewIdentifier'
  def mapView(map_view, viewForAnnotation:annotation)
    puts "\n\nviewForAnnotation"
    # if annotation.kind_of?
    if annotation == map_view.userLocation
      puts "PLAYER"
      return nil
    end
    puts "viewForAnnotation: #{annotation.class}"
    # check to see if it exists and has been queued
    if annotation_view = map_view.dequeueReusableAnnotationViewWithIdentifier(PylonViewIdentifier)
      puts "using existing view"
      annotation_view.annotation = pylon
    else
      # create a new one
      # MKPinAnnotationView is depreciated
      puts "create new view"
      annotation_view = MKMarkerAnnotationView.alloc.initWithAnnotation(annotation, reuseIdentifier:PylonViewIdentifier)
      annotation_view.canShowCallout = false
    end
    annotation_view
  end

  def mapView(map_view, didAddAnnotationViews:views)
    puts "didAddAnnotationViews!!"
  end

  def mapView(map_view, rendererForOverlay:overlay)
    puts "rendererForOverlay: #{overlay}"
    rend = MKPolygonRenderer.alloc.initWithOverlay(overlay)
    rend.lineWidth = 0.75
    rend.strokeColor = UIColor.colorWithHue(0.5, saturation: 0.9, brightness: 0.9, alpha: 1.0)
    # overlay.fillColor = UIColor.systemGreenColor
    rend.fillColor = UIColor.colorWithHue(0.2, saturation: 0.9, brightness: 0.9, alpha: 0.3)
    unless overlay.overlayColor.nil?
      rend.fillColor = overlay.overlayColor.colorWithAlphaComponent(0.3)
    end
    rend.lineJoin = KCGLineJoinMiter

    return rend
  end

  # def mapView(map_view, viewForOverlay:overlay)
  #   # https://stackoverflow.com/questions/16838360/ios-sdk-mapkit-mkpolyline-not-showing
  #   puts "viewForOverlay: #{overlay}"
  #   puts "Overlay type: #{overlay.class}"
  #   if overlay.class == MKPolyline
  #     overlayView = MKPolylineView.alloc.initWithPolyline(overlay)
  #     overlayView.strokeColor = UIColor.systemRedColor
  #     overlayView.lineWidth = 2
  #   end
  #   if overlay.class == MKPolygon
  #     overlayView = MKPolygonView.alloc.initWithPolygon(overlay)
  #     overlayView.strokeColor = UIColor.systemGreenColor
  #     overlayView.lineWidth = 1
  #     overlayView.fillColor = UIColor.systemBlueColor
  #   end
  #   overlayView
  # end

  def renderOverlays
    puts "\n\nrenderOverlays"
    overlaysToRemove = map_view.overlays.mutableCopy
    map_view.removeOverlays(overlaysToRemove)

    vcells = @voronoi_map.voronoiCells

    vcells.each do |cell|
      map_view.addOverlay(cell.overlay)
    end
  end

  def create_new_pylon
    puts "creating new pylon"
    # p = Pylon.new(map_view.centerCoordinate.longitude, map_view.centerCoordinate.latitude)
    # puts p.coordinate.longitude
    # map_view.addAnnotation(p.annotation)
    # map_view.addAnnotation(Pylon.new(map_view.centerCoordinate.latitude, map_view.centerCoordinate.longitude).annotation)
    # map_view.setNeedsDisplay
    # map_view.annotations.each { |ann| puts "Coord: #{ann.coordinate.latitude}, #{ann.coordinate.longitude}" }

    p = Pylon.initWithLocation(map_view.centerCoordinate)
    @voronoi_map.pylons.setObject(p, forKey:p.uuID)
    map_view.addAnnotation(PylonAnnotation.new(p).annotation)
    self.renderOverlays
  end

  def touch_down
    puts "touch down"
    @button_fsm.event(:button_down)
  end

  def touch_up
    puts "touch up"
    @button_fsm.event(:button_up)
  end

  def touch_out
    puts "touch out"
    @button_fsm.event(:button_up)
  end

  def set_button_color(color)
    button_pylon.tintColor = color
  end
end
