require 'rubygems'
require 'tweetstream'  
require 'yaml'

conf = YAML::load(File.read("config.yml"))

TweetStream::Client.new(conf['name'], conf['password']).track('ttt_test') do |status|
  puts "[#{status.user.screen_name}] #{status.text}"
  p status
end