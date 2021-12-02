# class Site
#   attr_accessor :coord,
#                 :voronoi_id,
#                 :uuid
#
#   DEBUGGING = true
#
#   # Expects a CGPoint
#   def initialize(in_coord = CGPointZero)
#     puts "SITE INITIALIZE".green if DEBUGGING
#     @coord = in_coord
#     @uuid = NSUUID.UUID
#   end
#
#   def to_s
#     "SITE coord: #{coord}, uuid: #{uuid}"
#   end
#
#   def init_with_value(in_value)
#     puts "SITE INIT_WITH_VALUE".green if DEBUGGING
#     Site.new(in_value.CGPointValue)
#   end
#
#   def set_coord_as_value(in_value)
#     @coord = in_value.CGPointValue
#   end
#   alias :setCoordAsValue :set_coord_as_value
#
#   def coord_as_value
#     NSValue.valueWithCGPoint(@coord)
#   end
#   alias :coordAsValue :coord_as_value
#
#   def set_x(temp_x)
#     puts "SITE SET_X".blue if DEBUGGING
#     @coord = CGPointMake(temp_x, @coord.y)
#   end
#   alias :setX :set_x
#   def x
#     puts "SITE X".blue if DEBUGGING
#     puts self
#     @coord.x
#   end
#
#   def set_y(temp_y)
#     puts "SITE SET_Y".blue if DEBUGGING
#     @coord = CGPointMake(@coord.x, temp_y)
#   end
#   alias :setY :set_y
#   def y
#     puts "SITE Y".blue if DEBUGGING
#     @coord.y
#   end
#
#   def uuid_string
#     puts "SITE UUID_STRING".blue if DEBUGGING
#     @uuid.UUIDString
#   end
#
#   def self.sort_sites(site_array)
#     puts "SITE SORT_SITES".blue if DEBUGGING
#     puts "Before:"
#     site_array.each do |s|
#       puts s
#     end
#     site_array.sortUsingSelector("compare:")
#     puts "After:"
#     site_array.each do |s|
#       puts s
#     end
#   end
#   class <<self
#     alias :sortSites :sort_sites
#   end
#
#   def compare(s)
#     puts "SITE COMPARE".blue if DEBUGGING
#     return NSOrderedDescending if @coord.y < s.y
#     return NSOrderedAscending if @coord.y > s.y
#     return NSOrderedDescending if @coord.x < s.x
#     return NSOrderedAscending if @coord.x > s.x
#
#     return NSOrderedSame
#   end
#
#   def setVoronoiId(in_value)
#     puts "SITE SETVORONOIID".blue if DEBUGGING
#     puts "in_value: #{in_value}"
#     @voronoi_id = in_value
#   end
#   def voronoiId
#     @voronoi_id
#   end
# end
