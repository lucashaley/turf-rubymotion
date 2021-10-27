# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHECellTowerAnnotation.h
class PylonAnnotation #< NSObject # is there a reason this is an NSObject? Nope, because it's all a subclass of NSObject
  attr_accessor :coordinate, :pylon_id, :title

  def initialize(coord)
    @coordinate = coord
  end

  def self.init_with_pylon(pylon)
    anno = PylonAnnotation.new(pylon.location.coordinate)
    # anno.pylon_id = pylon.uuid
    anno.title = pylon.title

    return anno
  end

  def set_coordinate(coord)
    @coordinate = coord
  end
  alias :setCoordinate :set_coordinate
end
