class Game
  attr_accessor :gamecode

  def initialize
    puts "Game initialize"
    @gamecode = generate_new_id
    puts "Gamecode: #{@gamecode}"
  end

  def generate_new_id
    puts "Machine generate_new_id"
    # update the UI with the gamecode
    # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
    new_id = rand(36**6).to_s(36)

    # check if it exists already
    # puts @db_ref.child("games")
  end
end
