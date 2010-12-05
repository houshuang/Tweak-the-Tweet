# reads tweets from the queue (database), parses them, and outputs them

require 'db'
require 'library'

while(1)
  DB::Tweet.find(:all, :limit => 5).each do |tweet|
    p tweet
    puts "#{tweet.user} + #{tweet.text}"
    tweet.delete
  end

end
