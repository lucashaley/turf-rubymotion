class DbView < UIView
  def drawRect(rect)
    bgcolor = UIColor.blackColor
    bgcolor.set
    UIBezierPath.bezierPathWithRect(frame).fill

    text = "Doing database"
    font = UIFont.systemFontOfSize(36)
    UIColor.whiteColor.set
    text.drawAtPoint(CGPoint.new(10, 20), withFont: font)
  end
end
