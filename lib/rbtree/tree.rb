# :nodoc: namespace
class RBTree

# Red-black tree implementation based on "Introduction to Algorithms" by CLRS.
#
# Instances of this class are not thread-safe. However, using different
# instances in different threads is OK, unlike the original RedBlackTree class.
class Tree
  # The tree's root node.
  attr_reader :root
  
  # The number of nodes in the tree.
  attr_reader :size

  # Creates a new tree.
  def initialize
    @guard = GuardNode.new
    @size = 0
    @root = @guard
  end

  # Creates a new node holding a given key and value.
  def node(key, value)
    RBTree::Node.new key, value, @guard
  end

  # Adds a new Node to the tree.
  #
  # Returns the given node, if it was inserted into the tree. If a node with
  # same key already existed, that node is returned instead, and the given node
  # is not inserted into the tree.
  def insert(node)
    x = insert_helper node
    return x unless x == node

    x.color = :red
    while x != @root && x.parent.color == :red
      if x.parent == x.parent.parent.left
        y = x.parent.parent.right
        if !y.nil? && y.color == :red
          x.parent.color = :black
          y.color = :black
          x.parent.parent.color = :red
          x = x.parent.parent
        else
          if x == x.parent.right
            x = x.parent
            left_rotate x
          end
          x.parent.color = :black
          x.parent.parent.color = :red
          right_rotate x.parent.parent
        end
      else
        y = x.parent.parent.left
        if !y.nil? && y.color == :red
          x.parent.color = :black
          y.color = :black
          x.parent.parent.color = :red
          x = x.parent.parent
        else
          if x == x.parent.left
            x = x.parent
            right_rotate x
          end
          x.parent.color = :black
          x.parent.parent.color = :red
          left_rotate x.parent.parent
        end
      end
    end
    @root.color = :black
    node
  end

  # Removes a node from the tree.
  def delete(z)
    y = (z.left.nil? || z.right.nil?) ? z : successor(z)
    x = y.left.nil? ? y.right : y.left
    x.parent = y.parent

    if y.parent.nil?
      @root = x
    else
      if y == y.parent.left
        y.parent.left = x
      else
        y.parent.right = x
      end
    end

    z.key = y.key if y != z

    if y.color == :black
      delete_fixup(x)
    end

    @size -= 1
    y
  end

  # The node with lowest key in the subtree rooted at the given node.
  def minimum(x = root)
    while !x.left.nil?
      x = x.left
    end
    x
  end

  # The node with the highest key in the subtree rooted at the given node.
  def maximum(x = root)
    while !x.right.nil?
      x = x.right
    end
    x
  end

  # The node with the lowest key that is higher than the given node's key.
  def successor(x)
    return minimum(x.right) if !x.right.nil?
    
    y = x.parent
    while !y.nil? && x == y.right
      x = y
      y = y.parent
    end
    y
  end

  # The node with the highest key that is lower than the given node's key.
  def predecessor(x)
    return maximum(x.left) if !x.left.nil?
    
    y = x.parent
    while !y.nil? && x == y.left
      x = y
      y = y.parent
    end
    y
  end

  # Yields all nodes in the given node's subtree, in ascending key order.
  def inorder(x = root)
    x = self.minimum
    until x.nil?
      yield x
      x = successor x
    end
  end

  # Yields all nodes in the given node's subtree, in descending key order.
  def reverse_inorder(x = root)
    x = self.maximum
    until x.nil?
      yield x
      x = predecessor x
    end
  end

  def search(key, x = root)
    until x.nil? || x.key == key
      x = (key < x.key) ? x.left : x.right
    end
    x
  end

  # True if the tree has no nodes in it.
  def empty?
    @root.nil?
  end

  # Number of black nodes on each path from the given node to a leaf.
  #
  # Red-black trees have the same number of black nodes on all paths from the
  # root to leaves, so this function is well defined.
  def black_height(x = root)
    height = 0
    while !x.nil?
      x = x.left
      height +=1 if x.nil? || x.black?
    end
    height
  end

private

  def left_rotate(x)
    raise "x.right is nil!" if x.right.nil?
    y = x.right
    x.right = y.left
    y.left.parent = x if !y.left.nil?
    y.parent = x.parent
    if x.parent.nil?
      @root = y
    else
      if x == x.parent.left
        x.parent.left = y
      else
        x.parent.right = y
      end
    end
    y.left = x
    x.parent = y
  end

  def right_rotate(x)
    raise "x.left is nil!" if x.left.nil?
    y = x.left
    x.left = y.right
    y.right.parent = x if !y.right.nil?
    y.parent = x.parent
    if x.parent.nil?
      @root = y
    else
      if x == x.parent.left
        x.parent.left = y
      else
        x.parent.right = y
      end
    end
    y.right = x
    x.parent = y
  end

  def insert_helper(z)
    y = @guard
    x = @root
    key = z.key
    until x.nil?
      y = x
      unless cmp = x.key <=> key
        raise ArgumentError,
              "comparison of #{x.key.class} with #{key.inspect} failed"
      end
      if cmp > 0
        x = x.left
      elsif cmp < 0
        x = x.right
      else
        return x
      end
    end
    z.parent = y
    if y.nil?
      @root = z
    else
      key < y.key ? y.left = z : y.right = z
    end
    @size += 1
    z
  end

  def delete_fixup(x)
    while x != root && x.color == :black
      if x == x.parent.left
        w = x.parent.right
        if w.color == :red
          w.color = :black
          x.parent.color = :red
          left_rotate x.parent
          w = x.parent.right
        end
        if w.left.color == :black && w.right.color == :black
          w.color = :red
          x = x.parent
        else
          if w.right.color == :black
            w.left.color = :black
            w.color = :red
            right_rotate w
            w = x.parent.right
          end
          w.color = x.parent.color
          x.parent.color = :black
          w.right.color = :black
          left_rotate x.parent
          x = root
        end
      else
        w = x.parent.left
        if w.color == :red
          w.color = :black
          x.parent.color = :red
          right_rotate x.parent
          w = x.parent.left
        end
        if w.right.color == :black && w.left.color == :black
          w.color = :red
          x = x.parent
        else
          if w.left.color == :black
            w.right.color = :black
            w.color = :red
            left_rotate w
            w = x.parent.left
          end
          w.color = x.parent.color
          x.parent.color = :black
          w.left.color = :black
          right_rotate x.parent
          x = root
        end
      end
    end
    x.color = :black
  end
end  # class RBTree::Tree

end  # class RBTree
