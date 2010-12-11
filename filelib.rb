# functions for writing to marshal dump file and reading

require 'fileutils'

module Filelib

  class Dumper

    # initialize a dumper, and specify to dump data every X seconds (every X seconds it dumps
    # all data in cache to a time_stamped file) 
    def initialize(seconds)
      @t = Time.now
      @interval = seconds
      @cache = Array.new
    end
    
    # currently we write to both data and data2, because all tweets in data are deleted
    # after reading. for testing, it's great to be able to copy data2/* data, and rerun
    # the processdump script, without having to create new actual tweets.
    # This is also a great way of creating test data of specific tweets, for example with
    # embedded location data, to help develop the location parser.
    def flush
      File.open("data/#{Time.now.to_i.to_s}",'w') { |f| Marshal.dump(@cache, f) }
      File.open("data2/#{Time.now.to_i.to_s}",'w') { |f| Marshal.dump(@cache, f) }
      puts "="
    end

    # call this at the end of the program to make sure there is no unwritten data
    def ensure_flush
      flush if @cache.size > 0
    end

    # add a Ruby object to cache, to be written on the next flush. This could theoretically be
    # any object, in this case it's used for Tweet objects
    def add_to_cache(obj)
      @cache << obj
      if @t + @interval < Time.now
        @t = Time.now
        flush if @cache.size > 0
        @cache = Array.new
      end
    end

  end

  class Reader
    
    # opens the next available file in the data directory, unpacks and returns an array of objects
    # (in this case representing individual tweeets), and deletes the file.
    # currently the only way the script knows that a file has been read, is by deleting this. it keeps
    # the logic very simple, but might raise some concerns. For testing, I write to two directories,
    # thus keeping a "backup" in data2/
    def readchunk
      file = "data/" + Dir.entries("data/")[2]
      content = Marshal.load(File.read(file))
      FileUtils::rm(file)
      return content
    end
    
    # checks if there are more files, useful for a while morechunks? loop
    def morechunks?
      Dir.entries("data/").size > 2
    end
  end

end