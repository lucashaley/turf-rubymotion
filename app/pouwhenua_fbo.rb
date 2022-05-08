# {
#   color,
#   created,
#   lifespan,
#   location # CHANGE TO COORDINATE
#   {
#     latitude,
#     longitude
#   },
#   title
# }

class PouwhenuaFbo < FirebaseObject
  attr_accessor :machine

  def initialize(in_ref, in_data_hash)
    in_data_hash.merge!('enabled' => 'true')
    super.tap do |k|
      k.machine = StateMachine::Base.new start_state: :start, verbose: DEBUGGING
      k.machine.when :start do |state|
        state.on_entry { puts 'Pouwhenua state start'.pink }
        state.transition_to :kapa_death,
                            after: in_data_hash['lifespan_ms'],
                            action: proc { destroy }
      end
      k.machine.start!
    end
    Utilities::puts_close
  end

  def destroy
    puts "FBO:#{@class_name} destroy".red if DEBUGGING
    update({ 'enabled' => 'false' })
  end
end
