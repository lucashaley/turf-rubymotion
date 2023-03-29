# this can be moved into Unused

class CharacterController < UIViewController
  extend IB

  attr_accessor :player_classes

  outlet :scout_button, UIButton

  DEBUGGING = true

  def viewDidLoad
    puts 'CHARACTERCONTROLLER VIEWDIDLOAD'.blue if DEBUGGING
    @player_classes = {
      'scout' => {
        'deploy_time' => 4,
        # "lifespan_ms" => 2 * 60 * 1000,
        'lifespan' => 4 * 1000,
        'pouwhenua_start' => 8,
        'title' => 'Scout'
      },
      'tank' => {
        'deploy_time' => 6,
        # "lifespan_ms" => 8 * 60 * 1000,
        'lifespan' => 8 * 1000,
        'pouwhenua_start' => 3,
        'title' => 'Tank'
      },
      'commander' => {
        'deploy_time' => 8,
        # "lifespan_ms" => 5 * 60 * 1000,
        'lifespan' => 5 * 1000,
        'pouwhenua_start' => 4,
        'title' => 'Commander'
      }
    }
    @player_classes.each_with_index do |pc, index|
      button_width = 200
      button = UIButton.buttonWithType(UIButtonTypeSystem)
      button.setTitle(pc[0], forState: UIControlStateNormal)
      button.titleLabel.font = UIFont.systemFontOfSize(30, weight: UIFontWeightSemibold)
      # button.setTitleColor(color, forState:UIControlStateNormal)
      button.sizeToFit
      button.frame = CGRectMake(
        self.view.center.x - (button.frame.size.width / 2), (index * button.frame.size.height + 20) + 180,
        200, button.frame.size.height
      )
      button.autoresizingMask =
      UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin
      button.addTarget(self,
      # action:"select_#{pc[0]}",
      action: "select_player_class:",
      forControlEvents: UIControlEventTouchUpInside)

      # This is a weird hack to pass the class to the action
      button.tag = index
      self.view.addSubview(button)
    end
  end

  def select_player_class(sender)
    puts "CHARACTERCONTROLLER SELECT_PLAYER_CLASS".blue if DEBUGGING

    player_class = @player_classes.values[sender.tag]
    puts "Class selected: #{player_class}".focus

    # This sends it directly to the Takaro
    # But this won't work with the Join Controller, as the Takaro doesn't exist until
    # the player enters the gamecode
    # Machine.instance.current_view.takaro.local_kaitakaro_hash['player_class'] = player_class
    # Machine.instance.current_view.takaro.local_kaitakaro.character_hash = player_class
    # Machine.instance.current_view.takaro.local_kaitakaro.character = player_class

    # directly make a local variable on the Controller, for Join Controller
    Machine.instance.current_view.local_character = player_class

    # post notification for New Controller
    Notification.center.post("SelectCharacter", player_class)

    dismiss_modal
  end

  def dismiss_modal
    presentingViewController.dismissViewControllerAnimated(true, completion: nil)
  end
end
