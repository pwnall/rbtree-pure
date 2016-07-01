require 'helper'

require 'byebug'

class RBTreeCJHTest < Test::Unit::TestCase
  def setup
    @rbtree = RBTree[*%w(b B d D a A c C)]
  end

  def test_hash_merge
    rbtree = RBTree.new
    rbtree["e"] = "E"

    ret = @rbtree.merge({'e' => 'E'})
    assert_equal(RBTree[*%w(a A b B c C d D e E)], ret)

    assert_equal(4, @rbtree.size)
  end
end
