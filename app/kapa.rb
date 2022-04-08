class Kapa < FirebaseObject
  extend Debugging
  extend Utilities
  
  # data_hash:
  # {
  #   color,
  #   coordinate
  #   {
  #     latitude
  #     longitude
  #   },
  #   created,
  #   kaitakaro
  #   {
  #     ... array of kaitakaro
  #   }
  # }
  
  attr_accessor :kapa_ref

  attr_reader :color

  DEBUGGING = true

  def initialize(ref, args={})
    puts "KAPA INITIALIZE".light_blue
    @kapa_ref = ref
    puts "KAPA REF: #{@kapa_ref.URL}"
    puts args
    self.color = args["color"] ? CIColor.alloc.initWithString(args["color"]) : CIColor.alloc.initWithColor(UIColor.systemYellowColor)
  end

  def color=(in_color)
    puts "KAPA SET COLOR".blue 
    @color = in_color
    puts @color.stringRepresentation
    @kapa_ref.updateChildValues(
      {"color" => in_color.stringRepresentation}, withCompletionBlock:
      lambda do | error, ref |
        puts "KAPA SET COLOR COMPLETE".blue
      end
    )
  end
  
  def within_distance(in_coordinate)
    puts "KAPA WITHIN_DISTANCE".blue
    
    distance = get_distance(in_coordinate, get_node('coordinate'))
    
    return distance <= 3
  end
  
  def kaitakaro(&block)
    @ref.child('kaitakaro').getDataWithCompletionBlock(
      lambda do | error, data_snapshot |
        return data_snapshot.children unless block
        
        i = 0
        while i < data_snapshot.childrenCount
          block.call at(i)
          i += 1
        end
      end
    )
  end
end
