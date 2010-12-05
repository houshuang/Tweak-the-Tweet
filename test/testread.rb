require '../filelib'

r = Filelib::Reader.new
p r.morechunks?
p r.readchunk