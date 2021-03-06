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
    @text_change_observer = Notification.center.observe UITextFieldTextDidChangeNotification do |_notification|
      puts 'Text did change'.blue if DEBUGGING
      check_input_text
    end

    puts 'Trying Firebase Object'.red
    TakaroFbo.new(Machine.instance.db.referenceWithPath('tests').childByAutoId, { name: 'tomato' })
  end

  def textFieldShouldEndEditing(text_field)
    puts 'JOINCONTROLLER TEXTFIELDSHOULDENDEDITING'.blue if DEBUGGING
    # this method should return true if editing should stop
    # and false if it should continue

    return true if text_field.text.length == 6

    false
  end

  # rubocop:disable Metrics/AbcSize
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
          lambda do |error, snapshot|
            mp error unless error.nil?

            game_snapshot = snapshot.children.nextObject
            game_hash = game_snapshot.valueInExportFormat

            puts 'OHHH JESUS HERE WE GO'.focus
            Machine.instance.takaro_fbo = TakaroFbo.new(game_snapshot.ref, {})
            mp Machine.instance.takaro_fbo

            continue_button.enabled = true

            # hide the keyboard
            gamecode.resignFirstResponder
          end
        )
    else
      continue_button.enabled = false
    end
  end
  # rubocop:enable Metrics/AbcSize
end
