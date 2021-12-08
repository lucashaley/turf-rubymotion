class JoinController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  # outlet :mapview, MKMapView
  outlet :gamecode, UITextField
  outlet :character_view, CharacterController
  outlet :cancel_button, UIButton
  outlet :continue_button, UIButton

  outlet :table_team_a, UITableView
  outlet :table_team_b, UITableView
  outlet :tableView, UITableView

  outlet :not_close_enough, UILabel

  DEBUGGING = true

  def viewDidLoad
    puts "JOINCONTROLLER VIEWDIDLOAD".light_blue if DEBUGGING
    # Do some stuff in here

    # super
    table_team_a.delegate = self
    # table_team_a.dataSource = something

    Machine.instance.current_view = self

    # get the current player's location
    Machine.instance.initialize_location_manager

    # Listen for new players
    @player_new_observer = App.notification_center.observe "PlayerNew" do |notification|
      puts "PLAYER NEW".yellow

      puts notification.object.value

      handle_new_player
    end

    Machine.instance.tracking = true

    # Trying out Takaro
    puts "Trying takaro"
    takaro = Takaro.new("9C29270C-4BD3-4297-92E5-66A1E2701111")
    puts "Takaro: #{takaro}"

    puts "Adding local player"
    @local_Player = takaro.add_local_player
    puts "local_player: #{@local_player}"
    takaro.start_syncing

    # takaro.list_player_names_for_team(0)

    Machine.instance.segue("ToCharacter")

    # Machine.instance.tracking = true
  end

  def viewWillAppear animated
    @text_change_observer = App.notification_center.observe UITextFieldTextDidChangeNotification do |notification|
      puts "Text did change".blue if DEBUGGING

      check_input_text
    end
  end

  def cancel_new_game sender
    puts "NewController: cancel_new_game"

    # self.presentingViewController.dismissViewControllerAnimated(true, completion:nil)
  end

  def dismiss_join sender
    Machine.instance.segue("ToMenu")
  end

  ### UITextFieldDelegate responders ###
  def textFieldDidBeginEditing text_field
    puts "JOINCONTROLLER TEXTFIELDDIDBEGINEDITING".blue if DEBUGGING
  end

  def textFieldShouldEndEditing text_field
    puts "JOINCONTROLLER TEXTFIELDSHOULDENDEDITING".blue if DEBUGGING
    # this method should return true if editing should stop
    # and false if it should continue

    return true if text_field.text.length == 6
    false
  end

  def check_input_text
    puts "JOINCONTROLLER CHECK_INPUT_TEXT".blue if DEBUGGING

    puts "Length: #{gamecode.text.length}".red if DEBUGGING

    if gamecode.text.length == 6
      # TODO: This should probably be threaded
      if Machine.instance.check_for_game(gamecode.text)
        continue_button.enabled = true
      end
    end
  end
end
