class GameOptionsController < MachineViewController
  def viewDidLoad
    super

    # get the current player's location
    puts 'Location?'.red
    Machine.instance.initialize_location_manager

    @takaro_fbo = TakaroFbo.new(
      Machine.instance.db.referenceWithPath('games').childByAutoId,
      { 'gamecode' => rand(36**6).to_s(36) }
    )
    Machine.instance.takaro_fbo = @takaro_fbo
  end

  def select_duration(sender)
    puts 'GAMEOPTIONSCONTROLLER: select_duration'.blue
    puts "sender: #{sender.inspect}".yellow

    # TODO: this should probably just be set on continue
    case sender.selectedSegmentIndex
    when 0
      @takaro_fbo.duration = 5.0
      Machine.instance.game_duration = 5.0
    when 1
      @takaro_fbo.duration = 10.0
      Machine.instance.game_duration = 10.0
    when 2
      @takaro_fbo.duration = 20.0
      Machine.instance.game_duration = 20.0
    end
  end
end
