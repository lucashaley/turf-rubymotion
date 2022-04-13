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
    super.tap do |k|
      k.machine = StateMachine::Base.new start_state: :start, verbose: DEBUGGING
      k.machine.when :start do |state|
        state.on_entry { puts 'Pouwhenua state start'.pink }
        state.transition_to :kapa_death,
                            after: 10,
                            action: proc { puts 'DEATH' }
      end
      k.machine.start!
    end
  end
end
