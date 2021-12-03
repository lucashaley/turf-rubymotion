class CharacterController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  outlet :scout_button, UIButton

  DEBUGGING = true

  def select_scout
    puts "CHARACTERCONTROLLER SELECT_SCOUT".blue if DEBUGGING

    # TODO all this needs to change to the game local player
    # Machine.instance.player.role = "scout"
    # Machine.instance.player.refresh = 5 # in seconds
    # Machine.instance.player.pouwhenua_count = 5
    #
    # puts Machine.instance.player.to_s.red
    # Machine.instance.player.update_all

    dismiss_modal
  end

  def dismiss_modal
    presentingViewController.dismissViewControllerAnimated(true, completion: nil)
  end
end
