class Scout < Character
  def initialize
    @name = "scout"
    @charging_ms = 4 * 1000
    @lifespan_ms = 5 * 60 * 1000
    @pouwhenua_start = 5
    @pouwhenua_current = 5
  end
end
