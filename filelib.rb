# functions for writing to marshal dump file and reading

module Filelib

  class Dumper
    def initialize(seconds)
      @t = Time.now
      @interval = seconds
      @cache = Array.new
    end
    
    def flush
      File.open(Time.now.to_i.to_s,'w') { |f| Marshal.dump(obj, f) }
      puts "."
    end

    def add_to_cache(obj)
      @cache << obj
      if @t + @interval < Time.now
        @t = Time.now
        flush
        @cache = Array.new
      end
    end

  end
end