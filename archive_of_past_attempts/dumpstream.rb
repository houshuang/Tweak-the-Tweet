require 'rubygems'
require 'tweetstream'  
require 'yaml'

# local parts
require 'library'     # utility functions
require 'db'          # connecting to database, creating if it doesn't exist already

@conf = YAML::load(File.read("config.yml"))

TweetStream::Client.new(@conf['name'], @conf['password']).sample do |s|
  DB::Tweet.create(:user => s.user.name, :text => s.text)
  puts "#{s.user.name}: #{s.text}"
end
