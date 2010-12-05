# library functions for use with tweaktweet 

require 'rubygems'
require 'geokit'

def location(adr)
  Geokit::Geocoders::MultiGeocoder.geocode(adr + ", #{@conf.city}")
end

class Position          # simply keeps the position, by writing to an external file. state independent.
  attr_reader :pos

  def initialize
    if File.exists?("position")
      @pos = File.read("position").to_i
    else
      @pos = 0
    end
    @file = File.open('position','w')
  end

  def pos=(newpos)
    @pos=newpos
    @file.seek(0)
    @file << @pos.to_s
  end  
end
