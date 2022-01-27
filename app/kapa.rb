class Kapa
  attr_accessor :kapa_ref

  attr_reader :color,
              :name

  DEBUGGING = true

  def initialize(ref, args={})
    puts "KAPA INITIALIZE".light_blue if DEBUGGING
    @kapa_ref = ref
    puts "KAPA REF: #{@kapa_ref.URL}"
    puts args
    self.name = args["name"] ? args["name"] : "Testing"
    self.color = args["color"] ? CIColor.alloc.initWithString(args["color"]) : CIColor.alloc.initWithColor(UIColor.systemYellowColor)
  end

  def color=(in_color)
    puts "KAPA SET COLOR".blue if DEBUGGING
    @color = in_color
    puts @color.stringRepresentation
    @kapa_ref.updateChildValues(
      {"color" => in_color.stringRepresentation}, withCompletionBlock:
      lambda do | error, ref |
        puts "KAPA SET COLOR COMPLETE".blue if DEBUGGING
      end
    )
  end

  def name=(in_name)
    puts "KAPA SET NAME".blue if DEBUGGING
    @name = in_name
    puts @name
    @kapa_ref.updateChildValues(
      {"name" => in_name}, withCompletionBlock:
      lambda do | error, ref |
        puts "KAPA SET NAME COMPLETE".blue if DEBUGGING
      end
    )
  end
end
