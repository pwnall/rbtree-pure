# :nodoc: namespace
class RBTree

# A node in the red-black tree.
#
# Nodes should only be manipulated directly by the RedBlackTree class.
class Node
  attr_accessor :key
  attr_accessor :value

  attr_accessor :color
  attr_accessor :left
  attr_accessor :right
  attr_accessor :parent

  # Creates a new node.
  #
  # New tree nodes are red by default.
  def initialize(key, value, guard)
    @color = :red
    @key = key
    @value = value
    @left = @right = @parent = guard
  end

  # True for black nodes.
  def black?
    @color == :black
  end

  # True for red nodes.
  def red?
    @color == :red
  end

  # Returns an array of the node's [key, value].
  #
  # This method is used for nodes in a RBTree's tree.
  def to_a
    [@key, @value]
  end

  # Returns an array of the node's [key, first value].
  #
  # This method is used for nodes in a MultiRBTree's tree.
  def to_single_a
    [@key, @value.first]
  end

  def inspect
    <<ENDI
<RBTree::Node (#{@color}) #{@key.inspect} -> #{@value.inspect}
  Left: [#{@left.inspect.gsub!("\n", "\n  ")}]
  Right: [#{@right.inspect.gsub!("\n", "\n  ")}]>
ENDI
  end
end  # class RBTree::Node

end  # namespace RBTree
