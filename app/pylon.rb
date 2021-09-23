class Pylon
  attr_reader :location, :owner, :lifespan, :birthdate

  def initialize(location, owner, lifespan, birthdate)
    @location = location
    @owner = owner
    @lifespan = lifespan
    @birthdate = birthdate
  end

  def life
    return DateTime.now() - birthdate
  end
end
