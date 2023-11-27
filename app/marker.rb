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

class Marker < FirebaseObject
  attr_accessor :machine

  def initialize(in_ref, in_data_hash)
	  mp __method__

	  in_data_hash.merge!('enabled' => 'true')
	  super.tap do |p|
		  p.machine = StateMachine::Base.new start_state: :start, verbose: DEBUGGING
		  p.machine.when :start do |state|
		    state.on_entry { mp 'Marker state start' }
        state.transition_to :death,
          after: in_data_hash['lifespan'],
          on: :pants
		  end
		  p.machine.when :death do |state|
			  state.on_entry { destroy }
		  end
		  p.machine.start!
    end
    Utilities::puts_close
  end

  def initialize_firebase_observers
		mp __method__

		# Teams
		@ref.child('active').observeEventType(
			FIRDataEventTypeChildChanged, withBlock:
			lambda do |marker_snapshot|
				mp "marker snapshot"
			end.weak!
		)
	end

  def destroy
  	mp __method__
			# Machine.instance.takaro_fbo.local_kaitakaro.pouwhenua_increment
			Machine.instance.takaro_fbo.local_player.marker_increment
			# notification = -> { Notification.center.post 'MapRefresh' }
			notification = lambda do
					Machine.instance.takaro_fbo.pouwhenua_is_dirty = true
					Notification.center.post 'MapRefresh'
			end.weak!
			update_with_block({ 'enabled' => 'false' }, &notification)
  end
end
