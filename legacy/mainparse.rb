# trying to extract the main useful stuff from parse-legacy

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
