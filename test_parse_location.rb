require 'test/unit'
require 'library'

class TestFilelib < Test::Unit::TestCase

  def test_address_parsing
    @conf = Hash.new
    @conf['city'] = "Toronto"
    loc = location("King Edward 115")
    assert_equal(loc, "43.6913009, -79.3117661")
  end

end
