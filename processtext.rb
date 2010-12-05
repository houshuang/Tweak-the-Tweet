# this is an experiment in processing tweet texts

# produces a hash of all tags, with their description
# ie turns this
# ttt_test #ttt_test2 #damage South tower collapsed #loc 43.634087,-79.341888  #status Dragon attacking castle.
# into this
# {"loc"=>"43.634087,-79.341888", "damage"=>"South tower collapsed", "status"=>"Dragon attacking castle.", "ttt_test"=>"", "ttt_test2"=>""}
def process(line)
  tags = Hash.new  
  line.split("#").each do |tag| 
    next if tag.size == 0
    tag, *desc = tag.split(" ")
    tags[tag] = desc.join(" ")
  end
  puts line
  p tags
end

File.read("twitter-examples.txt").each do |line|
  process(line)
end