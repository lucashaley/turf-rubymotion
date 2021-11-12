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
end

module Debugging
  DEBUGGING = false
end