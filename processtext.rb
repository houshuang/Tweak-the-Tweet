# this is an experiment in processing tweet texts

def process(line)
  tags = Hash.new
  line.split("#").each do |tag| 
    next if tag.size == 0
    tag, desc = tag.split(" ")
    tags[tag] = desc
  end
  p tags
end

File.read("twitter-examples.txt").each do |line|
  process(line)
end