class JoinController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  # outlet :mapview, MKMapView
  outlet :gamecode, UITextField
  outlet :character_view, CharacterController
  outlet :cancel_button, UIButton
  outlet :continue_button, UIButton

  DEBUGGING = true

  def viewDidLoad
    puts "JOINCONTROLLER VIEWDIDLOAD".blue if DEBUGGING
    # Do some stuff in here
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
