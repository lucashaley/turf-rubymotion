class JoinExistingController < MachineViewController
  outlet :gamecode_label, UITextField
  outlet :continue_button, UIButton
  outlet :cancel_button, UIButton

  DEBUGGING = true

  def viewDidLoad
    super
    
    # get the current player's location
    mp 'ask machine to initialize location'
    machine.initialize_location_manager
    
    Notification.center.post('app_state_join_view', nil)
  end

  def viewWillAppear(animated)
    super
    mp __method__

    # this shows the keyboard
    gamecode_label.becomeFirstResponder

    # This checks for input in the gamecode input field
    @text_change_observer = Notification.center.observe UITextFieldTextDidChangeNotification do |_notification|
      check_input_text
    end

    Notification.center.post('game_state_join_notification', nil)
  end

  def textFieldShouldEndEditing(text_field)
    mp __method__
    
    # this method should return true if editing should stop
    # and false if it should continue

    return true if text_field.text.length == 6

    false
  end

  # rubocop:disable Metrics/AbcSize
  def check_input_text
    mp __method__

    puts "Length: #{gamecode_label.text.length}".red if DEBUGGING

    if gamecode_label.text.length == 6
      # TODO: This should probably be threaded

      # this should also check for game_status waiting_room
      Machine.instance.db.referenceWithPath('games')
             .queryOrderedByChild('gamecode')
             .queryEqualToValue(gamecode.text)
             .queryLimitedToLast(1)
             .getDataWithCompletionBlock(
          lambda do |error, snapshot|
            mp error unless error.nil?
            Bugsnag.notifyError(error) unless error.nil?

            # Utilities::breadcrumb(snapshot.nil?)

            mp snapshot.childrenCount
            return if snapshot.nil?

            begin
              game_snapshot = snapshot.children.nextObject
              game_hash = game_snapshot.valueInExportFormat

              mp 'getting existing game'
              current_game = TakaroFbo.new(game_snapshot.ref, {})
              mp current_game

              continue_button.enabled = true

              # hide the keyboard
              gamecode_label.resignFirstResponder
            rescue Exception => e
              Utilities::breadcrumb('joining didnt work')
              Bugsnag.notify(e)
            end
          end
        )
    else
      continue_button.enabled = false
    end
  end
  # rubocop:enable Metrics/AbcSize

  def cancel_new_game
    puts 'JoinController: cancel_new_game'
    @takaro = nil
    current_game = nil
    Machine.instance.segue('ToMenu')
  end
end
