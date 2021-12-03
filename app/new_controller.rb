class NewController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  # outlet :mapview, MKMapView
  outlet :gamecode, UILabel
  outlet :character_view, CharacterController
  outlet :cancel_button, UIButton

  outlet :table_team_a, UITableView
  outlet :table_team_b, UITableView
  outlet :tableView, UITableView

  outlet :not_close_enough, UILabel

  DEBUGGING = true

  def viewDidLoad
    puts "NEWCONTROLLER: VIEWDIDLOAD".light_blue

    super
    table_team_a.delegate = self
    # table_team_a.dataSource = something

    Machine.instance.current_view = self

    # get the current player's location
    Machine.instance.initialize_location_manager

    # create a new game in Firebase and retrieve its ID
    # TODO perhaps move this into viewWillAppear?
    # Machine.instance.create_new_game
    Machine.instance.create_new_game.tap do |game|
      puts "New game uuid: #{game.uuID.UUIDString}"
      gamecode.text = game.gamecode
    end

    # Listen for new players
    @player_new_observer = App.notification_center.observe "PlayerNew" do |notification|
      puts "PLAYER NEW".yellow

      puts notification.object.value

      handle_new_player
    end

    Machine.instance.segue("ToCharacter")
  end


  ### TABLE STUFF
  # Useful: https://code.tutsplus.com/tutorials/ios-sdk-crafting-custom-uitableview-cells--mobile-15702
  def tableView(table_view, cellForRowAtIndexPath: index_path)
    puts "NEWCONTROLLER TABLEVIEW CELLFORROW".blue if DEBUGGING

    @reuseIdentifier ||= "PlayerCell"
    cell = tableView.dequeueReusableCellWithIdentifier(@reuseIdentifier)

    puts Machine.instance.game.nga_kapa[0].player_names[index_path.item]

    # How can we tell which table it's from?
    if table_view == @table_team_a
      cell.player_name.text = Machine.instance.game.nga_kapa[0].player_names[index_path.item]
    elsif table_view == @table_team_b
      cell.player_name.text = "Georgina"
    end

    cell
  end
  def tableView(table_view, didDeselectRowAtIndexPath: index_path)
    puts "NEWCONTROLLER TABLEVIEW DIDSELECT".blue if DEBUGGING
  end
  def tableView(table_view, numberOfRowsInSection: section)
    puts "NEWCONTROLLER TABLEVIEW NUMBEROFROWS".blue if DEBUGGING
    return 0 if Machine.instance.game.nga_kapa.empty? # This is a terrible concurrency hack
    return Machine.instance.game.nga_kapa[0].count if table_view == @table_team_a
    return Machine.instance.game.nga_kapa[1].count if table_view == @table_team_b
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

class PlayerCell < UITableViewCell
  extend IB

  outlet :player_name, UILabel
end
