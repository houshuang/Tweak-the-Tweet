# reads tweets from the queue, parses them, and outputs them

require 'rubygems'
require 'tweetstream'
require 'filelib'
require 'library'

r = Filelib::Reader.new
while (r.morechunks?)
  r.readchunk.each do |tweet|
    puts tweet.user.name + ": " + tweet.text
  end
end