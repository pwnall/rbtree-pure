require 'helper'

require 'byebug'

class RBTreeCJHTest < Test::Unit::TestCase
  class CIString < String
    def eql? other
      (''+downcase).eql? other.downcase
    end

    def <=>(other)
      # downcase yields a CIString.
      ''+downcase <=> other.downcase
    end
  end

  def setup
    @rbtree = RBTree[*%w(b B d D a A c C).map{|s| CIString.new(s)}]
  end

  def test_eql
    assert_equal('B', @rbtree['b'])
    assert_equal('B', @rbtree['B'])
  end

  def test_hash_merge
    rbtree = RBTree.new
    rbtree["e"] = "E"

    ret = @rbtree.merge({'e' => 'E'})
    assert_equal(RBTree[*%w(a A b B c C d D e E)], ret)

    assert_equal(4, @rbtree.size)
  end
end
