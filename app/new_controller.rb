class NewController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  # outlet :mapview, MKMapView
  outlet :gamecode, UILabel
  outlet :character_view, CharacterController
  outlet :cancel_button, UIButton

  outlet :table_team_a, UITableView
  outlet :table_team_b, UITableView
  TABLEVIEW_TEAM_A = 0
  TABLEVIEW_TEAM_B = 1

  outlet :not_close_enough, UILabel

  attr_accessor :takaro

  DEBUGGING = false
  CELL_IDENTIFIER = "PlayerCell"

  def viewDidLoad
    puts "NEWCONTROLLER: VIEWDIDLOAD".light_blue

    Machine.instance.current_view = self
    # get the current player's location
    Machine.instance.initialize_location_manager

    # # Old version
    # # create a new game in Firebase and retrieve its ID
    # # TODO perhaps move this into viewWillAppear?
    # # Machine.instance.create_new_game
    # Machine.instance.create_new_game.tap do |game|
    #   puts "Created new game: #{game.uuid_string}".pink
    #   gamecode.text = game.gamecode
    # end

    @takaro = Takaro.new

    # Listen for new players
    @player_new_observer = App.notification_center.observe "PlayerNew" do |notification|
      puts "PLAYER NEW".yellow

      # puts notification.object.value unless notification.object.value.nil?

      handle_new_player
    end
    @kapa_new_observer = App.notification_center.observe "KapaNew" do |notification|
      puts "NEWCONTROLLER NEWKAPA".yellow
      table_team_a.reloadData
      table_team_b.reloadData
    end

    Machine.instance.tracking = true

    Machine.instance.segue("ToCharacter")
  end


  ### TABLE STUFF
  # Useful: https://code.tutsplus.com/tutorials/ios-sdk-crafting-custom-uitableview-cells--mobile-15702
  def tableView(table_view, cellForRowAtIndexPath: index_path)
    puts "NEWCONTROLLER TABLEVIEW CELLFORROW".blue if DEBUGGING

    cell = table_view.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
    unless cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: CELL_IDENTIFIER)
    end

    # How can we tell which table it's from?
    if table_view == @table_team_a
      cell.textLabel.text = @takaro.list_player_names_for_index(TABLEVIEW_TEAM_A)[index_path.row]
    elsif table_view == @table_team_b
      cell.textLabel.text = @takaro.list_player_names_for_index(TABLEVIEW_TEAM_B)[index_path.row]
    end

    # This will eventually be their character role
    cell.detailTextLabel.text = "Mung beans"

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
      sms.body = "You've been invited to a game of Turf. The game code is #{@new_id}. Open your Turf app on your device and select 'Join Game'."
      presentModalViewController(sms, animated: true)
    end if MFMessageComposeViewController.canSendText
  end

  def messageComposeViewController(controller, didFinishWithResult: result)
    puts "didFinishWithResult"
    NSLog("SMS Result: #{result}")
    controller.dismissModalViewControllerAnimated(true)
  end

  def dismiss_new
    Machine.instance.segue("ToMenu")
  end
end
