# https://stackoverflow.com/questions/1489183/how-can-i-use-ruby-to-colorize-the-text-output-to-a-terminal
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red # Errors
    colorize(31)
  end

  def green # Constructors
    colorize(32)
  end

  def yellow # observers
    colorize(33)
  end

  def blue # Methods
    colorize(34)
  end

  def pink # States
    colorize(35)
  end

  def light_blue # Apple
    colorize(36)
  end

  def focus
    "\e[37;40;1m#{self}\e[0m"
  end

  def to_firebase
    self
  end
end

# rubocop:disable Lint/UnifiedInteger
class Fixnum
  def to_firebase
    self
  end
end
# rubocop:enable Lint/UnifiedInteger

class CIColor
  def to_firebase
    stringRepresentation
  end
end

class CGPoint
  def to_s
    puts "CGPOINT x: #{x}, y: #{y}"
  end
end

# class CLLocationPoint
#   def to_s
#     puts "CLLOCATIONPOINT"
#   end
# end

class CLLocation
  def to_hash
    coordinate.to_hash
  end
end

class CLLocationCoordinate2D
  def to_s
    to_hash.to_s
  end

  def to_hash
    { 'latitude' => latitude, 'longitude' => longitude }
  end

  def +(other)
    CLLocationCoordinate2DMake(latitude + other.latitude, longitude + other.longitude)
  end

  def /(other)
    CLLocationCoordinate2DMake(latitude / other, longitude / other)
  end

  def to_cgpoint
    MKMapPointForCoordinate(self).to_cgpoint
  end
end

class MKMapPoint
  def to_cgpoint
    CGPointMake(x, y)
  end
end

class MKMapRect
  def to_cgrect
    CGRectMake(
      origin.x,
      origin.y,
      size.width,
      size.height
    )
  end
end

class Hash
  def to_CLLocationCoordinate2D
    CLLocationCoordinate2DMake(self['latitude'], self['longitude'])
  end

  def extract(*keys)
    Hash[[keys, self.values_at(*keys)].transpose]
  end

  def except(*keys)
    desired_keys = self.keys - keys
    Hash[[desired_keys, self.values_at(*desired_keys)].transpose]
  end

  def test
    puts 'TESTING'
  end
end

class Numeric
  def minutes
    self * 60
  end
end

module Debugging
  module_function

  DEBUGGING = false

  def recursive_symbolize_keys(h)
    case h
    when Hash
      Hash[
        h.map do |k, v|
          [k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v)]
        end
      ]
    when Enumerable
      h.map { |v| recursive_symbolize_keys(v) }
    else
      h
    end
  end
end

module Utilities
  module_function

  def get_distance(coord_a, coord_b)
    # puts 'UTILITIES GET_DISTANCE'.blue
    distance = MKMetersBetweenMapPoints(
      MKMapPointForCoordinate(
        format_to_location_coord(coord_a)),
      MKMapPointForCoordinate(
        format_to_location_coord(coord_b))
    )
  end

  def format_to_location_coord(input)
    # puts 'UTILITIES FORMAT_TO_LOCATION_COORD'.blue
    # puts "Input: #{input.class}: #{input}".red
    case input
    when Hash
      return CLLocationCoordinate2DMake(input['latitude'], input['longitude'])
    when CLLocationCoordinate2D
      return input
    end
    0
  end

  def random_color
    "#{rand.round(2)} #{rand.round(2)} #{rand.round(2)} 1"
  end

  def puts_open
    puts "\n"
    puts "\n|" * 2
    puts '|' + '_' * 89
  end

  def puts_close
    puts '|' + '??' * 89
    puts "|\n" * 2
    puts "\n"
  end
end
