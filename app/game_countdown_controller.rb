class GameCountdownController < MachineViewController
  def viewDidLoad
    super

    @location_update_observer = Notification.center.observe 'CountdownSegueToGame' do |data|
      mp 'LETS GOOOOOOOOOOOOOOOO!!!'
      Notification.center.post('game_state_playing_notification', nil)
      performSegueWithIdentifier('ToGame', sender: self)
    end
  end
end
