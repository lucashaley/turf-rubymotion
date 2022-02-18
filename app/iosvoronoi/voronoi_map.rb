# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiMap.m
class VoronoiMap
  include Utilities
  include VoronoiUtilities
  # @pylons is a dictionary, with key as the UUID and value as the pylon
  # This will be translated into Firebase structure.
  attr_accessor :pylons

  DEBUGGING = true

  ##
  #
  # DATA STRUCTURES
  #
  # it would be good to know this.
  #
  # Voronoi boundingBox expects a CGRect
  # Site expects a CGPoint
  #
  # The UI will probably want a MKCoordinateRegion, centered around the midpoint
  #
  # computeWithSites expects an array

  def initialize
    puts "VORONOI_MAP INITIALIZE".green if DEBUGGING
    # what is the structure of this hash?
    @pylons = {}
  end

  def voronoi_cells_from_pylons(in_pylons)
    puts "VORONOI_MAP: VORONOI_CELLS_FROM_PYLONS".blue if DEBUGGING

    puts "in_pylons: #{in_pylons}".red if DEBUGGING

    voronoi_cells = []
    voronoi = Voronoi.new

    # Change the mkmaprect to a MKCoordinateRegion
    # coord_region = MKCoordinateRegionForMapRect(Machine.instance.takaro.taiapa)
    # puts "coord_region: #{coord_region}".focus
    # Then change it into a CGRect for this map
    # region = Machine.instance.current_view.map_view.convertRegion(coord_region, toRectToView: nil)
    region = Machine.instance.takaro.taiapa.to_cgrect
    puts "\nregion: #{region.origin.x}:#{region.origin.y}".focus
    puts "#{region.size.height}:#{region.size.width}\n".focus

    taiapa_region = Machine.instance.takaro.taiapa_region
    puts "\nregion: #{taiapa_region.center.latitude}:#{taiapa_region.center.longitude}".focus
    puts "#{taiapa_region.span.latitudeDelta}:#{taiapa_region.span.longitudeDelta}\n".focus

    # puts "bounding_box: #{Machine.instance.bounding_box}".focus
    # voronoi.boundingBox = Machine.instance.bounding_box
    voronoi.boundingBox = region
    # puts "\nvoronoi_cells_from_pylons voronoi: #{voronoi}"
    # puts "\nvoronoi_cells_from_pylons voronoi.boundingBox: #{voronoi.boundingBox.origin.x}, #{voronoi.boundingBox.origin.y}, #{voronoi.boundingBox.size.height}, #{voronoi.boundingBox.size.width}"
    # pylons = NSDictionary.dictionaryWithDictionary(in_pylons)
    #
    # puts "\n\nvoronoi_cells_from_pylons::pylons: #{pylons}\n\n".focus
    # puts "pylons.allValues: #{pylons.allValues}".focus
    #
    # pylons_array = NSArray.arrayWithArray(pylons.allValues)
    # puts "#{pylons_array}".red

    # site_array = []
    pylons_array = Machine.instance.takaro.pouwhenua_array
    # puts "pylons_array: #{pylons_array}".focus
    # # Create temp array with new Sites
    # pylons_array.each { |p|
    #   puts "pylon: #{p["coordinate"]["latitude"]}".focus
    #   puts "#{CLLocationCoordinate2DMake(p["coordinate"]["latitude"], p["coordinate"]["longitude"]).latitude}"
    #   map_point = MKMapPointForCoordinate(
    #     CLLocationCoordinate2DMake(p["coordinate"]["latitude"], p["coordinate"]["longitude"])
    #   )
    #   # site_array << Site.alloc.initWithCoord(CGPointMake(map_point.x, map_point.y))
    #
    #   s = Site.alloc.initWithCoord(map_point.to_cgpoint)
    #   puts "s: #{s.coord.x}".focus
    #   site_array << Site.alloc.initWithCoord(map_point.to_cgpoint)
    # }

    site_array_map = pylons_array.map { |p|
      # cgpoint = format_to_location_coord(p["coordinate"]).to_cgpoint
      Site.alloc.initWithCoord(format_to_location_coord(p["coordinate"]).to_cgpoint)
    }
    puts "site_array_map: #{site_array_map.inspect}".focus

    # Let's check it all
    # puts "site_array:".focus
    # site_array.each_with_index do | s, index |
    #   puts "Site #{index}: #{s.coord.x}, #{s.coord.y}".focus
    # end
    # puts "region:".focus
    # puts "#{region.origin.x}, #{region.origin.y}".focus

    puts "COMPUTEWITHSITES".red if DEBUGGING
    # TODO make this prettier
    # result = voronoi.computeWithSites(site_array, andBoundingBox: CGRectMake(voronoi.boundingBox.origin.x, voronoi.boundingBox.origin.y, voronoi.boundingBox.size.height, voronoi.boundingBox.size.width))
    result = voronoi.computeWithSites(site_array_map, andBoundingBox: mkmaprect_for_coord_region(taiapa_region).to_cgrect)
    puts "COMPUTEWITHSITES FINISHED".red if DEBUGGING

    result.cells.each_with_index do |cell, index|
      puts "cell: #{cell.description}".focus
      pylon = pylons.objectForKey(cell.site.uuID)

      c = Wakawaka.new(cell, pylon)

      voronoi_cells << c
    end

    puts "FINISHNG VORONOI_CELLS_FROM_PYLONS".blue if DEBUGGING
    voronoi_cells
  end
  alias :voronoiCellsFromPylons :voronoi_cells_from_pylons
  alias :voronoi_cells_from_pouwhenua :voronoi_cells_from_pylons

  def voronoi_cells
    puts "VORONOI_MAP: VORONOI_CELLS".blue if DEBUGGING
    voronoi_cells_from_pylons(@pylons)
  end
  alias :voronoiCells :voronoi_cells

  def annotations
    # What is this doing here
    annotations = []

    @pylons.allValues.each do |pylon|
      anno = PylonAnnotation.new(pylon)
      anno.title = pylon.title

      annotations << anno
    end

    annotations
  end

  def add_pylon(pylon)
    puts "VORONOI_MAP ADD_PYLON".blue if DEBUGGING
    puts "pylon: #{pylon}"
    @pylons.setObject(pylon, forKey: pylon.uuID.UUIDString)

    puts "pylons: "
    @pylons.each do |k, v|
      puts "#{k}: #{v}"
    end
  end

  def add_pouwhenua(pouwhenua)
    puts "VORONOI_MAP ADD_POUWHENUA".blue if DEBUGGING
    puts "Pouwhenua: #{pouwhenua}"
    puts pouwhenua.uuid_string
    @pylons.setObject(pouwhenua, forKey: pouwhenua.uuid_string)

    puts "pylons: "
    @pylons.each do |k, v|
      puts "#{k}: #{v}"
    end
  end
end
