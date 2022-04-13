# frozen_string_literal: true

# {
#   coordinate
#   {
#     latitude,
#     longitude
#   },
#   created,
#   kaitakaro
#   {
#
#   }
# }

class KapaFbo < FirebaseObject
  attr_reader :kaitakaro_array
              :kaitakaro_hash

  def initialize(in_ref, in_data_hash)
    @kaitakaro_array = []
    @kaitakaro_hash = {}
    super.tap do |k|

    end
  end

  def add_kaitakaro(in_kaitakaro)
    @kaitakaro_array << in_kaitakaro
    @kaitakaro_hash[in_kaitakaro.ref.key] = in_kaitakaro.data_hash
    update({ 'kaitakaro' => @kaitakaro_hash })
    puts "@kaitakaro_hash: #{@kaitakaro_hash.inspect}".red
  end

  def empty?
    @kaitakaro_array.empty?
  end

  def list_display_names
    @kaitakaro_array.map { |k| k.name_and_character }
  end

  # Helpers
  def kaitakaro
    data_hash['kaitakaro']
  end
end
