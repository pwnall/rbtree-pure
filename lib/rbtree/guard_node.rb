# :nodoc: namespace
class RBTree
  
# Node instance used as a guard.
class GuardNode < Node
  def initialize
    @color = :black
    @key = nil
    @value = nil
    @left = nil
    @right = nil
    @parent = nil
  end

  def nil?
    true
  end
  
  def to_a
    nil
  end
  
  def inspect
    'RBTree::GuardNode'
  end
end

end  # namespace RBTree
