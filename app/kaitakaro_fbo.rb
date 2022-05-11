# {
#   character
#   {
#     deploy_time.
#     lifespan_ms,
#     pouwhenua_start,
#     title
#   },
#   coordinate
#   {
#     latitude,
#     longitude
#   },
#   display_name,
#   email,
#   kapa,
#   user_id
# }

class KaitakaroFbo < FirebaseObject
  attr_accessor :is_bot,
                :in_boundary,
                :machine
  attr_reader :location_update_observer

  DEBUGGING = false

  def initialize(in_ref, in_data_hash, in_bot = false)
    @location_update_observer = nil
    super(in_ref, in_data_hash).tap do |k|
      @is_bot = in_bot
      @in_boundary = true
      k.init_observers unless @is_bot
      k.update({ 'display_name' => "mung #{rand(1..10)}" })
      App.notification_center.post 'PlayerNew'

      # STATE MACHINE
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
        state.transition_to :ejected,
                            after: 3
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

    @location_update_observer = App.notification_center.observe 'UpdateLocation' do |data|
      puts 'TAKARO UPDATELOCALPLAYERPOSITION LOCATION'.yellow if DEBUGGING

      new_location = data.object['new_location']
      _old_location = data.object['old_location']

      self.coordinate = new_location.to_hash
    end
  end

  def coordinate=(in_coordinate)
    puts "FBO:#{@class_name}:#{__LINE__} update_coordinate for #{display_name}".green if DEBUGGING

    # We haven't changed, so move on
    return if in_coordinate == coordinate

    # update the database if we've moved
    update({ 'coordinate' => in_coordinate })

    # check if we are outside the game field
    # We could use MKMapRectContainsPoint, but we would need to MapView MKMapRect
    # or we can use this algorithm: https://stackoverflow.com/a/23546284
    if Machine.instance.is_playing
      # check here
      # App.notification_center.post 'BoundaryExit' unless check_taiapa
      check_taiapa
    end

    # check if we are outside the kapa starting zone
    recalculate_kapa(in_coordinate) if Machine.instance.is_waiting
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

    # result &= cos((center.latitude - coord.latitude)*M_PI/180.0) > cos(span.latitudeDelta/2.0*M_PI/180.0);
    in_taiapa &= Math.cos((center.latitude - coord.latitude) * Math::PI / 180) > Math.cos(span.latitudeDelta / 2.0 * Math::PI / 180.0)
    # result &= cos((center.longitude - coord.longitude)*M_PI/180.0) > cos(span.longitudeDelta/2.0*M_PI/180.0);
    in_taiapa &= Math.cos((center.longitude - coord.longitude) * Math::PI / 180) > Math.cos(span.longitudeDelta / 2.0 * Math::PI / 180.0)
    # return result;

    @machine.event(:exit_bounds) if !in_taiapa && @in_boundary
    @machine.event(:enter_bounds) if in_taiapa && !@in_boundary
  end

  # TODO: Couldn't this all be in the .kapa method?
  def recalculate_kapa(in_coordinate = coordinate)
    puts "FBO:#{@class_name}:#{__LINE__} recalculate_kapa for #{display_name}".green if DEBUGGING
    new_kapa = Machine.instance.takaro_fbo.get_kapa_for_coordinate(in_coordinate)

    if new_kapa.nil?
      puts 'Too far!'.red

      # remove from kapa, if it exists
      KapaFbo.remove_kaitakaro_with_key(@ref.key, kapa['id']) unless kapa.nil?

      self.kapa = nil
    else
      if @data_hash.key?('kapa') && @data_hash['kapa']['id'] == new_kapa.ref.key
        new_kapa.recalculate_coordinate
        return
      end

      # if there is already a kapa, we need to remove the kaitakaro
      # ahh yes, we must remove it from the _existing_ one, not the new one
      puts "recalculate_kapa - existing data_hash kapa: #{@data_hash['kapa']}"
      unless @data_hash['kapa'].nil?
        # what if it's the last one? Surely we don't delete it
        KapaFbo.remove_kaitakaro_with_key(@ref.key, kapa['id'])
      end

      # We might be adding it to the new kapa before it leaves the old one
      # perhaps we need to pass a block?

      puts "Adding #{display_name} to kapa #{new_kapa}".green

      new_kapa.add_kaitakaro(self)
    end
  end

  def exit_bounds
    puts 'Kaitakaro exit_bounds'.pink
    @in_boundary = false
    App.notification_center.post 'BoundaryExit'
  end

  def enter_bounds
    puts 'Kaitakaro enter_bounds'.pink
    @in_boundary = true
    App.notification_center.post 'BoundaryEnter'
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

  def name_and_character
    {
      'display_name' => display_name,
      'character' => character['title']
    }
  end

  def data_for_kapa
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
      'kapa_key' => kapa['key']
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

  def coordinate
    @data_hash['coordinate']
  end

  def deploy_time
    @data_hash['character']['deploy_time']
  end

  def lifespan_ms
    @data_hash['character']['lifespan_ms']
  end
end
