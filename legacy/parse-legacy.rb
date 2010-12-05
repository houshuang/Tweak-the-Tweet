  #!/usr/bin/env ruby
  # Code by Kate Starbird
  
  
require "rubygems"
require "mysql"
require "date"
require "time"
require "fileutils"
require "google_spreadsheet"

count = 0

def set_database(db_name)
  db = Mysql.new("localhost", "root", "", db_name)
  return db
end

# this is a first line filter which pulls any tweet from tweets_dump that looks like it might be in TtT format
# these possible TtT tweets are then put into a secondary table, tweets
def graduate_tweets(db, time) 
  
  # first pull any tweets from tweets_dump that fit the bill
  print time.to_s + "\n"
  
  res = db.query("SELECT * FROM tweets_dump WHERE time >= '" + time.to_s + "'")
  res.each do |row|
    txt = row[1]
    for i in (0...row.length)
      if row[i] == nil || row[i] == "NULL"
         row[i] = ""
      end
    end
    # this reg ex is actually event dependent, not that not every primary tag makes a good first line filter
    # for instance, "flood" is too general
    # however, some secondary tags make good TtT filters "loc " and "src "
    if (txt.downcase =~ /#(imok|ruok|missing|trapped|injured|injury|need|offer|raod|traffic|closed|shelter|damage|facility|service|power |open |closed|fire |fatality|dead |src |loc )/) ||
                                        (txt.downcase =~ /(twitpic|tweetphoto|yfrog|moby\.to|goo\.gl|twitgoo|instagr\.am|twitvid|pegd.at|plixi.com|youtu.be|eye.tc|videos.ph|flic.kr)/)
       res = db.query("SELECT id FROM tweets WHERE text LIKE '%" + txt + "%'")
       if res == nil || res.fetch_row == nil            
            db.query("INSERT INTO tweets (text, author, tweet_id, source, time, parsed, gps_lat, gps_long, place, place_url) VALUES ('" +
               txt + "', '" + row[2] + "', '" + row[3] + "', '" + row[4] + "', '" + row[5] + "', '" +
               row[6] + "', '" + row[7] + "', '" + row[8] + "', '" + row[9] + "', '" + row[10] + "')")
       end
     end 
  end
end

######################################################################################################

# this is here to allow for crowd-sourcing assistance at the spreadsheet level
# changes to records on the spreadsheet are updated into the MySQL record storage
# this can cause things to be way out of line, if someone is not updating the Spreadsheet correctly - so it's currently dangerous
# I would only allow this portion if I was closely monitoring the event (and giving only select access to edit the spreadsheet)
def update_database_from_Google_Spreadsheet(db)
   print "Updating database from Spreadsheet - for edited records\n\n"
   
   # Logs in.
  # You can also use OAuth. See document of GoogleSpreadsheet.login_with_oauth for details. You'll need a Google Doc account/login + access to the spreadsheet
  session = GoogleSpreadsheet.login("your_Google_login", "your_password")

  # this is the Spreadsheet code - different for each Google Spreadsheet document
  ws = session.spreadsheet_by_key("0AkuhimfFYZrOdG9XN1FDbmxnRlcwVFRraFZ6M0o3Tnc").worksheets[0]
                                   
  el_num = 1
  row_num = 2
 
  found_record = []
 
  while ws[row_num, 1] != ""
      row_record = Array.new
      for el_num in (1..19)
        row_record[el_num-1] = ws[row_num, el_num]
        row_record[el_num-1] = "" if row_record[el_num-1] == "NA"
      end
      row_num += 1
      el_num = 0
      
      found_record.push(row_record[18])
      compare_and_update_res(db, row_record, row_record[18])
  end
  
  res = db.query("SELECT id FROM records")
  res.each do |row|
    if !(found_record.index(row[0]))
      # this allows us to delete records permanently by removing them from the google spreadsheet
      print "Delete record " + row[0] + "\n"
      db.query("DELETE FROM records WHERE id = '" + row[0] + "'")
    end
  end
 
end

# part of the code that takes new info from spreadsheet and adds that info the appropriate record
def compare_and_update_res(db, row, id)
    
    db.query("UPDATE records SET type_specifics = '" + row[1] + "', contact = '" + row[4] + "', info = '" + row[5] + "', status = '" + row[6] + "', text_location = '" + row[3] + "', gps_lat = '" + row[7] +
               "', gps_long = '" + row[8] + "', pic = '" + row[9] + "', source = '" + row[10] + "', tweet_author = '" + row[11] + "', mapped = '" + row[13] + "', verified = '" + row[14] +
               "', actionable = '" + row[15] + "', Ushahidi = '" + row[16] + "', complete = '" + row[17] + "' WHERE id = '" + id + "'")  
     

    # if can't find a record with the id - then add new record
      res = db.query("SELECT id FROM records WHERE id = '" + id + "'")
      if res == nil or res.fetch_row == nil
        db.query("INSERT INTO records (type, type_specifics, time, text_location, contact, info, status, gps_lat, gps_long, pic, source, tweet_author, tweet, mapped, verified, actionable, Ushahidi, complete) VALUES ('" +
          row[0] + "', '" + row[1] + "', '" + row[2] + "', '" + row[3] + "', '" + row[4] + "', '" + row[5] + "', '" + row[6] + "', '" +
          row[7] + "', '" + row[8] + "', '" + row[9] + "', '" + row[10] + "', '" + row[11] + "', '" + row[12] + "', '" + row[13] +
          "', '" + row[14] + "', '" + row[15] + "', '" + row[16] + "', '" + row[17] + "')")
      end
    
end


######################################################################################################

# parse the type of report - only one of the tags will apply to any report
# in more complex events, we use a series of reg-exes
# for instance, the "photo" tag may be a primary tag, but it also may just be a data tag, so we
# check for other, more specific tags first, then check for photo later
# we've done this for the "flood" tag, the "cholera" tag, the "fire" tag and many similar
# this is event-specfic (this list of tags) and will ideally be defined by an adminstrator launching an event collection instance
def parse_type(text)
  
  if text.downcase =~ /#(imok|ruok|missing|trapped|injured|injury|fatality|dead |need|offer|raod|traffic|closed|shelter|damage|facility|service|power |open |closed|cancelled|fire )/
    return $1.strip
  end
  
  if text.downcase =~ /#(photo )/
    return $1.strip
  end
   
  return ""
end

# parses the text after the type tag - that will be the main text of the report
# the same ordered parsing applies as above
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

# could expand to other RT types, sometimes important to know if the tweet is a RT
def parse_RT(text)  
  if text.downcase =~ /(r @|rt @|via @)/
    return true
  end
  return false
end

# parse all the different known photo types and #pic/#photo links/
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

######################################################################################################

# sometimes we have the same record (sort of) but with new information for a tag, so we append it
# we need a better solution for this
def fix_repeat_record(old, new)
  return new if old == ""
  return old if new == ""
  
  if old.index(new.downcase) != nil
    return old
  end
  
  return old + ", " + new
end

# again, this is looking to see if two records are the same, if they should be added
def collapse(s1, s2)
  return s2 if s1 == nil
  return s1 if s2 == nil

  x = s2.index("(cont)")
  if x != nil && x > 0
    s2 = s2[0...x]
  end

  s1.gsub!("...", "")
  s1.gsub!("NA", "")
  s1.strip!
  s2.gsub!("...", "")
  s2.gsub!("NA", "")
  s2.strip!
  
  return s1 if s1 == s2
  
  if s1.index(s2) != nil
    return s1
  end
  
  @dirty = 1
  
  if s2.index(s1) != nil
    return s2
  end
  
  return s1 + " / " + s2
end

def getLaterTime(t1, t2)
  dt1 = DateTime.parse(t1)
  dt2 = DateTime.parse(t2)
  return t1 if dt1 > dt2
  return t2
end

def getEarlierTime(t1, t2)
  return t1 if t2 == "0000-00-00 00:00:00"
  return t2 if t1 == "0000-00-00 00:00:00"
  
  dt1 = DateTime.parse(t1)
  dt2 = DateTime.parse(t2)
  return t1 if dt1 < dt2
  return t2
end

# this is super ugly, it takes the tweets that have been filtered to seem like TtT
# then parses to find a primary tag and the primary record
# then parses to find all the secondary tags, location info, photos, etc.
def parse_tweets_to_database(db, time)
  del = db.query("DELETE FROM `tweets` WHERE `text` LIKE '%[where:%' OR `text` LIKE '%[type%'") 
#  db.query("DELETE FROM `records`")
  dis = db.query("SELECT DISTINCT text FROM `tweets` WHERE time > '" + time.to_s + "'")
 
  list_array = []
  
  dis.each do |group|
  
    res = db.query("SELECT id, author, text, time, gps_lat, gps_long, place, place_url FROM tweets WHERE text = '" + group[0] + "'")
    row = res.fetch_row
   
    is_TtT = 0  
  
    twt1 = row[2].gsub("[", "")
    twt = twt1.gsub("]", "").strip
     
    author = row[1]
    
    gps_lat = row[4]
    gps_long = row[5]
    gps_lat = "" if gps_lat == nil
    gps_long = "" if gps_long == nil
    place = row[6]
    place_url = row[7]

    if (gps_lat.length < 3) || (gps_long.length < 3)
      gps_lat = parse_lat(twt)
      gps_long = parse_long(twt)
      if (gps_lat == "") || (gps_long == "")
        lat_long_arr1 = parse_lat_long(twt)
        gps_lat = lat_long_arr1[0];
        gps_long = lat_long_arr1[1];
        if gps_lat == ""
          lat_long_arr2 = parse_lat_long_degrees_minutes_seconds(twt);
          if lat_long_arr2[0] != 0
            gps_lat = lat_long_arr2[0].to_s
            gps_long = lat_long_arr2[1].to_s
          end
        end
      end
    end
    
    tweet = twt
                      
  # going to allow RTs  
      type = parse_type(twt)
      if type.length > 0
        type = "#" + type
      else
        type = "Unspecified"
      end
      type_s = parse_type_s(twt)
      type_s.strip! if type_s != nil
      location = parse_location(twt)
      location.strip!
      google_loc = parse_Google_loc(twt)
 
    # if there is a place_url - then take that in front of the google_loc   
      if place_url && place_url.length > 0
        google_loc = place_url
      end
      
      pic = parse_pic(twt)
      
      text_location = parse_location(twt)
      text_location.strip!
      
      is_rt = parse_RT(twt)
      
    # if we have a pic and a lat/long in the right area, then file as pic 
      if (pic != "") && ((type == "Unspecified") || (type == "#cholera"))
        print "has a pic of type " + type + " "
        
        if (gps_lat != "" && gps_long != "" && !is_rt)   #(as long it's not a RT)
          type = "photo"
          type_s = "local " + gps_lat + "," + gps_long
          print "has gps\n"
        elsif text_location != ""
          type = "photo"
          type_s = "local " + text_location
          print "has text location\n"
        else
          type = "Unspecified"             # if a tweets only has #maintag and no location, must be pic, but can ignore
          print "has nothing, ignoring\n"
        end
      end
      
      # if type is one of the general categories - then you only accept the record if it has GPS or textual location
      # this is to reduce noise for too-general terms, not for this Test event, but for Haiti-Cholera it looks like this:
      if (type == "#hospital" || type == "#flood" || type == "#storm" || type == "#eye" || type == "#heath facility" || type == "#hurricane")
        print "Type requires location info " + type + "\n"
        if (gps_lat == "" && text_location == "")
          print "\tNo GPS info\n"
          type = "Unspecified"
        end
      end
          
      number = parse_number(twt)
      amount = parse_amount(twt)
      if number == ""
        number = amount
      end
      info = parse_info(twt)
      info.gsub!("...", "")
      info.strip!
      status = parse_status(twt)
      status.strip!
      
      contact = parse_contact(twt)
      contact.strip!
      contact = add_phone_number(contact, twt)
      contact.strip!
      source = parse_source(twt)
      source.strip!
      
      # this isn't current in use
      event = ""
      
      # parse the bounding box into an average for lat, long
    
      # time adjusting
      d_time = DateTime.parse(row[3])
      d_time = d_time - 5.0/24.0    # 5/24 makes this EST instead of GMT, this should be flexible
      time = d_time.to_s
      time = time[0...time.length - 6]
      time[10] = " "
      
      print type + "\n"
      
      # so, only accept a tweet that has a primary type and either some report after the primary or location info
      # again, this is the main way we determine if the tweet is TtT
      if type != "Unspecified" && (type_s != "" || gps_lat != "" || text_location != "")

          if type_s == "" and info != ""
            type_s = info
          end

          # check to see if the same record exists, how??? type, type_specifics + (location or GPS w/ GPS not null)
          aRes = db.query("SELECT contact, source, num, status, pic, info, gps_lat, gps_long, time, id FROM records WHERE type = '" + type +
                          "' AND type_specifics = '" + type_s + "' AND text_location = '" + text_location +
                          "' AND gps_lat = '" + gps_lat +"' AND gps_long = '" + gps_long + "'")
   
            # if records are same (same report type & type specifics & location) but have some differences
            # then update differences, add more contact info (if one not contained in another), info, num, status, pic, GPS (if old null)
           # update time         
           count = 0 
           aRes.each do |row|
              @dirty = 0
              contact = collapse(row[0], contact)
              source = collapse(row[1], source)
              number = collapse(row[2], number)
              status = collapse(row[3], status)
              pic = collapse(row[4], pic)
              info = collapse(row[5], info)
              gps_lat = collapse(row[6], gps_lat)
              gps_long = collapse(row[7], gps_long)
              if is_rt
                time = getEarlierTime(row[8], time)
              else
                time = getLaterTime(row[8], time)
              end
              
              if @dirty
                print "Dirty\n"
                db.query("UPDATE records SET contact = '" + contact + "', source = '" + source + "', num = '" + number + "', status = '" + status +
                         "', pic = '" + pic + "', info = '" + info + "', gps_lat = '" + gps_lat + "', gps_long = '" + gps_long + "', time = '" +
                         time + "' WHERE id = '" + row[9] + "'")
              end
  
              count += 1
           end
  
            # if can't find another - then add new record
            if count == 0  
              db.query("INSERT INTO records (type, type_specifics, text_location, contact, source, num, status, pic, info, time, tweet_author, tweet, gps_lat, gps_long, loc_url, location, event) VALUES ('" + type + "', '" +
                  type_s + "', '" + text_location + "', '" + contact + "', '" + source + "', '" + number + "', '" + status +"', '" +
                  pic + "', '" + info + "', '" + time + "', '" + author + "', '" + tweet + "', '" + gps_lat +
                  "', '" + gps_long + "', '" + google_loc + "', '" + location + "', '" + event + "')")
            end       
 
      end
      
  end
end

def update_spreadsheet(db)
  # Logs in.
  # You can also use OAuth. See document of GoogleSpreadsheet.login_with_oauth for details.
  session = GoogleSpreadsheet.login("your_Google_login", "your_password")

  # this is the Spreadsheet code - different for each Google Spreadsheet document
  ws = session.spreadsheet_by_key("0AkuhimfFYZrOdG9XN1FDbmxnRlcwVFRraFZ6M0o3Tnc").worksheets[0]
                                   

  res = db.query("SELECT type, type_specifics, time, text_location, contact, info, status, gps_lat, gps_long, pic, source, tweet_author, tweet, mapped, verified, actionable, Ushahidi, complete, id FROM records ORDER BY time DESC")
  row_num = 2
  res.each do |row|
    el_num = 1
    row.each do |element|
      if !element || element.length == 0
        element = 'NA'
      end
      ws[row_num, el_num] = element
      el_num += 1
    end
    row_num += 1
  end

  begin
    ws.save()
    
  rescue
    print "Some sort of worksheet save error - don't save the date"
    @save_error = true
    
  end

end

db = Mysql.new("localhost", "root", "", "TtT_Aux")

res = db.query("SELECT time, id FROM last_parsed ORDER BY time DESC LIMIT 1")
arow = res.fetch_row
a_time = arow[0]
oldtime = DateTime.parse(a_time)
print "Start time " + oldtime.to_s + "\n"

count = arow[1].to_i

# put in some timing loop
while (true) do
  print "Iteration " + count.to_s + "\n"
  count += 1
  
  db = Mysql.new("localhost", "root", "", "TtT_Aux")
  
  db.query("DELETE FROM tweets")

  update_database_from_Google_Spreadsheet(db)

  time = DateTime.now
   
  graduate_tweets(db, oldtime)
  print "Move tweets from tweet_dump to tweets\n"
  
  parse_tweets_to_database(db, oldtime)
  print "Parsing tweets to database\n"
  
  @save_error = false
  print "Update Spreadsheet\n"
  update_spreadsheet(db)

  print time.to_s + "\n"
  
  time = time + 7.0/24.to_f
  
  oldtime = time
  
  if !@save_error
    db.query("INSERT INTO last_parsed (id, time) VALUES ('" + count.to_s + "', '" + time.to_s + "')")
  end
  
  print "Sleeping\n"  
  sleep 1200
end


  
  
  

