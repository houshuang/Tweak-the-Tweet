# reads tweets from the queue, parses them, and outputs them. it starts a loop reading each
# file, and when there are no new files, it sleeps for a second and checks again, for ever.
# this way it can keep running and will wake up when tweets arrive

require 'rubygems'
require 'tweetstream'
require 'filelib'
require 'library'

r = Filelib::Reader.new
while(1)
  while (r.morechunks?)
    r.readchunk.each do |tweet|
      puts tweet.user.name + ": " + tweet.text
    end
  end
  sleep(1)
end