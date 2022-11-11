# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiMap.m
class VoronoiMap
  include Utilities
  include VoronoiUtilities

  attr_accessor :voronoi_cells_cache

  DEBUGGING = false

  def initialize
    puts 'VORONOI_MAP INITIALIZE'.green if DEBUGGING
  end

  # Oops we might need a new one of these with async
  # rubocop:disable Metrics
  def voronoi_cells_from_pylons(_in_pylons)
    puts 'VORONOI_MAP: VORONOI_CELLS_FROM_PYLONS'.blue if DEBUGGING

    return @voronoi_cells_cache if !@voronoi_cells_cache.nil? && !Machine.instance.takaro_fbo.pouwhenua_is_dirty

    voronoi_cells = []
    taiapa_region = Machine.instance.takaro_fbo.taiapa_region
    bounding_box = mkmaprect_for_coord_region(taiapa_region).to_cgrect

    voronoi = Voronoi.new
    # not sure we need this
    voronoi.boundingBox = bounding_box

    # TODO: rename this with pouwhenua
    # pylons_array = Machine.instance.takaro.pouwhenua_array
    # pylons_array = Machine.instance.takaro_fbo.pouwhenua_array_enabled_only
    pylons_array = Machine.instance.takaro_fbo.marker_hash.values

    # site_array_map = Machine.instance.takaro.pouwhenua_array.map do |p|
    # site_array_map = Machine.instance.takaro_fbo.pouwhenua_array_enabled_only.map do |p|
    site_array_map = Machine.instance.takaro_fbo.marker_hash.values.map do |p|
      # puts "coordinate: #{p['coordinate']}".focus
      loc_coord = format_to_location_coord(p['coordinate'])
      color = CIColor.colorWithString(p['color'])
      PouSite.new(loc_coord.to_cgpoint, color, p['key'])
    end

    puts 'COMPUTEWITHSITES'.red if DEBUGGING
    result = voronoi.computeWithSites(site_array_map, andBoundingBox: bounding_box)
    puts 'COMPUTEWITHSITES FINISHED'.red if DEBUGGING

    result.cells.each_with_index do |cell, _index|
      # In the old version, this would cross-reference the pylon list
      # for us, we need to access the kapa
      p = pylons_array.detect { |h| h['key'] == cell.site.pouwhenua_key }

      c = Wakawaka.new(cell, p)

      voronoi_cells << c
    end

    puts 'FINISHNG VORONOI_CELLS_FROM_PYLONS'.blue if DEBUGGING
    Machine.instance.takaro_fbo.pouwhenua_is_dirty = false
    @voronoi_cells_cache = voronoi_cells
  end
  alias voronoiCellsFromPylons voronoi_cells_from_pylons
  alias voronoi_cells_from_pouwhenua voronoi_cells_from_pylons
  # rubocop:enable Metrics

  def voronoi_cells
    puts 'VORONOI_MAP: VORONOI_CELLS'.blue if DEBUGGING
    # voronoi_cells_from_pylons(@pylons)
    voronoi_cells_from_pylons(nil)
  end
  alias voronoiCells voronoi_cells

  def annotations
    puts 'VORONOI_MAP ANNOTATIONS'.focus
    annotations = []

    # Machine.instance.takaro.pouwhenua_array.each do |p|
    Machine.instance.takaro_fbo.pouwhenua_array_enabled_only.each do |p|
      # puts "Adding p: #{p}".focus
      pa = PouAnnotation.alloc.initWithCoordinate(
        format_to_location_coord(p['coordinate'])
      )
      pa.color = UIColor.alloc.initWithCIColor(CIColor.alloc.initWithString(p['color']))
      annotations << pa
    end

    # puts "Annotations: #{annotations}".focus
    annotations
  end
end
