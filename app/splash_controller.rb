class SplashController < MachineViewController
  def viewDidLoad
    super
    self.view.addGestureRecognizer(
      UITapGestureRecognizer.alloc.initWithTarget(self, action: "handleSingleTap:")
    )
  end

  def handleSingleTap(recognizer)
    Machine.instance.fsm.event(:splashToMenu)
  end
end
