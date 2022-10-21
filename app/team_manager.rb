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
	
	def find_nearest_team(coordinates)
		mp 'TeamManager find_nearest_team'
	end
end