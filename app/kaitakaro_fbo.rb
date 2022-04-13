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
#   team,
#   user_id
# }

class KaitakaroFbo < FirebaseObject
  extend Utilities

  attr_reader :location_update_observer

  def initialize(in_ref, in_data_hash)
    @location_update_observer = nil
    super.tap do |k|
      k.init_observers
    end
  end

  def init_observers
    puts "FBO:#{@class_name}:#{__LINE__} init_observers".green if DEBUGGING
    @location_update_observer = App.notification_center.observe 'UpdateLocation' do |data|
      puts 'TAKARO UPDATELOCALPLAYERPOSITION LOCATION'.yellow if DEBUGGING

      new_location = data.object['new_location']
      _old_location = data.object['old_location']

      update_coordinate(new_location.to_hash)
    end
  end

  def update_coordinate(coordinate)
    puts "FBO:#{@class_name}:#{__LINE__} update_coordinate".green if DEBUGGING

    # update the database
    update({ 'coordinate' => coordinate })

    # check if we are outside the game field
    # We could use MKMapRectContainsPoint, but we would need to MapView MKMapRect
    # or we can use this algorithm: https://stackoverflow.com/a/23546284
    if Machine.instance.is_playing
      # check here
    end

    # check if we are outside the kapa starting zone
    if Machine.instance.is_waiting
      # check here
    end
  end
end
