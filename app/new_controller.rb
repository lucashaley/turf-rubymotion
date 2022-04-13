class NewController < MachineViewController
  
  # outlet :mapview, MKMapView
  outlet :gamecode, UILabel
  outlet :character_view, CharacterController
  outlet :continue_button, UIButton
  outlet :cancel_button, UIButton

  outlet :table_team_a, UITableView
  outlet :table_team_b, UITableView
  TABLEVIEW_TEAM_A = 0
  TABLEVIEW_TEAM_B = 1

  outlet :not_close_enough, UILabel

  # Should this switch to Machine?
  # Maybe only when we exit?
  attr_accessor :takaro,
                :local_character

  DEBUGGING = false
  CELL_IDENTIFIER = "PlayerCell"

  def viewDidLoad
    super
    puts "NEWCONTROLLER: VIEWDIDLOAD".light_blue

    # get the current player's location
    # this should already have happened
    # Machine.instance.initialize_location_manager
    
    # testing the game_options_controller
    # puts "game_duration: #{Machine.instance.game_duration}".blue
    puts "duration: #{Machine.instance.takaro_fbo.duration}".blue

    # @takaro = Takaro.new
    @takaro = Machine.instance.takaro_fbo

    gamecode.text = @takaro.gamecode

    # Listen for new players
    @player_new_observer = App.notification_center.observe "PlayerNew" do |notification|
      puts "PLAYER NEW".yellow
      handle_new_player
    end
    @player_changed_observer = App.notification_center.observe "PlayerChanged" do |notification|
      puts "PLAYER CHANGED".yellow
      handle_changed_player
    end
    
    @kapa_new_observer = App.notification_center.observe "KapaNew" do |notification|
      puts "NEWCONTROLLER NEWKAPA".yellow
      table_team_a.reloadData
      table_team_b.reloadData
    end
    # Listen for gamecode
    @gamecode_new_observer = App.notification_center.observe "GamecodeNew" do |notification|
      puts "GAMECODE NEW".yellow

      gamecode.text = notification.object
    end
    
    # listen for the character selection
    @character_select_observer = App.notification_center.observe "SelectCharacter" do |notification|
      puts "CHARACTER SELECT".yellow
      @takaro.local_kaitakaro.character = notification.data
    end

    # Machine.instance.tracking = true

    # Machine.instance.segue("ToCharacter")
  end


  ### TABLE STUFF
  # Useful: https://code.tutsplus.com/tutorials/ios-sdk-crafting-custom-uitableview-cells--mobile-15702
  def tableView(table_view, cellForRowAtIndexPath: index_path)
    puts "NEWCONTROLLER TABLEVIEW CELLFORROW".blue if DEBUGGING

    cell = table_view.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
    unless cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: CELL_IDENTIFIER)
    end
    
    puts "table_view: #{table_view.inspect}".red
    table = case table_view
      when @table_team_a then TABLEVIEW_TEAM_A
      when @table_team_b then TABLEVIEW_TEAM_B
      else 'poop'
    end
    player = @takaro.list_player_names_for_index(table)[index_path.row]
    puts "PLAYER: #{player.inspect}".yellow
    cell.textLabel.text = player['display_name']
    cell.detailTextLabel.text = player['character']

    cell
  end

  def tableView(table_view, didDeselectRowAtIndexPath: index_path)
    puts "NEWCONTROLLER TABLEVIEW DIDSELECT".blue if DEBUGGING
  end

  def tableView(table_view, numberOfRowsInSection: section)
    puts "NEWCONTROLLER TABLEVIEW NUMBEROFROWS".blue if DEBUGGING
    return 0 unless @takaro
    if table_view == table_team_a
      # puts "NumberOfRows rows a: #{@takaro.player_count_for_index(TABLEVIEW_TEAM_A)}"
      return @takaro.player_count_for_index(TABLEVIEW_TEAM_A)
    elsif table_view == table_team_b
      # puts "NumberOfRows rows b: #{@takaro.player_count_for_index(TABLEVIEW_TEAM_B)}"
      return @takaro.player_count_for_index(TABLEVIEW_TEAM_B)
    end
    0
  end

  def handle_new_player
    puts "NEWCONTROLLER HANDLE_NEW_PLAYER".blue if DEBUGGING
    # TODO this is a hack
    table_team_a.reloadData
    table_team_b.reloadData
  end
  
  def handle_changed_player
    puts "NEWCONTROLLER HANDLE_CHANGED_PLAYER".blue if DEBUGGING
    # TODO this is a hack
    table_team_a.reloadData
    table_team_b.reloadData
  end

  def cancel_new_game
    puts "NewController: cancel_new_game"

    # self.presentingViewController.dismissViewControllerAnimated(true, completion:nil)
  end

  # https://stackoverflow.com/questions/16668436/how-to-send-in-app-sms-using-rubymotion
  def compose_sms
    puts "compose_sms"
    MFMessageComposeViewController.alloc.init.tap do |sms|
      sms.messageComposeDelegate = self
      sms.recipients = ["+6420410908922", "+15037361234"]
      sms.body = "You've been invited to a game of Turf. The game code is #{@gamecode.text}. Open your Turf app on your device and select 'Join Game'."
      presentModalViewController(sms, animated: true)
    end if MFMessageComposeViewController.canSendText
  end

  def messageComposeViewController(controller, didFinishWithResult: result)
    puts "didFinishWithResult"
    NSLog("SMS Result: #{result}")
    controller.dismissModalViewControllerAnimated(true)
  end

  def continue_button_action sender
    puts "NEWCONTROLLER CONTINUE_BUTTON_ACTION".light_blue if DEBUGGING
    puts "Continuing to game".focus
    # make the first two pouwhenua
    # set the machine takaro
    Machine.instance.takaro = @takaro
    puts "#{@takaro}".focus

    @takaro.set_initial_pouwhenua
  end

  def dismiss_new
    Machine.instance.segue("ToMenu")
  end

  def add_bot_action sender
    puts "NEWCONTROLLER ADD_BOT_ACTION".light_blue
    @takaro.create_bot_player
  end
end
