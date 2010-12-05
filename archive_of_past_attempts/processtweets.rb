# reads tweets from the queue (database), parses them, and outputs them

require 'db'
require 'library'

counter = Position.new

# this search query finds 20 new posts with IDs higher than the current position, then stores the 
# new position to avoid reading the same tweets again. By storing the position outside of the database
# we don't have to compete with the reader for write-access to the database.

ActiveRecord::Base.allow_concurrency = true
while(1)
  DB::Tweet.find(:all, :conditions => { :id => counter.pos..-1 }, :limit => 20).each do |tweet|
    puts "#{tweet.user} + #{tweet.text}"
    counter.pos = tweet.id
  end
end
