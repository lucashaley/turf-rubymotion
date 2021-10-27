# class Pylon
#   attr_reader :coordinate, :owner, :lifespan, :birthdate, :annotation
#
#   def initialize(lat, long)
#     @coordinate = CLLocationCoordinate2D.new
#     @coordinate.latitude = lat
#     @coordinate.longitude = long
#     @annotation = MKPointAnnotation.alloc.initWithCoordinate(@coordinate)
#     # @owner = owner
#     # @lifespan = lifespan
#     # @birthdate = birthdate
#   end
#
#   def life
#     return DateTime.now() - birthdate
#   end
#
#   Test_Pylons = [
#     Pylon.new(37.33224775088951, -122.03043116202183),
#     Pylon.new(37.33241108181487, -122.03069094931799),
#     Pylon.new(37.33161364148488, -122.03045331411569),
#     Pylon.new(37.3327634456037, -122.02935601332467)
#   ]
# end
