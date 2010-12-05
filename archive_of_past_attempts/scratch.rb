class Position          # simply keeps the position, by writing to an external file. state independent.
  attr_reader :pos

  def initialize
    if File.exists?("position")
      @pos = File.read("position").to_i
    else
      @pos = 0
    end
    @file = File.open('position','w')
  end

  def pos=(newpos)
    @pos=newpos
    @file.seek(0)
    @file << @pos.to_s
  end  
end



# example of the data that comes from a Tweet:
# 
# (text, status.author.screen_name, status.id, status.source, status.created_at, lat_s, long_s, place, url, box)
# coordinates=>[40.00994082, -105.25638727]}}
# text, author, tweet_id, source, time, gps_lat, gps_long, place, place_url, bounding_box



first filtering
if (txt.downcase =~ /#(imok|ruok|missing|trapped|injured|injury|need|offer|raod|traffic|closed|shelter|damage|facility|service|power |open |closed|fire |fatality|dead |src |loc )/) ||
                                    (txt.downcase =~ /(twitpic|tweetphoto|yfrog|moby\.to|goo\.gl|twitgoo|instagr\.am|twitvid|pegd.at|plixi.com|youtu.be|eye.tc|videos.ph|flic.kr)/)









# parsing
def parse_type(text)
  
  if text.downcase =~ /#(imok|ruok|missing|trapped|injured|injury|fatality|dead |need|offer|raod|traffic|closed|shelter|damage|facility|service|power |open |closed|cancelled|fire )/
    return $1.strip
  end
  
  if text.downcase =~ /#(photo )/
    return $1.strip
  end
   
  return ""
end


# parsing 2
def parse_type_s(text)
  
  if text.downcase =~ /#(imok|ruok|missing|trapped|injured|injury|fatality|dead |need|offer|raod|traffic|closed|shelter|damage|facility|service|power |open |closed|cancelled|fire )([^#]*)/
    cur = $2
    return cur
  end

  if text.downcase =~ /#(photo)([^#]*)/
    cur = $2
    return cur
  end

  return ""
end


# parsing RT
def parse_RT(text)  
  if text.downcase =~ /(r @|rt @|via @)/
    return true
  end
  return false
end

# parsing other stuff
def parse_pic(text)
  if text =~ /(\#pic |\#photo )([^#]*)/
    cur = $2
    x = cur.index("http:")
    if x != nil
      link = cur[x...cur.length]
      link_s = link[3...link.length]
      y = link_s.index("http:")
      if y != nil && y > 3
        return link[0...y+3]
      end
      return link
    end
    return ""
  end
  if text =~ /(http:\/\/twitpic)([^#^ ]*)/
    cur = $2
    x = cur.index("http:")
    if x != nil
      link = "http://twitpic" + cur[0...x]
      return link
    end 
    return "http://twitpic" + cur
  end
  if text =~ /(http:\/\/tweetphoto)([^#^ ]*)/
    cur = $2
    x = cur.index("http:")
    if x != nil
      link = "http://tweetphoto" + cur[0...x]
      return link
    end 
    return "http://tweetphoto" + cur
  end
  if text =~ /(http:\/\/)(yfrog\.com|yfrog\.us|moby\.to|twitgoo\.com|goo\.gl|twitvid\.com|instagr\.am|flic\.kr|www.ustream.tv|plixi\.com|youtu\.be|pegd\.at|www\.videos.ph)([^#^ ]*)/
    cur = $3
    link = "http://" + $2 + $3
    return link
  end
  return ""
end


def parse_number(text)
  if text.downcase =~ /(\#number|\#num )([^#]*)/
    cur = $2
    return cur
  end
  return ""
end

def parse_amount(text)
  if text.downcase =~ /(\#amount|\#capacity|\#cap )([^#]*)/
    cur = $2
    return cur
  end
  return "" 
end

def parse_contact(text)
 if text.downcase =~ /(\#contact|\#con |contact |#tel )([^#]*)/
    cur = $2
    return cur
  end
  return "" 
end

def add_phone_number(contact, text)
  if text.downcase =~ /([0-9]*[0-9\+\- ]*[0-9]+)/
    tel = $1
    if tel.length > 7
      contact = collapse(contact, tel)
    end
  end
  return contact
end

def parse_source(text)
 if text.downcase =~ /(\#source|\#src)([^#]*)/
    cur = $2
    return cur
  end
  return ""   
end

# parsing lat/long using #lat / #long tags (rare)
def parse_lat(text)
  if text.downcase =~ /(\#lat )([\-]*[0-9]+.[0-9]+)/
    return $2
  end
  return ""
end

def parse_long(text)
  if text.downcase =~ /(\#long |\#lng |\#lon)([\-]*[0-9]+.[0-9]+)/
    return $2
  end
  return ""
end

# parsing lat/long in a variety of common formats (decimal)
def parse_lat_long(text)
  if text.downcase =~ /[\-]*([0-9]+\.[0-9]+),[ ]*([\-]*[0-9]+\.[0-9]+)/
    print "lat long assumes" + text + "\n" + $1 + " " + $2+ "\n"
    return [$1, $2]
  end
  
  if text.downcase =~ /[\-]*([0-9]+\.[0-9]+)[ ]+([\-]*[0-9]+\.[0-9]+)/
    print "lat long assumes" + text + "\n" + $1 + " " + $2+ "\n"
    return [$1, $2]
  end
  
  if text.downcase =~ /[\-]*([0-9]+\.[0-9]+)[ ]*([nsew])[,]*[ ]*([\-]*[0-9]+\.[0-9]+)[ ]*([nsew])/
    lat = $1
    long = $3
    if $2 == "s" || $2 == "w"
      lat = "-" + lat
    end
    
    if $4 == "s" || $4 == "w"
      long = "-" + long
    end
    
    if $2 == "e" || $2 == "w"
      x = long
      long = lat
      lat = x
    end
     
    return [lat, long]
  end
  
  return ["", ""] 
end

def parse_lat_long_degrees_minutes_seconds(text)
  lat = long = 0
  if text.downcase =~ /([0-9]+)[\.\,]([0-9]+)[\'\"]*([ns])/
    minutes = $2.to_f / 60;
    lat = $1.to_f + minutes
    if $3 == "n"
      lat = -lat;
    end
  end
  if text.downcase =~ /([0-9]+)[\.\,]([0-9]+)[\'\"]*([ew])/
    minutes = $2.to_f / 60;
    long = $1.to_f + minutes
    if $3 == "e"
      long = -long;
    end
  end

  return [lat, long]
end

# parse a google location
def parse_Google_loc(text)
  if text =~ /(L: http:\/\/)([^#^ ]*)/
     cur = $2
    x = cur.index("http:")
    if x != nil && x > 0
      link = cur[0...x]
      return "http://" + link
    end
    return "http://" + cur
  end
  return ""
end

# parse the info or detail/details tag
# also collpsing time/date/num/capacity here
def parse_info(text)
  result = ""
  if text.downcase =~ /(#info|#detail)([^#]*)/
    result += $2 + " "
  end
  if text.downcase =~ /(#time|#date)([^#]*)/
    result += "time " + $2 + " "
  end
  if text.downcase =~ /#(number|num |amount|amt |capacity|cap )([^#]*)/
    result += $1 + " " + $2 + " "
  end
  return result
end

# parse the status
def parse_status(text)
  if text.downcase =~ /(#status|#estati)([^#]*)/
    cur = $2
    return cur
  end
  return ""
end

# parse the textual location after the #loc tag
def parse_location(text)
  if text.downcase =~ /(\#loc |\#location |\#gps |\#pozisyon |\#lokalite |\#lok )([^#]*)/
    cur = $2
    return cur if cur.length > 3
  end
  
  if text.downcase =~ /(\#loc \#|\#location \#|\#gps \#|\#pozisyon \#|\#lokalite \#|\#lok \#)([^#]*)/
    cur = $2
    return cur
  end
  return ""
end
