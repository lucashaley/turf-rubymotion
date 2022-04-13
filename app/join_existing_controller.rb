class JoinExistingController < MachineViewController
  outlet :gamecode, UITextField
  outlet :continue_button, UIButton

  DEBUGGING = true

  def viewWillAppear(animated)
    super
    puts 'JOINCONTROLLER VIEWWILLAPPEAR'.blue if DEBUGGING

    # get the current player's location
    puts 'Location?'.red
    Machine.instance.initialize_location_manager

    # This checks for input in the gamecode input field
    @text_change_observer = App.notification_center.observe UITextFieldTextDidChangeNotification do |_notification|
      puts 'Text did change'.blue if DEBUGGING
      check_input_text
    end

    puts 'Trying Firebase Object'.red
    test_fbo = TakaroFbo.new(Machine.instance.db.referenceWithPath('tests').childByAutoId, { name: 'tomato' })
  end

  def textFieldShouldEndEditing(text_field)
    puts 'JOINCONTROLLER TEXTFIELDSHOULDENDEDITING'.blue if DEBUGGING
    # this method should return true if editing should stop
    # and false if it should continue

    return true if text_field.text.length == 6

    false
  end

  def check_input_text
    puts 'JOINCONTROLLER CHECK_INPUT_TEXT'.blue if DEBUGGING

    puts "Length: #{gamecode.text.length}".red if DEBUGGING

    if gamecode.text.length == 6
      # TODO: This should probably be threaded

      Machine.instance.db.referenceWithPath('games')
             .queryOrderedByChild('gamecode')
             .queryEqualToValue(gamecode.text)
             .queryLimitedToLast(1)
             .getDataWithCompletionBlock(
          lambda do |_error, snapshot|
            game_snapshot = snapshot.children.nextObject
            puts "game_snapshot: #{game_snapshot.valueInExportFormat.inspect}".focus

            # Machine.instance.takaro = Takaro.new(snapshot.children.nextObject.key)
            Machine.instance.gamecode = gamecode.text
            continue_button.enabled = true

            # can we get all the players?
            if game_snapshot.hasChild('players')
              player_hash = game_snapshot.childSnapshotForPath('players').valueInExportFormat
              player_names = player_hash.values.map { |p| p['display_name'] }
              puts "player_names: #{player_names}".red
              # oh yeah this worked
            end
          end
        )
      #
      # if Machine.instance.check_for_game(gamecode.text)
      #   continue_button.enabled = true
      # end
    else
      continue_button.enabled = false
    end
  end
end
