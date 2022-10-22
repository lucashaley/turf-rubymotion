# {
#   color,
#   coordinate
#   {
#     latitude,
#     longitude
#   },
#   created,
#   kaitakaro
#   {
#
#   }
# }

class Team < FirebaseObject
  attr_reader :players

  DEBUGGING = true

  def initialize(in_ref, in_data_hash)
	puts "FBO:#{@class_name}:#{__LINE__} initialize".green if DEBUGGING
	@team_distance = 50
	@players = []
	
	super.tap do
	  # Notification.center.post 'Kapafbo_New'
	  Notification.center.post 'Team_New'
	end
	Utilities::puts_close
  end

  # def add_kaitakaro(in_kaitakaro)
  def add_player(in_player)
	puts "FBO:#{@class_name}:#{__LINE__} add_player".green if DEBUGGING

	in_player.team = self

	@players << in_player

	update({ 'players' => players_hash })

	Notification.center.post 'PlayerAdded'
	recalculate_coordinate
  end

  # TODO: Check if it's the last kaitakaro, and delete kapa if so
  # do we also need to delete the object too?
  # def remove_kaitakaro(in_kaitakaro)
  def remove_player(in_player)
	puts 'Removing player from team'.red
	puts "To remove: #{in_player.inspect}"
	puts "To remove: #{@players.inspect}"

	@players.delete_if { |p| p.key == in_player }
	puts "Array after delete: #{@players}".yellow
	puts "hash after delete: #{players_hash}".yellow
	update({ 'players' => players_hash })
	
	# This seems really messy
	# and should probably be handled by the TeamManager
	# TODO move to TeamManager
	mp 'THIS IS MESSY'
	delete if @data_hash['players'].empty?
	Machine.instance.takaro_fbo.remove_kapa(@ref) if @data_hash['players'].empty?

	mp 'Team remove_player result: ' & @data_hash['players'].empty?
  end

  def self.remove_player_with_key(in_player, in_key)
	puts "FBO:#{@class_name}:#{__LINE__} remove_player_with_key".red
	mp 'Removing player: ' & in_player
	mp 'Removing player key: ' & in_key

	# first, find the Kapa
	k = Machine.instance.takaro_fbo.kapa_with_key(in_key)

	# then remove the kaitakaro
	k.remove_player(in_player)
  end

  def empty?
	@players.empty?
  end

  def check_distance(in_coordinate)
	get_distance(coordinate, in_coordinate) < @team_distance
  end

  def recalculate_coordinate
	puts 'Recaluclating coordinate'.red
	lat = 0
	long = 0
	@players.each do |player|
	  coordinate = player.coordinate

	  lat += coordinate['latitude'].to_f
	  long += coordinate['longitude'].to_f
	end
	lat /= @players.count
	long /= @players.count
	self.coordinate = { 'latitude' => lat, 'longitude' => long }

	# TODO: Do we need to update all the kaitakaro?
	# TODO: This can probably be a method, to check for existing
	@players.each { |player| player.team = self }
  end

  def list_display_names_and_classes
	puts "FBO:#{@class_name} list_display_names_and_classes".blue if DEBUGGING
	return if @players.empty?

	@players.map(&:name_and_character)
  end

  # Helpers
  # Is this used?
  # def players
	# @data_hash['players']
  # end

  def players_hash
	# TODO: make a Kaitarako method to spit out hash version?
	# @kaitakaro_array.to_h { |k| [k.key, k.data_for_kapa] }
	h = {}
	@players.each do |player|
	  h[player.key] = player.data_for_team
	end
	h
  end

  def color
	@data_hash['color']
  end

  def color=(in_color)
	update({ 'color' => in_color })
  end

  def coordinate
	@data_hash['coordinate']
  end

  def coordinate=(in_coordinate)
	update({ 'coordinate' => in_coordinate })
  end

  def data_for_team
	{
	  'team_key' => @ref.key,
	  'color' => color,
	  'coordinate' => coordinate
	}
  end

  def data_for_pouwhenua
	{
	  'kapa_key' => key,
	  'color' => color,
	  'coordinate' => coordinate
	}
  end

  # Utilities, why is this not being pulled in
  def get_distance(coord_a, coord_b)
	MKMetersBetweenMapPoints(
	  MKMapPointForCoordinate(
		format_to_location_coord(coord_a)
	  ),
	  MKMapPointForCoordinate(
		format_to_location_coord(coord_b)
	  )
	)
  end

  def format_to_location_coord(input)
	case input
	when Hash
	  h = recursive_symbolize_keys(input)
	  return CLLocationCoordinate2DMake(h[:latitude], h[:longitude])
	when CLLocationCoordinate2D
	  return input
	end
	0
  end

  def recursive_symbolize_keys(hsh)
	case hsh
	when Hash
	  Hash[
		hsh.map do |k, v|
		  [k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v)]
		end
	  ]
	when Enumerable
	  hsh.map { |v| recursive_symbolize_keys(v) }
	else
	  hsh
	end
  end
end
