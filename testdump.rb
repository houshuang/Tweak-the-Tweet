require 'filelib'
dumper = Filelib::Dumper.new(1)

t = Time.now
20000.times do |a|
  1000000.times {}
  dumper.add_to_cache(a)
  puts "."
end

dumper.ensure_flush