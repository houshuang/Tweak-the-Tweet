# library functions for use with tweaktweet 

require 'rubygems'
require 'geokit'
require 'yaml'

@conf = YAML::load(File.read("config.yml"))

def location(adr)
  gk = Geokit::Geocoders::MultiGeocoder.geocode(adr + ", #{@conf['city']}")
  return gk.lat.to_s + ", " + gk.lng.to_s
end
