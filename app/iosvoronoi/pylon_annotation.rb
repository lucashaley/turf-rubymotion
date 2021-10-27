# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHECellTowerAnnotation.h
class PylonAnnotation # < MKPointAnnotation # do we want to do this?
  attr_accessor :title, :pylon, :annotation

  def initialize(pylon)
    puts "\n\nPylonAnnotation::initialize location: #{pylon.location}"
    # @coordinate = pylon.location
    # @pylon_id = pylon.uuID
    @pylon = pylon
    @annotation = MKPointAnnotation.alloc.initWithCoordinate(pylon.location)
  end

  # def self.initWithLocation(coord)
  #   anno = PylonAnnotation.alloc.init
  #   anno.coordinate = coord
  # end

  def initWithPylon(pylon)
    anno = PylonAnnotation.new(pylon.location.coordinate)
    anno.pylon_id = pylon.uuID
    # anno.title = pylon.title

    return anno
  end
  alias :init_with_pylon :initWithPylon

  def color
    @pylon.color
  end

  def pylon_id
    @pylon.uuID
  end

  def set_coordinate(coord)
    # @coordinate = coord
    @annotation.coordinate = coord
    # return nil
  end
  alias :setCoordinate :set_coordinate

  def coordinate
    @annotation.coordinate
  end
end
