# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiMap.m
class VoronoiMap
  # @pylons is a dictionary, with key as the UUID and value as the pylon
  # This will be translated into Firebase structure.
  attr_accessor :pylons

  def initialize
    @pylons = Hash.new
  end

  def voronoi_cells_from_pylons(in_pylons)
    # puts "\n\nvoronoi_cells_from_pylons"
    voronoi_cells = []
    voronoi = Voronoi.alloc.init
    voronoi.boundingBox = Machine.instance.bounding_box
    # puts "\nvoronoi_cells_from_pylons voronoi: #{voronoi}"
    # puts "\nvoronoi_cells_from_pylons voronoi.boundingBox: #{voronoi.boundingBox.origin.x}, #{voronoi.boundingBox.origin.y}, #{voronoi.boundingBox.size.height}, #{voronoi.boundingBox.size.width}"
    pylons = NSDictionary.dictionaryWithDictionary(in_pylons)
    # puts "\n\nvoronoi_cells_from_pylons::pylons: #{pylons}\n\n"
    # puts "pylons.allValues: #{pylons.allValues}"

    pylons_array = NSArray.arrayWithArray(pylons.allValues)
    # puts "#{pylons_array}"
    result = voronoi.computeWithSites(pylons_array, andBoundingBox: CGRectMake(voronoi.boundingBox.origin.x, voronoi.boundingBox.origin.y, voronoi.boundingBox.size.height, voronoi.boundingBox.size.width))

    result.cells.each_with_index do |cell, index|
      pylon = pylons.objectForKey(cell.site.uuID)

      c = Wakawaka.new(cell, pylon)

      voronoi_cells << c
    end

    return voronoi_cells
  end
  alias :voronoiCellsFromPylons :voronoi_cells_from_pylons

  def voronoi_cells
    return voronoi_cells_from_pylons(@pylons)
  end
  alias :voronoiCells :voronoi_cells

  def annotations
    annotations = []

    @pylons.allValues.each do |pylon|
      anno = PylonAnnotation.new(pylon)
      anno.title = pylon.title

      annotations << anno
    end

    annotations
  end
end
