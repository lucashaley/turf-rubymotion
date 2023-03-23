class NewController < MachineViewController
  outlet :gamecode, UILabel
  outlet :character_view, CharacterController
  outlet :continue_button, UIButton
  outlet :button_continue, UIButton
  outlet :cancel_button, UIButton
  outlet :button_pylon, UIButton

  outlet :table_team_a, UITableView
  outlet :table_team_b, UITableView
  TABLEVIEW_TEAM_A = 0
  TABLEVIEW_TEAM_B = 1

  outlet :not_close_enough, UILabel

  # Should this switch to Machine?
  # Maybe only when we exit?
  attr_accessor :takaro,
                :local_character

  DEBUGGING = true
  CELL_IDENTIFIER = 'PlayerCell'.freeze

  def viewDidLoad
    super
    mp __method__
    # mp 'NEWCONTROLLER: VIEWDIDLOAD'.light_blue

    init_observers

    # Machine.instance.is_waiting = true

    # @takaro = Machine.instance.takaro_fbo
    # @takaro.update({ 'is_waiting' => 'true' })

    # gamecode.text = @takaro.gamecode
    gamecode.text = machine.takaro_fbo.gamecode

    # this is now handled in the Machine
    # @takaro.initialize_local_player(Machine.instance.local_character)

    Notification.center.post('game_state_waiting_room_notification', nil)
  end

  def viewWillAppear(_animated)
    mp __method__
    # continue_button.enabled = @takaro.host
    continue_button.enabled = machine.takaro_fbo.host
  end

  def init_observers
    mp __method__
    Notification.center.addObserver(self,
                                    selector: 'handle_new_player',
                                    name: 'PlayerNew',
                                    object: nil)

    Notification.center.addObserver(self,
                                    selector: 'handle_changed_player',
                                    name: 'player_changed',
                                    object: nil)

    Notification.center.addObserver(self,
                                    selector: 'reload_table_data',
                                    name: 'KapaNew',
                                    object: nil)

    Notification.center.addObserver(self,
                                    selector: 'reload_table_data',
                                    name: 'KapaDelete',
                                    object: nil)

    Notification.center.addObserver(self,
                                    selector: 'reload_table_data',
                                    name: 'Kapafbo_New',
                                    object: nil)

    Notification.center.addObserver(self,
                                    selector: 'reload_table_data',
                                    name: 'Kapafbo_ChildRemoved',
                                    object: nil)

    Notification.center.addObserver(self,
                                    selector: 'reload_table_data',
                                    name: 'Kapafbo_ChildAdded',
                                    object: nil)

    Notification.center.addObserver(self,
                                    selector: 'reload_table_data',
                                    name: 'Kapafbo_ChildChanged',
                                    object: nil)

    Notification.center.addObserver(self,
                                    selector: 'reload_table_data',
                                    name: 'teams_changed',
                                    object: nil)

    # Listen for gamecode
    @gamecode_new_observer = Notification.center.observe 'GamecodeNew' do |notification|
      mp 'new_controller: NEW'.yellow

      gamecode.text = notification.object
    end

    # listen for the character selection
    # do we still want this like this?
    # Because it's also done through Machine.local_character and initialize_local_character
    # @character_select_observer = Notification.center.observe 'SelectCharacter' do |notification|
    #   mp 'CHARACTER SELECT'.yellow
    #   # @takaro.local_kaitakaro.character = notification.data
    #   @takaro.local_player.character = notification.data
    # end
  end

  ### TABLE STUFF
  # Useful: https://code.tutsplus.com/tutorials/ios-sdk-crafting-custom-uitableview-cells--mobile-15702
  def tableView(table_view, cellForRowAtIndexPath: index_path)
    begin
      mp 'NEWCONTROLLER TABLEVIEW CELLFORROW'.blue if DEBUGGING
      mp __method__

      cell = table_view.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
      # unless cell
      #   cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: CELL_IDENTIFIER)
      # end
      cell ||= UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: CELL_IDENTIFIER)

      table = case table_view
              when @table_team_a then TABLEVIEW_TEAM_A
              when @table_team_b then TABLEVIEW_TEAM_B
              else 'poop'
              end
      puts "table: #{table}; row: #{index_path.row}"

      # player = @takaro.list_player_names_for_index(table)[index_path.row]
      player = machine.takaro_fbo.list_player_names_for_index(table)[index_path.row]


      puts '⌞'
      puts 'player:'.red
      mp player
      puts '⌜'

      cell.textLabel.text = player['display_name']
      cell.detailTextLabel.text = player['character']

      cell
    rescue Exception => exception
      Bugsnag.notify(exception)
    end
  end

  # def tableView(table_view, didDeselectRowAtIndexPath: index_path)
  #   puts 'NEWCONTROLLER TABLEVIEW DIDSELECT'.blue if DEBUGGING
  # end

  def tableView(table_view, numberOfRowsInSection: _section)
    puts 'NEWCONTROLLER TABLEVIEW NUMBEROFROWS'.blue if DEBUGGING
    # return 0 unless @takaro
    return 0 unless machine.takaro_fbo

    table = case table_view
            when @table_team_a then TABLEVIEW_TEAM_A
            when @table_team_b then TABLEVIEW_TEAM_B
            else 'poop'
            end
    # count = @takaro.player_count_for_index(table)
    count = machine.takaro_fbo.player_count_for_index(table)
    mp "tableView count: #{count}"
    count
  end

  def reload_table_data
    table_team_a.reloadData
    table_team_b.reloadData
  end

  def handle_new_player
    puts 'NEWCONTROLLER HANDLE_NEW_PLAYER'.blue if DEBUGGING
    reload_table_data
  end

  def handle_changed_player
    puts 'NEWCONTROLLER HANDLE_CHANGED_PLAYER'.blue if DEBUGGING
    reload_table_data
  end

  def cancel_new_game
    mp __method__

    # @takaro = nil
    # machine.takaro_fbo = nil
    # Machine.instance.takaro_fbo = nil
    # Machine.instance.segue('ToMenu')

    app_machine.event(:app_waiting_room_to_main_menu)
  end

  # https://stackoverflow.com/questions/16668436/how-to-send-in-app-sms-using-rubymotion
  def compose_sms
    puts 'compose_sms'

    return unless MFMessageComposeViewController.canSendText

    MFMessageComposeViewController.alloc.init.tap do |sms|
      sms.messageComposeDelegate = self
      sms.body = "You've been invited to a game of Turf. "
      sms.body += "The game code is #{@gamecode.text}. "
      sms.body += 'Open your Turf app on your device and select Join Game.'
      presentModalViewController(sms, animated: true)
      # end if MFMessageComposeViewController.canSendText
    end
  end

  def messageComposeViewController(controller, didFinishWithResult: result)
    puts "didFinishWithResult: #{result}"
    NSLog("SMS Result: #{result}")
    controller.dismissModalViewControllerAnimated(true)
  end

  def continue_button_action(_sender)
    mp __method__
    # puts 'NEWCONTROLLER CONTINUE_BUTTON_ACTION'.light_blue if DEBUGGING
    # puts 'Continuing to game'.focus
    # make the first two pouwhenua

    # set the machine takaro
    # Machine.instance.takaro_fbo = @takaro # what is this doing 

    # @takaro.set_initial_pouwhenua
    # @takaro.set_initial_markers

    app_machine.event(:app_waiting_room_to_game)
  end

  # def dismiss_new
  #   @takaro = nil
  #   Machine.instance.takaro_fbo = nil
  #   Machine.instance.segue('ToMenu')
  # end

  def add_bot_action(_sender)
    puts 'NEWCONTROLLER ADD_BOT_ACTION'.light_blue
    # @takaro.create_bot_player
    machine.game.create_bot_player
  end
end
