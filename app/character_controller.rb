class CharacterController < MachineViewController
  attr_accessor :player_classes

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

  def viewDidLoad
    super
    puts 'CHARACTERCONTROLLER VIEWDIDLOAD'.blue if DEBUGGING
    @player_classes = {
      'scout' => {
        "deploy_time" => 4,
        "lifespan_ms" => 2 * 60 * 1000,
        "pouwhenua_start" => 8
      },
      "tank" => {
        "deploy_time" => 6,
        "lifespan_ms" => 8 * 60 * 1000,
        "pouwhenua_start" => 3
      },
      "commander" => {
        "deploy_time" => 8,
        "lifespan_ms" => 5 * 60 * 1000,
        "pouwhenua_start" => 4
      }
    }
    @player_classes.each_with_index do |pc, index|
      button_width = 200
      button = UIButton.buttonWithType(UIButtonTypeSystem)
      button.setTitle(pc[0], forState:UIControlStateNormal)
      button.titleLabel.font = UIFont.systemFontOfSize(30, weight: UIFontWeightSemibold)
      # button.setTitleColor(color, forState:UIControlStateNormal)
      button.sizeToFit
      button.frame = CGRectMake(
        self.view.center.x-(button.frame.size.width/2), (index * button.frame.size.height + 20) + 180,
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
    # Machine.instance.current_view.takaro.kaitakaro_hash = player_class
    # Machine.instance.current_view.takaro.kaitakaro_hash["pouwhenua_current"] = player_class["pouwhenua_start"]
    Machine.instance.current_view.takaro.local_kaitakaro_hash['player_class'] = player_class
    puts "Machine class: #{Machine.instance.current_view.takaro.local_kaitakaro_hash['player_class']}"
>>>>>>> Stashed changes
    dismiss_modal
  end

  def dismiss_modal
    presentingViewController.dismissViewControllerAnimated(true, completion: nil)
  end
end
