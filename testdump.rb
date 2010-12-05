def dump(obj)
  File.open(Time.now.to_i.to_s,'w') { |f| Marshal.dump(obj, f) }
  puts "."
end

cache = Array.new

t = Time.now
20000.times do |a|
  1000000.times {}
  cache << a
  if t + 2 < Time.now
    t = Time.now
    dump(cache)
    cache = Array.new
  end
end