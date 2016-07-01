# :nodoc: namespace
class RBTree

# Variant of Tree that uses a custom comparator.
#
# This is the "slow path", whereas Tree uses "fast path" <, > etc.
class TreeCmp < Tree
  # Creates a new tree.
  def initialize(&cmp_proc)
    @cmp_proc = cmp_proc
    @guard = GuardNode.new
    @size = 0
    @root = @guard
  end

  # Returns a node containing the given key or nil if no node contains the key.
  def search(key, node = root)
    until node.nil?
      return node if node.key == key
      node = @cmp_proc.call(key, node.key) < 0 ? node.left : node.right
    end
    nil
  end

  # Returns the node with the smallest key that is >= the given key.
  #
  # Returns nil if called on an empty tree or the guard node.
  def lower_bound(key, node = root)
    return nil if node.nil?
    loop do
      cmp = @cmp_proc.call(key, node.key)
      return node if cmp == 0
      if cmp < 0
        next_node = node.left
        return node if next_node.nil?
      else
        next_node = node.right
        return successor(node) if next_node.nil?
      end
      node = next_node
    end
  end

  # Returns a node with the largest key that is <= then given key.
  #
  # Returns nil if called on an empty tree or the guard node.
  def upper_bound(key, node = root)
    return nil if node.nil?
    loop do
      cmp = @cmp_proc.call(key, node.key)
      return node if cmp == 0
      if cmp < 0
        next_node = node.left
        return predecessor(node) if next_node.nil?
      else
        next_node = node.right
        return node if next_node.nil?
      end
      node = next_node
    end
  end

  def insert_helper(z)
    y = @guard
    x = @root
    key = z.key
    until x.nil?
      y = x
      unless cmp = @cmp_proc.call(x.key, key)
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
      @cmp_proc.call(key, y.key) < 0 ? y.left = z : y.right = z
    end
    @size += 1
    z
  end
end  # class RBTree::TreeCmp

end  # class RBTree
