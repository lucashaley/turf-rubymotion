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

class Fixnum
  def to_firebase
    self
  end
end

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
  def to_firebase
    coordinate.to_firebase
  end
end

class CLLocationCoordinate2D
  def to_s
    to_firebase.to_s
  end

  def to_firebase
    {latitude: latitude, longitude: longitude}
  end

  def +(loc)
    CLLocationCoordinate2DMake(latitude + loc.latitude, longitude + loc.longitude)
  end

  def /(denom)
    CLLocationCoordinate2DMake(latitude/denom, longitude/denom)
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
          [ k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v) ]
        end
      ]
    when Enumerable
      h.map { |v| recursive_symbolize_keys(v) }
    else
      h
    end
  end
end
