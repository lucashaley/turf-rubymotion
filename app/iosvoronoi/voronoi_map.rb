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
    taiapa_region = Machine.instance.takaro.taiapa_region
    bounding_box = mkmaprect_for_coord_region(taiapa_region).to_cgrect

    voronoi = Voronoi.new
    # not sure we need this
    voronoi.boundingBox = bounding_box

    # pylons_array = Machine.instance.takaro.pouwhenua_array

    # new pouwhenua_array way
    # When a Site is created, it gets assigned a NSUUID.
    # That NSUUID gets passed on to the generated cell during the computeWithSites
    # method.
    site_array_map = Machine.instance.takaro.pouwhenua_array.map { |p|
      # Site.alloc.initWithCoord(format_to_location_coord(p["location"]).to_cgpoint)
      # PouSite.alloc.initWithCoord(format_to_location_coord(p["location"]).to_cgpoint)
      PouSite.new(format_to_location_coord(p["location"]).to_cgpoint, CIColor.colorWithString(p['color']))
    }
    puts "site_array_map: #{site_array_map.inspect}".focus

    puts "COMPUTEWITHSITES".red if DEBUGGING
    result = voronoi.computeWithSites(site_array_map, andBoundingBox: bounding_box)
    puts "COMPUTEWITHSITES FINISHED".red if DEBUGGING

    result.cells.each_with_index do |cell, index|
      puts "cell: #{cell.site}".focus
      
      # In the old version, this would cross-reference the pylon list
      # for us, we need to access the kapa
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
    puts "VORONOI_MAP ANNOTATIONS".focus
    # # What is this doing here
    annotations = []
    #
    # @pylons.allValues.each do |pylon|
    #   anno = PylonAnnotation.new(pylon)
    #   anno.title = pylon.title
    #
    #   annotations << anno
    # end
    #
    # annotations

    # Let's try adding the pouwhenua
    Machine.instance.takaro.pouwhenua_array.each do |p|
      puts "Adding p: #{p}".focus
      pa = PouAnnotation.alloc.initWithCoordinate(
        format_to_location_coord(p['location'])
      )
      pa.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(p['color']))
      annotations << pa
    end

    puts "Annotations: #{annotations}".focus
    annotations
  end

  def add_pylon(pylon)
    puts "VORONOI_MAP ADD_PYLON".blue if DEBUGGING
    # puts "pylon: #{pylon}"
    @pylons.setObject(pylon, forKey: pylon.uuID.UUIDString)

    # puts "pylons: "
    # @pylons.each do |k, v|
    #   puts "#{k}: #{v}"
    # end
  end

  def add_pouwhenua(pouwhenua)
    puts "VORONOI_MAP ADD_POUWHENUA".blue if DEBUGGING
    # puts "Pouwhenua: #{pouwhenua}"
    # puts pouwhenua.uuid_string
    @pylons.setObject(pouwhenua, forKey: pouwhenua.uuid_string)

    # puts "pylons: "
    # @pylons.each do |k, v|
    #   puts "#{k}: #{v}"
    # end
  end
end
