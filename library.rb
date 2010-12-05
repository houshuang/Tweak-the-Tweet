# library functions for use with tweaktweet 

require 'rubygems'
require 'geokit'

def location(adr)
  Geokit::Geocoders::MultiGeocoder.geocode(adr + ", #{@conf.city}")
end
