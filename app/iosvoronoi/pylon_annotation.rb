# https://github.com/DevRhys/iosvoronoi/blob/master/Example/iosvoronoi/BHECellTowerAnnotation.h
class PylonAnnotation # < MKPointAnnotation # do we want to do this? Oh wait maybe to get the color
  attr_accessor :title, :pylon, :annotation

  DEBUGGING = false

  def initialize(pylon)
    puts "PYLONANNOTATION: INITIALIZE".green if DEBUGGING
    # @coordinate = pylon.location
    # @pylon_id = pylon.uuID
    @pylon = pylon
    @annotation = MKPointAnnotation.alloc.initWithCoordinate(pylon.location)
    pylon.annotation = @annotation
    pylon.set_annotation(@annotation)
  end

  # def self.initWithLocation(coord)
  #   anno = PylonAnnotation.alloc.init
  #   anno.coordinate = coord
  # end

  def initWithPylon(pylon)
    puts "PYLONANNOTATION: INITWITHPYLON".green if DEBUGGING
    anno = PylonAnnotation.new(pylon.location.coordinate)
    anno.pylon_id = pylon.uuID
    # anno.title = pylon.title
    pylon.annotation = anno

    return anno
  end
  alias :init_with_pylon :initWithPylon

  def color
    @pylon.get_uicolor
  end

  def pylon_id
    @pylon.uuID
  end

  # MKAnnotation interface methods
  def set_coordinate(coord)
    @annotation.coordinate = coord
  end
  alias :setCoordinate :set_coordinate

  def coordinate
    @annotation.coordinate
  end
end
