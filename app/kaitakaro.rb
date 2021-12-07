class Kaitarako
  def initialize(game_ref, args = {})
    @ref = game_ref.child("players").childByAutoId
    @ref.updateChildValues({
      user_id: args[:user_id] || "ABC123",
      display_name: args[:given_name] || "Hemi",
      location: args[:location] || CLLocationCoordinate2DMake(37.33189332651307, -122.03128724123847).to_firebase
    })
  end

  def location_coordinates=(in_location_coordinates)
    puts "KAITAKARO SET LOCATION_COORDINATES".blue if DEBUGGING
    new_location_coords = {}
    case in_location_coordinates
    when Hash
      new_location_coords = in_location_coordinates
    when CLLocationCoordinate2D
      new_location_coords = {
        "latitude" => in_location_coordinates.latitude,
        "longitude" => in_location_coordinates.longitude
      }
    else
      new_location_coords = {"latitude" => 0, "longitude" => 0}
    end
    @ref.updateChildValues({location: new_location_coords})
  end
end
