require 'helper'

# The code below is lifted from the rbtree gem. Here is its LICENSE.
#
# Copyright (c) 2002-2004, 2007, 2009-2010 OZAWA Takuma
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

class MultiRBTreeTest < Test::Unit::TestCase
  def setup
    @rbtree = MultiRBTree[*%w(a A b B b C b D c C)]
  end

  def test_create
    assert_equal(%w(a A b B b C b D c C), @rbtree.to_a.flatten)

    assert_equal(MultiRBTree[*%w(a A)], MultiRBTree[RBTree[*%w(a A)]])
    assert_raises(TypeError) {
      RBTree[MultiRBTree[*%w(a A)]]
    }
  end

  def test_size
    assert_equal(5, @rbtree.size)
  end

  def test_clear
    @rbtree.clear
    assert_equal(0, @rbtree.size)
  end

  def test_empty
    assert_equal(false, @rbtree.empty?)
    @rbtree.clear
    assert_equal(true, @rbtree.empty?)
  end

  def test_to_a
    assert_equal([%w(a A), %w(b B), %w(b C), %w(b D), %w(c C)],
                 @rbtree.to_a)
  end

  def test_to_s
    if RUBY_VERSION < "1.9"
      assert_equal("aAbBbCbDcC", @rbtree.to_s)
    else
      expected = "[[\"a\", \"A\"], [\"b\", \"B\"], [\"b\", \"C\"], \[\"b\", \"D\"], [\"c\", \"C\"]]"
      assert_equal(expected, @rbtree.to_s)
    end
  end

  def test_to_hash
    assert_raises(TypeError) {
      @rbtree.to_hash
    }
  end

  def test_to_rbtree
    assert_equal(@rbtree, @rbtree.to_rbtree)
  end

  def test_aref
    assert_equal("B", @rbtree["b"])
  end

  def test_aset
    @rbtree["b"] = "A"
    assert_equal("B", @rbtree["b"])
    assert_equal(%w(a A b B b C b D b A c C), @rbtree.to_a.flatten)
  end

  def test_equal
    assert_equal(true, MultiRBTree[*%w(a A b B b C b D c C)] == @rbtree)
    assert_equal(true, RBTree[*%w(a A)] == MultiRBTree[*%w(a A)])
    assert_equal(true, MultiRBTree[*%w(a A)] == RBTree[*%w(a A)])
  end

  def test_replace
    assert_equal(RBTree[*%w(a A)],
                 MultiRBTree[*%w(a A)].replace(RBTree[*%w(a A)]))
    assert_raises(TypeError) {
      RBTree[*%w(a A)].replace(MultiRBTree[*%w(a A)])
    }
  end

  def test_update
    assert_equal(MultiRBTree[*%w(a A b B)],
                 MultiRBTree[*%w(a A)].update(RBTree[*%w(b B)]))
    assert_raises(TypeError) {
      RBTree[*%w(a A)].update(MultiRBTree[*%w(b B)])
    }
  end

  def test_clone
    assert_equal(@rbtree, @rbtree.clone)
  end

  def test_each
    ret = []
    @rbtree.each {|k, v|
      ret << k << v
    }
    assert_equal(%w(a A b B b C b D c C), ret)
  end

  def test_delete
    @rbtree.delete("b")
    assert_equal(4, @rbtree.size)
    assert_equal(%w(a A b C b D c C), @rbtree.to_a.flatten)

    @rbtree.delete("b")
    assert_equal(3, @rbtree.size)
    assert_equal(%w(a A b D c C), @rbtree.to_a.flatten)

    @rbtree.delete("b")
    assert_equal(2, @rbtree.size)
    assert_equal(%w(a A c C), @rbtree.to_a.flatten)
  end

  def test_delete_if
    @rbtree.delete_if {|k, v| k == "b" }
    assert_equal(%w(a A c C), @rbtree.to_a.flatten)
  end

  def test_inspect
    assert_equal(%(#<MultiRBTree: {"a"=>"A", "b"=>"B", "b"=>"C", "b"=>"D", "c"=>"C"}, default=nil, cmp_proc=nil>),
                 @rbtree.inspect)
  end

  def test_readjust
    @rbtree.readjust {|a, b| b <=> a }
    assert_equal(%w(c C b B b C b D a A), @rbtree.to_a.flatten)
  end

  def test_marshal
    assert_equal(@rbtree, Marshal.load(Marshal.dump(@rbtree)))
  end

  def test_lower_bound
    assert_equal(%w(b B), @rbtree.lower_bound("b"))
  end

  def test_upper_bound
    assert_equal(%w(b D), @rbtree.upper_bound("b"))
  end

  def test_bound
    assert_equal(%w(b B b C b D), @rbtree.bound("b").flatten)
  end

  def test_first
    assert_equal(%w(a A), @rbtree.first)
  end

  def test_last
    assert_equal(%w(c C), @rbtree.last)
  end

  def test_shift
    assert_equal(%w(a A), @rbtree.shift)
    assert_equal(4, @rbtree.size)
    assert_equal(nil, @rbtree["a"])
  end

  def test_pop
    assert_equal(%w(c C), @rbtree.pop)
    assert_equal(4, @rbtree.size)
    assert_equal(nil, @rbtree["c"])
  end

  def test_has_key
    assert_equal(true,  @rbtree.has_key?("b"))
  end

  def test_has_value
    assert_equal(true, @rbtree.has_value?("B"))
    assert_equal(true, @rbtree.has_value?("C"))
    assert_equal(true, @rbtree.has_value?("D"))
  end

  def test_select
    assert_equal(%w(b B b C b D), @rbtree.select {|k, v| k == "b"}.flatten)
    assert_equal(%w(b C c C),     @rbtree.select {|k, v| v == "C"}.flatten)
  end

  def test_values_at
    assert_equal(%w(A B), @rbtree.values_at("a", "b"))
  end

  def test_invert
    assert_equal(MultiRBTree[*%w(A a B b C b C c D b)], @rbtree.invert)
  end

  def test_keys
    assert_equal(%w(a b b b c), @rbtree.keys)
  end

  def test_values
    assert_equal(%w(A B C D C), @rbtree.values)
  end

  def test_index
    assert_equal("b", @rbtree.index("B"))
    assert_equal("b", @rbtree.index("C"))
    assert_equal("b", @rbtree.index("D"))
  end
end
