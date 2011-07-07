# :nodoc: namespace
class RBTree

# A node in the red-black tree.
#
# Nodes should only be manipulated directly by the RedBlackTree class.
class Node
  attr_reader :key
  attr_accessor :value

  attr_accessor :color
  attr_accessor :left
  attr_accessor :right
  attr_accessor :parent

  # Creates a new node.
  #
  # New tree nodes are red by default. The guard 
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
  def to_a
    [@key, @value]
  end
  
  def inspect
    <<ENDI
<RBTree::Node (#{@color}) #{@value.inspect}
  Left: [#{@left.inspect.gsub!("\n", "\n  ")}]
  Right: [#{@right.inspect.gsub!("\n", "\n  ")}]>
ENDI
  end
end  # class RBTree::Node
  
end  # namespace RBTree
