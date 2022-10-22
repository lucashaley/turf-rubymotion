class TeamManager
	attr_accessor :teams
	
	def initialize
		mp 'TeamManager initialize'
	end
	
	#####################
	# SINGLETON
	# def self.instance
	# 	Dispatch.once { @instance ||= new }
	# 	@instance
	# end
	
	def add_player_to_team(in_player)
		mp 'TeamManager add_player_to_team'
		mp 'Player:'
		mp in_player
	end
	
	def create_new_team(in_coordinate)
		mp 'TeamManager create_new_team'
	end
	
	def find_nearest_team(coordinates)
		mp 'TeamManager find_nearest_team'
	end
end