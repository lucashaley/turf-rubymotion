class Player < FirebaseObject
  attr_accessor :is_bot,
                :in_boundary,
                :machine,
                :button_down_location,
                :state_waiting,
                :coordinate_state
  attr_reader :location_update_observer
  
  @location_dirty = false
  
  DEBUGGING = true
  PLACEMENT_DISTANCE_LIMIT = 4
  
  def initialize(in_ref, in_data_hash, in_bot = false)
    @location_update_observer = nil

    # set the current pouwhenua
    in_data_hash.merge!('pouwhenua_current' => in_data_hash['character']['pouwhenua_start'])

    super(in_ref, in_data_hash).tap do |k|
      @is_bot = in_bot
      @in_boundary = true
      k.init_observers unless @is_bot
      
      Notification.center.post 'PlayerNew'
      
      # STATE MACHINE: COORDINATE
      k.coordinate_state = StateMachine::Base.new start_state: :waiting, verbose: DEBUGGING
      k.coordinate_state.when :waiting do |state|
        state.on_entry { puts 'coordinate_state enter waiting'.pink }
        state.on_exit { puts 'coordinate_state exit waiting'.pink }
        state.transition_to :updating, on: :update
      end
      k.coordinate_state.when :updating do |state|
        state.on_entry { puts 'coordinate_state enter updating'.pink }
        state.on_exit { puts 'coordinate_state exit updating'.pink }
        state.transition_to :waiting, 
          on_notification: 'Player_ChildChanged',
          action: proc { recalculate_team }
      end
      # k.coordinate_state.when :recalculating_team do |state|
      #   state.on_entry { puts 'coordinate_state enter recalculating_team'.pink }
      #   state.transition_to :waiting, on: :finished
      # end
      k.coordinate_state.start!

      # STATE MACHINE: PLAYING
      k.machine = StateMachine::Base.new start_state: :in_bounds, verbose: DEBUGGING
      k.machine.when :in_bounds do |state|
        state.on_entry { enter_bounds }
        state.transition_to :out_of_bounds,
                            on: :exit_bounds
      end
      k.machine.when :out_of_bounds do |state|
        state.on_entry { exit_bounds }
        state.transition_to :in_bounds,
                            on: :enter_bounds
        # state.transition_to :ejected,
        #                     after: 3
      end
      k.machine.when :ejected do |state|
        state.on_entry { eject }
      end
      k.machine.start!
    end
    Utilities::puts_close
  end

  def init_observers
    puts "FBO:#{@class_name}:#{__LINE__} init_observers".green if DEBUGGING

    @ref.child('team').observeEventType(
      FIRDataEventTypeChildAdded, withBlock:
      lambda do |_data_snapshot|
        puts "FBO:#{@class_name} TEAM CHANGED".red if DEBUGGING
        mp 'Setting dirty to false'
        @location_dirty = false
      end
    )

    @location_update_observer = Notification.center.observe 'UpdateLocation' do |data|
      puts 'TAKARO UPDATELOCALPLAYERPOSITION LOCATION'.yellow if DEBUGGING

      new_location = data.object['new_location']
      _old_location = data.object['old_location']

      self.coordinate = new_location.to_hash
    end
  end
  
  def coordinate=(in_coordinate)
    puts "FBO:#{@class_name}:#{__LINE__} update_coordinate for #{display_name}".green if DEBUGGING

    # if we're still updating, return
    return if @location_dirty
    
    # check if we're still in the update state
    return if @coordinate_state.current_state.to_s == 'update'

    # We haven't changed, so move on
    return if in_coordinate == coordinate

    # Looks like we're updating, so set state
    @coordinate_state.event(:update)

    # mark as dirty, so we can't do more updates until this cleans
    mp 'New coordinate: Setting location_dirty to true'
    @location_dirty = true

    # update the database if we've moved
    update({ 'coordinate' => in_coordinate })

    # check if we are outside the game field
    # We could use MKMapRectContainsPoint, but we would need to MapView MKMapRect
    # or we can use this algorithm: https://stackoverflow.com/a/23546284
    if Machine.instance.is_playing
      check_taiapa
      check_placing
    end

    # check if we are outside the kapa starting zone
    # recalculate_kapa(in_coordinate) if Machine.instance.is_waiting
  end

  # https://stackoverflow.com/a/23546284
  def check_taiapa
    puts "FBO:#{@class_name}:#{__LINE__} check_taiapa".green if DEBUGGING

    coord = coordinate.to_CLLocationCoordinate2D
    # CLLocationCoordinate2D center = region.center;
    center = Machine.instance.takaro_fbo.taiapa_region.center
    # MKCoordinateSpan span = region.span;
    span = Machine.instance.takaro_fbo.taiapa_region.span

    # BOOL result = YES;
    in_taiapa = true

    radian = Math::PI / 180.0
    # result &= cos((center.latitude - coord.latitude)*M_PI/180.0) > cos(span.latitudeDelta/2.0*M_PI/180.0);
    # in_taiapa &= Math.cos((center.latitude - coord.latitude) * Math::PI / 180) > Math.cos(span.latitudeDelta / 2.0 * Math::PI / 180.0)
    in_taiapa &= Math.cos((center.latitude - coord.latitude) * radian) > Math.cos(span.latitudeDelta / 2 * radian)
    # result &= cos((center.longitude - coord.longitude)*M_PI/180.0) > cos(span.longitudeDelta/2.0*M_PI/180.0);
    in_taiapa &= Math.cos((center.longitude - coord.longitude) * radian) > Math.cos(span.longitudeDelta / 2 * radian)
    # return result;

    puts "in_taiapa: #{in_taiapa}"
    puts "in_boundary: #{@in_boundary}"

    @machine.event(:exit_bounds) if !in_taiapa && @in_boundary
    @machine.event(:enter_bounds) if !@in_boundary && in_taiapa
  end

  def placing(in_bool)
    puts "FBO:#{@class_name}:#{__LINE__} placing".green if DEBUGGING

    @button_down_location = in_bool ? coordinate : nil
  end

  def check_placing
    puts "FBO:#{@class_name}:#{__LINE__} check_placing".green if DEBUGGING

    return if @button_down_location.nil?

    distance = Utilities::get_distance(@button_down_location, coordinate)
    puts "Distance: #{distance}".focus

    return if distance < PLACEMENT_DISTANCE_LIMIT

    puts 'MOVED TOO FAR!!'.focus
    Notification.center.post 'CrossedPlacementLimit'
  end

  # TODO: Couldn't this all be in the .kapa method?
  def recalculate_team(in_coordinate = coordinate)
    puts "FBO:#{@class_name}:#{__LINE__} recalculate_team for #{display_name}".green if DEBUGGING
    new_team = Machine.instance.takaro_fbo.get_team_for_coordinate(in_coordinate)

    if new_team.nil?
      # we did not find any nearby kapa.
      puts 'Too far!'.red

      # if the kaitakaro has a kapa already,
      # it means they have moved away from their kapa
      Team.remove_player_with_key(@ref.key, team['id']) unless team.nil?

      # either way, remove the team from the player
      self.team = nil
    else
      # we did find a kapa!
      # it's the same kapa
      if @data_hash.key?('team') && @data_hash['team']['id'] == new_team.ref.key
        new_team.recalculate_coordinate
        return
      end

      # if there is already a kapa, we need to remove the kaitakaro
      # ahh yes, we must remove it from the _existing_ one, not the new one
      puts "recalculate_team - existing data_hash team: #{@data_hash['team']}"
      # unless @data_hash['kapa'].nil? or @data_hash['kapa'].count == 1
      unless team.nil? or @data_hash['team'].count == 1
        # what if it's the last one? Surely we don't delete it
        Team.remove_player_with_key(@ref.key, team['team_key'])
      end

      # We might be adding it to the new kapa before it leaves the old one
      # perhaps we need to pass a block?

      puts "Adding #{display_name} to team #{new_team}".green

      new_team.add_player(self)
    end
  end

  def exit_bounds
    puts 'Kaitakaro exit_bounds'.pink
    @in_boundary = false
    Notification.center.post 'BoundaryExit'
  end

  def enter_bounds
    puts 'Kaitakaro enter_bounds'.pink
    @in_boundary = true
    Notification.center.post 'BoundaryEnter'
  end

  def eject
    puts 'EJECTED!!!!'.focus
  end

  # Helpers
  def display_name
    @data_hash['display_name']
  end

  def display_name=(in_name)
    update({ 'display_name' => in_name })
  end
  
  def updating?
    @data_hash['updating']
  end
  
  def updating=(in_updating)
    update({ 'updating' => 'true' })
  end

  def name_and_character
    {
      'display_name' => display_name,
      'character' => character['title']
    }
  end

  def data_for_team
    {
      'id' => @ref.key,
      'display_name' => display_name,
      'character' => character['title'],
      'coordinate' => coordinate
    }
  end

  def data_for_pouwhenua
    {
      'key' => @ref.key,
      'coordinate' => coordinate,
      'lifespan_ms' => character['lifespan_ms'],
      'color' => kapa['color'],
      'kapa_key' => kapa['kapa_key'],
      'kaitakaro_key' => key
    }
  end

  def character
    @data_hash['character']
  end

  def character=(in_character)
    update({ 'character' => in_character })
  end

  def kapa
    @data_hash['kapa']
  end

  def kapa=(in_kapa)
    result = in_kapa.nil? ? '' : in_kapa.data_for_kaitakaro
    update({ 'kapa' => result })
  end
  
  def team
    @data_hash['team']
  end
  
  def team=(in_team)
    result = in_team.nil? ? '' : in_team.data_for_player
    update({ 'team' => result })
  end

  def coordinate
    @data_hash['coordinate']
  end

  def deploy_time
    @data_hash['character']['deploy_time']
  end

  def lifespan_ms
    @data_hash['character']['lifespan_ms']
  end

  def pouwhenua_current
    @data_hash['pouwhenua_current']
  end

  def pouwhenua_decrement
    notification = -> { Notification.center.post 'UpdatePouwhenuaLabel' }
    update_with_block({ 'pouwhenua_current' => pouwhenua_current - 1 }, &notification)
  end

  def pouwhenua_increment
    notification = -> { Notification.center.post 'UpdatePouwhenuaLabel' }
    update_with_block({ 'pouwhenua_current' => pouwhenua_current + 1 }, &notification)
  end
end