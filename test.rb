require 'rubygems'
require 'tweetstream'  
require 'yaml'
require 'pp'
require 'geokit'

@conf = YAML::load(File.read("@config.yml"))

def location(adr)
  Geokit::Geocoders::MultiGeocoder.geocode(adr + ", #{@conf.city}")
end
  

TweetStream::Client.new(@conf['name'], @conf['password']).track('ttt_test') do |s|
  puts [s.text, s.user[screen_name],s.id,s.source,s.created_at].join(",")
  puts "hi"
end
# (text, status.author.screen_name, status.id, status.source, status.created_at, lat_s, long_s, place, url, box)
# coordinates=>[40.00994082, -105.25638727]}}
# text, author, tweet_id, source, time, gps_lat, gps_long, place, place_url, bounding_box

# {:retweet_count=>nil,
#  :in_reply_to_user_id_str=>nil,
#  :coordinates=>nil,
#  :in_reply_to_status_id_str=>nil,
#  :favorited=>false,
#  :geo=>nil,
#  :place=>nil,
#  :user=>
#   {:time_zone=>nil,
#    :utc_offset=>nil,
#    :follow_request_sent=>nil,
#    :statuses_count=>7,
#    :listed_count=>0,
#    :profile_sidebar_border_color=>"C0DEED",
#    :notifications=>nil,
#    :profile_link_color=>"0084B4",
#    :following=>nil,
#    :lang=>"en",
#    :profile_sidebar_fill_color=>"DDEEF6",
#    :profile_background_color=>"C0DEED",
#    :url=>nil,
#    :show_all_inline_media=>false,
#    :description=>nil,
#    :profile_text_color=>"333333",
#    :protected=>false,
#    :profile_background_tile=>false,
#    :geo_enabled=>false,
#    :favourites_count=>0,
#    :created_at=>"Sat Dec 04 15:41:58 +0000 2010",
#    :screen_name=>"stian_disaster",
#    :followers_count=>6,
#    :location=>nil,
#    :friends_count=>1,
#    :contributors_enabled=>false,
#    :name=>"Stian RHOK2 Test",
#    :verified=>false,
#    :id=>222828757,
#    :profile_image_url=>
#     "http://s.twimg.com/a/1291318259/images/default_profile_4_normal.png",
#    :profile_background_image_url=>
#     "http://s.twimg.com/a/1291318259/images/themes/theme1/bg.png",
#    :profile_use_background_image=>true,
#    :id_str=>"222828757"},
#  :source=>"web",
#  :created_at=>"Sat Dec 04 20:35:52 +0000 2010",
#  :retweeted=>false,
#  :in_reply_to_status_id=>nil,
#  :truncated=>false,
#  :entities=>
#   {:urls=>[],
#    :hashtags=>
#     [{"text"=>"ttt_test", "indices"=>[0, 9]},
#      {"text"=>"tickles", "indices"=>[37, 45]},
#      {"text"=>"MacGyver", "indices"=>[52, 61]},
#      {"text"=>"ATeam", "indices"=>[66, 72]}],
#    :user_mentions=>[]},
#  :in_reply_to_user_id=>nil,
#  :contributors=>nil,
#  :text=>
#   "#ttt_test Sitting on a ticking bomb. #tickles Bring #MacGyver and #ATeam",
#  :id=>11156756612775936,
#  :id_str=>"11156756612775936",
#  :in_reply_to_screen_name=>nil}

