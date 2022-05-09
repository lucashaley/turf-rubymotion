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
        state.transition_to :death,
                            after: in_data_hash['lifespan_ms'] / 1000
      end
      k.machine.when :death do |state|
        state.on_entry { destroy }
      end
      k.machine.start!
    end
    Utilities::puts_close
  end

  def destroy
    puts "FBO:#{@class_name} destroy".red if DEBUGGING
    update_with_block({ 'enabled' => 'false' }, Proc.new { App.notification_center.post 'MapRefresh' })
  end
end
