# library functions for parsing lat/long (normalizing) - should be usable outside of TtT
# based on Kate Starbird's original TtT code

# !!currently not functional


# try and find the lat/long info in a few different ways if we didn't get
# it from the tweet metadata
if (gps_lat.length < 3) || (gps_long.length < 3)
  # grab from the #lat and #long/#lng/#lon tags
  gps_lat = parse_lat(twt)
  gps_long = parse_long(twt)
  if (gps_lat == "") || (gps_long == "")
    # search for a lat/long written in decimal format
    lat_long_arr1 = parse_lat_long(twt)
    gps_lat = lat_long_arr1[0];
    gps_long = lat_long_arr1[1];
    if gps_lat == ""
      # search for a lat/long written in degrees/minutes/seconds format 
      lat_long_arr2 = parse_lat_long_degrees_minutes_seconds(twt);
      if lat_long_arr2[0] != 0
        gps_lat = lat_long_arr2[0].to_s
        gps_long = lat_long_arr2[1].to_s
      end
    end
  end
end

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
