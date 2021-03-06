class JoinController < MachineViewController
  
  # outlet :mapview, MKMapView
  outlet :gamecode, UITextField
  outlet :character_view, CharacterController
  outlet :cancel_button, UIButton
  outlet :continue_button, UIButton

  outlet :table_team_a, UITableView
  outlet :table_team_b, UITableView
  TABLEVIEW_TEAM_A = 0
  TABLEVIEW_TEAM_B = 1

  outlet :not_close_enough, UILabel

  attr_accessor :takaro,
                :local_character

  DEBUGGING = true
  CELL_IDENTIFIER = "PlayerCell"

  def viewDidLoad
    super
    puts "JOINCONTROLLER VIEWDIDLOAD".light_blue if DEBUGGING

    # get the current player's location
    Machine.instance.initialize_location_manager
    
    # We can't do this yet, as we need to create it from the existing server version
    # @takaro = Takaro.new

    # Listen for new players
    @player_new_observer = Notification.center.observe "PlayerNew" do |notification|
      puts "PLAYER NEW".yellow

      puts notification.object.value unless notification.object.nil?

      handle_new_player
    end
    @kapa_new_observer = Notification.center.observe "KapaNew" do |notification|
      puts "KAPANEW".light_blue
      self.reload_data
    end

    Machine.instance.tracking = true

    Machine.instance.segue("ToCharacter")
  end

  def viewWillAppear animated
    puts "JOINCONTROLLER VIEWWILLAPPEAR".blue if DEBUGGING

    @text_change_observer = Notification.center.observe UITextFieldTextDidChangeNotification do |notification|
      puts "Text did change".blue if DEBUGGING
      check_input_text
    end
  end

  def tableView(table_view, cellForRowAtIndexPath: index_path)
    puts "JOINCONTROLLER TABLEVIEW CELLFORROW".blue if DEBUGGING

    cell = table_view.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
    unless cell
      cell = UITableViewCell.alloc.initWithStyle(UITableViewCellStyleSubtitle, reuseIdentifier: CELL_IDENTIFIER)
    end

    # How can we tell which table it's from?
    if table_view == table_team_a
      cell.textLabel.text = @takaro.list_player_names_for_index(TABLEVIEW_TEAM_A)[index_path.row]
    elsif table_view == table_team_b
      cell.textLabel.text = @takaro.list_player_names_for_index(TABLEVIEW_TEAM_B)[index_path.row]
    end
    cell.detailTextLabel.text = "Mung beans"

    cell
  end

  def tableView(table_view, didDeselectRowAtIndexPath: index_path)
    puts "JOINCONTROLLER TABLEVIEW DIDSELECT".blue if DEBUGGING
  end

  def tableView(table_view, numberOfRowsInSection: section)
    puts "JOINCONTROLLER TABLEVIEW NUMBEROFROWS".blue if DEBUGGING
    return 0 unless @takaro
    if table_view == table_team_a
      puts "NumberOfRows rows a: #{@takaro.player_count_for_index(TABLEVIEW_TEAM_A)}"
      return @takaro.player_count_for_index(TABLEVIEW_TEAM_A)
    elsif table_view == table_team_b
      puts "NumberOfRows rows b: #{@takaro.player_count_for_index(TABLEVIEW_TEAM_B)}"
      return @takaro.player_count_for_index(TABLEVIEW_TEAM_B)
    end
    0
  end

  def reload_data
    puts "JOINCONTROLLER REOAD_DATA".blue if DEBUGGING
    table_team_a.reloadData
    table_team_b.reloadData
  end

  def handle_new_player
    puts "JOINCONTROLLER HANDLE_NEW_PLAYER".blue if DEBUGGING
    # TODO this is a hack
    reload_data
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

      Machine.instance.db.referenceWithPath("games")
        .queryOrderedByChild("gamecode")
        .queryEqualToValue(gamecode.text)
        .queryLimitedToLast(1)
        .getDataWithCompletionBlock(
          lambda do | error, snapshot |
            # create the takaro
            puts "snapshot: #{snapshot.value}".focus
            @takaro = Takaro.new(snapshot.children.nextObject.key)
            @takaro.local_kaitakaro.character = local_character
          end
        )
      #
      # if Machine.instance.check_for_game(gamecode.text)
      #   continue_button.enabled = true
      # end
    end
  end
end
