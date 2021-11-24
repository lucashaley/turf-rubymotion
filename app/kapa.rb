class Kapa # a team
  extend Debugging

  attr_accessor :color,
                :uuid,
                :nga_kaitakaro

  def initialize
    @nga_kaitakaro = []
  end
end
