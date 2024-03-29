class SplashController < MachineViewController
  def viewDidLoad
    super
    self.view.addGestureRecognizer(
      UITapGestureRecognizer.alloc.initWithTarget(self, action: "handleSingleTap:")
    )
  end

  def handleSingleTap(recognizer)
    Notification.center.post('app_splash_to_menu', nil)
    Machine.instance.fsm.event(:splashToMenu)
  end
end
