#!/usr/bin/env python
# A #Haiti Twitter stream listener for TweakTheTweet using Tweepy.
# Requires Python 2.6
# Requires Tweepy http://github.com/joshthecoder/tweepy
# http://creativecommons.org/licenses/by-nc-sa/3.0/us/
# Based on: http://github.com/joshthecoder/tweepy-examples
# Modifications by @ayman
# Further modifications by Kate Starbird, @kate30_CU
 
import time
from getpass import getpass
from textwrap import TextWrapper
import tweepy
import re
import pprint
import sys

#import MySQLdb

class MockDB:
    def commit():
        print "MockDB: commit()"
    def rollback():
        print "MockDB: rollback()"
    def close():
        print "MockDB: close()"
    
    def execute(sql):
        print "MockDB: execute(%s)" % sql 

     
# Primary Filter, can be a comma seperated list of hashtags.
PRIMARY_TRACK_LIST = "#ttt_test"

def get_place(st):
    """Extract location info from the status message object"""

    place = ''
    place_url = ''
    box = []
    if st.place:
        place = 'Place Found'
            
        if "name" in st.place and st.place["name"]:
            place = st.place["name"]
 
        if "full_name" in st.place and st.place["full_name"]:
            place = st.place["full_name"]
            
        if "url" in st.place and st.place["url"]:
            place_url = st.place["url"]
        
        if "bounding_box" in st.place:
            if "coordinates" in st.place["bounding_box"]:
                box = st.place["bounding_box"]["coordinates"]
       
    return place,place_url,box
    
def get_coords(st):
    '''Get geo coordinates from the Status object'''
    a = None
    b = None
    if st.geo:
        if st.geo["type"]:
            print '%s' % str(st.geo["type"])
        
        if st.geo["coordinates"] and st.geo["coordinates"][0] and st.geo["coordinates"][1]:
            a = st.geo["coordinates"][0]
            b = st.geo["coordinates"][1]
             
    return a,b


class StreamWatcherListener(tweepy.StreamListener):
    """A listener for events from tweepy"""

    status_wrapper = TextWrapper(width=70,
                                 initial_indent=' ',
                                 subsequent_indent=' ')
 
    def __init__(self, u, p):
        self.auth = tweepy.BasicAuthHandler(username = u,
                                            password = p)
        self.api = tweepy.API(auth_handler = self.auth,
                              secure=True,
                              retry_count=3)
        return
 
    def on_status(self, status):
        global db
        global cursor

        place,url,box = get_place(status)
        lat,long = get_coords(status)
        
        num = 0.0
        lat_num = 0.0
        long_num = 0.0
     
	# extract geo location information from the Status object
        if (not lat) and box and len(box) > 0:    
            for coord in box[0]:
                print '%s, ' % coord
                lat_num += float(coord[1])
                long_num += float(coord[0])
                num += 1.0
            if lat_num > 0:
                lat = lat_num / num
                long = long_num / num
        
	# format the lat and long if we have it
        if lat and long:
            lat_s = '%f' % lat
            long_s = '%f' % long      
        else:
            lat_s = ''
            long_s = ''
        
        text = status.text.replace("'", "")
            
        print self.status_wrapper.fill(text)
        print '%s %s via %s #%s\n Lat %s, Long %s, Place %s\n' % (status.author.screen_name,
            status.created_at,
            status.source,
            status.id,
            lat_s, long_s, place)
            
        try:                
            sql = "INSERT INTO tweets_dump (text, author, tweet_id, source, time, gps_lat, gps_long, place, place_url, bounding_box) VALUES  ('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s')" % \
                    (text, status.author.screen_name, status.id, status.source, status.created_at, lat_s, long_s, place, url, box)

            try:
                # Execute the SQL command
                cursor.execute(sql)
                # Commit your changes in the database
                db.commit()
                print "Commit"

            except:
                # Rollback in case there is any error
                db.rollback()
                print "Rollback"

        except:
            # Catch any unicode errors while printing to console and
            # just ignore them to avoid breaking application.
            pass
        return
 
    def on_limit(self, track):
        print 'Limit hit! Track = %s' % track
        return
 
    def on_error(self, status_code):
        print 'An error has occured! Status code = %s' % status_code
        return True # keep stream alive
 
    def on_timeout(self):
        print 'Timeout: Snoozing Zzzzzz'
        return
 
def main():   
 
    username = 'houshuang_disaster' # get a Twitter user name #
    password = 'alabast' # get a Twitter password #

    global db
    global cursor
     
    #db = MySQLdb.connect (host = ##,
    #    user = ##,
    #    passwd = ##,
    #    db = ##)
    #cursor = db.cursor ()
    db = MockDB()
    cursor = db 
    
    listener = StreamWatcherListener(username, password)
    stream = tweepy.Stream(username,
                           password,
                           listener,
                           timeout = None)
    track_list = [k for k in PRIMARY_TRACK_LIST.split(',')]
    stream.filter(track = track_list)
 
if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        cursor.close()
        db.close()
        print '\nCiao!'
