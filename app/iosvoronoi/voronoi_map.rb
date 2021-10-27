# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHEVoronoiMap.m
class VoronoiMap
  # @pylons is a dictionary, with key as the UUID and value as the pylon
  # This will be translated into Firebase structure.
  attr_accessor :pylons

  def initialize
    @pylons = Hash.new
  end

  def voronoi_cells_from_pylons(in_pylons)
    puts "\n\nvoronoi_cells_from_pylons"
    voronoi_cells = []
    voronoi = Voronoi.alloc.init
    voronoi.boundingBox = Machine.instance.bounding_box
    # puts "\nvoronoi_cells_from_pylons voronoi: #{voronoi}"
    # puts "\nvoronoi_cells_from_pylons voronoi.boundingBox: #{voronoi.boundingBox.origin.x}, #{voronoi.boundingBox.origin.y}, #{voronoi.boundingBox.size.height}, #{voronoi.boundingBox.size.width}"
    pylons = NSDictionary.dictionaryWithDictionary(in_pylons)
    # puts "\n\nvoronoi_cells_from_pylons::pylons: #{pylons}\n\n"
    # puts "pylons.allValues: #{pylons.allValues}"

    puts "\n\nGETTING READY\n\n"
    # pylons_ptr = Pointer.new(NSArray.type, pylons.length)
    # puts "#{pylons_ptr}"
    # pylons_ptr[0] = pylons.allValues[0]
    pylons_array = NSArray.arrayWithArray(pylons.allValues)
    puts "#{pylons_array}"
    result = voronoi.computeWithSites(pylons_array, andBoundingBox: CGRectMake(voronoi.boundingBox.origin.x, voronoi.boundingBox.origin.y, voronoi.boundingBox.size.height, voronoi.boundingBox.size.width))
    puts "\n\nDONE\n\n"

    result.cells.each_with_index do |cell, index|
      puts "\nvoronoi_cells_from_pylons::cell#{index}: #{cell} site:#{cell.site}"
      pylon = pylons.objectForKey(cell.site.uuID)
      # puts "voronoi_cells_from_pylons::pylon: #{pylon}\n\n"

      # cell = Cell.alloc.init_with_cell(cell, pylon: pylon)
      # cell = PylonCell.new(cell, pylon: pylon)
      c = Wakawaka.new(cell, pylon)

      # voronoi_cells << cell
      voronoi_cells << c
    end

    return voronoi_cells
  end

  def voronoi_cells
    return voronoi_cells_from_pylons(@pylons)
  end
  alias :voronoiCells :voronoi_cells

  def annotations
    puts "\n\nannotations"
    annotations = []

    puts "pylons.addValues: #{@pylons.allValues}"
    @pylons.allValues.each do |pylon|
      # annotations << PylonAnnotation.alloc.init
      anno = PylonAnnotation.new(pylon.location.coordinate)
      anno.title = pylon.title
      anno.color = pylon.color

      puts "anno: #{anno}"

      annotations << anno
    end

    annotations
  end
end
