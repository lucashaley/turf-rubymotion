class BeachSection
  attr_accessor :next,
                :previous,
                :parent,
                :right,
                :left,
                :red,
                :site,
                :edge,
                :circle_event

  DEBUGGING = true

  def initialize(in_site)
    puts "BEACHSECTION INITIALIZE".green if DEBUGGING
    @site = in_site
  end

  # Do we need to pass the array by reference?
  def self.create_beachsection_from_junkyard(in_junkyard, site: in_site)
    puts "BEACHSECTION CREATE_BEACHSECTION_FROM_JUNKYARD".blue if DEBUGGING
    if in_junkyard.length > 0
      section = in_junkyard.last
      # not sure if this is working
      in_junkyard.pop
      section.site = in_site
      return section
    else
      return BeachSection.new(in_site)
    end
  end
  # class <<self
  #   alias_method :createBeachSectionFromJunkyard, :create_beachsection_from_junkyard
  # end
end
