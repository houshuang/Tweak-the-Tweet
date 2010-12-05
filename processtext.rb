# (text, author, tweet_id, source, time, gps_lat, gps_long, place, place_url, bounding_box)





# this is an experiment in processing tweet texts
require 'library'

# produces a hash of all tags, with their description
# ie turns this
# ttt_test #ttt_test2 #damage South tower collapsed #loc 43.634087,-79.341888  #status Dragon attacking castle.
# into this
# {"loc"=>"43.634087,-79.341888", "damage"=>"South tower collapsed", "status"=>"Dragon attacking castle.", "ttt_test"=>"",
# "ttt_test2"=>""}
def hash_to_dict(line)
  tags = Hash.new  
  line.downcase.split("#").each do |tag| 
    next if tag.size == 0
    tag, *desc = tag.split(" ")
    tags[tag] = desc.join(" ")
  end
  return tags
end

# this function receives a text string from the tweet with the location. this could be a text address or 
# lat long in a number of different formats. if it's text, it uses location() from library to look it up
# with geokit, if it's numbers, it uses a number of algorithms to get it into a normalized lat/long form
# to be able to map it geographically. right now it returns a text string with the lat long, perhaps it should
# be an array of longs, depends on what we want to do with it later.
def parse_location(text)
  if text =~ /[a-zA-Z]/
    return location(text)
  else
    return text
  end
end

# this function receives a single tweet text, and parses the text 
def process(tweet)
  puts tweet
  hash_to_dict(tweet).each do |tag|
    if tag[0] == "loc"
      tag[1] = parse_location(tag[1])
    end
    p tag
  end
end

File.read("twitter-examples.txt").each do |line|
  process(line)
end