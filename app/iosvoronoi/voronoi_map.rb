# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiMap.m
class VoronoiMap
  include Utilities
  include VoronoiUtilities

  attr_accessor :voronoi_cells_cache

  DEBUGGING = false

  def initialize
    puts 'VORONOI_MAP INITIALIZE'.green if DEBUGGING
    @voronoi_cells_cache = []
    recalculate_cells
  end

  # Oops we might need a new one of these with async
  # rubocop:disable Metrics
#   def voronoi_cells_from_pylons(_in_pylons)
#     puts 'VORONOI_MAP: VORONOI_CELLS_FROM_PYLONS'.blue if DEBUGGING
#
#     # return @voronoi_cells_cache if !@voronoi_cells_cache.nil? && !Machine.instance.takaro_fbo.pouwhenua_is_dirty
#
#     voronoi_cells = []
#     taiapa_region = Machine.instance.takaro_fbo.taiapa_region
#     bounding_box = mkmaprect_for_coord_region(taiapa_region).to_cgrect
#
#     voronoi = Voronoi.new
#     # not sure we need this
#     voronoi.boundingBox = bounding_box
#
#     # TODO: rename this with pouwhenua
#     # pylons_array = Machine.instance.takaro.pouwhenua_array
#     # pylons_array = Machine.instance.takaro_fbo.pouwhenua_array_enabled_only
#     pylons_array = Machine.instance.takaro_fbo.markers_hash.values
#
#     # site_array_map = Machine.instance.takaro.pouwhenua_array.map do |p|
#     # site_array_map = Machine.instance.takaro_fbo.pouwhenua_array_enabled_only.map do |p|
#     site_array_map = Machine.instance.takaro_fbo.markers_hash.values.map do |p|
#       # puts "coordinate: #{p['coordinate']}".focus
#       loc_coord = format_to_location_coord(p['coordinate'])
#       color = CIColor.colorWithString(p['color'])
#       PouSite.new(loc_coord.to_cgpoint, color, p['key'])
#     end
#
#     puts 'COMPUTEWITHSITES'.red if DEBUGGING
#     result = voronoi.computeWithSites(site_array_map, andBoundingBox: bounding_box)
#     puts 'COMPUTEWITHSITES FINISHED'.red if DEBUGGING
#
#     result.cells.each_with_index do |cell, _index|
#       # In the old version, this would cross-reference the pylon list
#       # for us, we need to access the kapa
#       p = pylons_array.detect { |h| h['key'] == cell.site.pouwhenua_key }
#
#       c = Wakawaka.new(cell, p)
#
#       voronoi_cells << c
#     end
#
#     puts 'FINISHNG VORONOI_CELLS_FROM_PYLONS'.blue if DEBUGGING
#     # Machine.instance.takaro_fbo.pouwhenua_is_dirty = false
#     @voronoi_cells_cache = voronoi_cells
#   end
#   alias voronoiCellsFromPylons voronoi_cells_from_pylons
#   alias voronoi_cells_from_pouwhenua voronoi_cells_from_pylons
#   # rubocop:enable Metrics

  # rubocop:disable Metrics/AbcSize
  def recalculate_cells
    mp __method__

    voronoi_cells = []

#     playfield_region = Machine.instance.takaro_fbo.playfield_region
#     mp playfield_region
#
#     # bounding_box = mkmaprect_for_coord_region(taiapa_region).to_cgrect
#     bounding_box = mkmaprect_for_coord_region(playfield_region).to_cgrect
#     mp bounding_box
    bounding_box = Machine.instance.takaro_fbo.bounding_box_cgrect

    voronoi = Voronoi.new
    # not sure we need this
    voronoi.boundingBox = bounding_box

    # pylons_array = Machine.instance.takaro_fbo.markers_hash.values
    markers_array = Machine.instance.takaro_fbo.markers_hash.values
    mp 'markers_array'
    mp markers_array

    # site_array_map = Machine.instance.takaro_fbo.markers_hash.values.map do |p|
    mp 'Iterating through markers'
    site_array_map = markers_array.map do |marker|
      mp marker
      loc_coord = format_to_location_coord(marker['coordinate'])
      color = CIColor.colorWithString(marker['color'])
      VoronoiSite.new(loc_coord.to_cgpoint, color, marker['team_key'])
    end

    mp 'site_array_map'
    mp site_array_map

    puts 'COMPUTEWITHSITES'.red if DEBUGGING
    result = voronoi.computeWithSites(site_array_map, andBoundingBox: bounding_box)
    puts 'COMPUTEWITHSITES FINISHED'.red if DEBUGGING

    mp 'result'
    mp result.cells
    result.cells.each do |c|
      mp "result cell: #{c}"
      mp "result site: #{c.site}"
    end

    # We now have a list of generated cells
    # The next step is to reassociate those cells with their
    # corresponding Sites.
    mp 'Iterating through cells'
    result.cells.each_with_index do |cell, _index|
      marker = markers_array.detect { |marker| marker['team_key'] == cell.site.pouwhenua_key }
      mp marker
      c = VoronoiCell.new(cell, marker)
      mp c

      voronoi_cells << c
    end

    mp 'Matched voronoi cells:'
    mp voronoi_cells

    puts 'FINISHNG VORONOI_CELLS_FROM_PYLONS'.blue if DEBUGGING
    # Machine.instance.takaro_fbo.pouwhenua_is_dirty = false
    @voronoi_cells_cache = voronoi_cells
  end
  # rubocop:enable Metrics/AbcSize

  def voronoi_cells
    mp __method__
    mp @voronoi_cells_cache

    @voronoi_cells_cache
  end
  alias voronoiCells voronoi_cells
end
