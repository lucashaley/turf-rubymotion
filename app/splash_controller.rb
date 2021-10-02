class SplashController < UIViewController
  # https://code.tutsplus.com/tutorials/lets-write-a-rubymotion-app-part-1--cms-20612
  extend IB

  def viewDidLoad
    self.view.addGestureRecognizer(
      UITapGestureRecognizer.alloc.initWithTarget(self, action: "handleSingleTap:")
    )
  end

  def handleSingleTap(recognizer)
    UIApplication.sharedApplication.delegate.to_menu
  end
end
