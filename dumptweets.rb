require 'rubygems'
require 'tweetstream'  
require 'filelib'

@conf = YAML::load(File.read("config.yml"))

require 'filelib'
dumper = Filelib::Dumper.new(1)

TweetStream::Client.new(@conf['name'], @conf['password']).track('ttt_test2') do |s|
  dumper.add_to_cache(s)
  puts "#{s.user.name}: #{s.text}"
end

dumper.ensure_flush