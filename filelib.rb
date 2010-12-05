# functions for writing to marshal dump file and reading

require 'fileutils'

module Filelib

  class Dumper
    def initialize(seconds)
      @t = Time.now
      @interval = seconds
      @cache = Array.new
    end
    
    def flush
      File.open("data/#{Time.now.to_i.to_s}",'w') { |f| Marshal.dump(@cache, f) }
      File.open("data2/#{Time.now.to_i.to_s}",'w') { |f| Marshal.dump(@cache, f) }
      puts "="
    end

    def ensure_flush
      flush if @cache.size > 0
    end

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
    def readchunk
      file = "data/" + Dir.entries("data/")[2]
      content = Marshal.load(File.read(file))
      FileUtils::rm(file)
      return content
    end
    
    def morechunks?
      Dir.entries("data/").size > 2
    end
  end

end