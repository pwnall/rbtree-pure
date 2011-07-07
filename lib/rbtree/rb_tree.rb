# Sorted hash that supports multiple keys for its values.
class RBTree
  include Enumerable
  
  # The red-black tree backing this store.
  attr_reader :tree
  
  # The value returned when trying to read keys that don't exist in the tree.
  attr_reader :default
  
  # The value returned when trying to read keys that don't exist in the tree.
  def default=(new_default)
    @default_proc = nil
    @default = new_default
  end
  
  # Block called when trying to read keys that don't exist in the tree.
  attr_reader :default_proc
  
  # Block used to implement custom comparisons.
  attr_reader :cmp_proc
  
  def initialize(default = nil, &default_proc)
    raise ArgumentError, "wrong number of arguments" if default && default_proc
    @default = default
    @default_proc = default_proc
    @tree = RBTree::Tree.new
  end
  
  def self.[](*key_values)
    if key_values.length == 1
      tree = self.new
      key_values.first.each { |k, v| tree[k] = v }
      return tree
    end
    
    if key_values.length % 2 == 1
      raise ArgumentError, 'odd number of arguments for RBTree'
    end
    
    tree = self.new
    0.upto(key_values.length / 2 - 1) do |i|
      tree[key_values[i * 2]] = key_values[i * 2 + 1]
    end
    tree
  end
  
  def [](key)
    node = tree.search key
    return node.value unless node.nil?
    @default_proc ? @default_proc.call(key) : @default
  end
  
  def []=(key, value)
    key = key.clone.freeze unless key.frozen?
    @tree.insert(@tree.node(key, value)).value = value
  end
  
  def size
    @tree.size
  end
  
  def empty?
    @tree.empty?
  end
  
  def clear
    @tree = RBTree::Tree.new
  end
  
  def ==(other)
    return false unless other.instance_of?(RBTree::Tree)
    
    # TODO: consider making this not horribly slow
    to_a == other.to_a
  end
  
  alias :eql? :==
  
  def index(key)
    node = tree.search key
    node && node.value
  end
  
  def fetch(key, *default)
    if default.length > 1
      raise ArgumentError, "expected at most 1 default, got #{default.length}"
    end
    if default.length == 1 && block_given?
      raise ArgumentError, 'expected either 1 default value or a block'
    end
    
    node = tree.search key
    return node.value unless node.nil?
    if block_given?
      yield key
    else
      if default.length == 1
        default
      else
        raise IndexError, 'key not found'
      end
    end
  end
  
  def delete(key)
    node = @tree.search key
    return nil if node.nil?
    @tree.delete node
    node.value
  end
  
  # :nodoc:
  def each
    if block_given?
      @tree.inorder { |node| yield [node.key, node.value] }
    else
      # TODO(pwnall): Enumerator
      raise 'Enumerator not implemented'
    end
  end
  alias :each_pair :each
  
  # :nodoc:
  def reverse_each
    if block_given?
      @tree.reverse_inorder { |node| yield [node.key, node.value] }
    else
      # TODO(pwnall): Enumerator
      raise 'Enumerator not implemented'
    end
  end

  # See Hash#each_key.
  def each_key
    if block_given?
      @tree.inorder { |node| yield node.key }
    else
      # TODO(pwnall): Enumerator
      raise 'Enumerator not implemented'
    end
  end

  # See Hash#each_value.
  def each_value
    if block_given?
      @tree.inorder { |node| yield node.value }
    else
      # TODO(pwnall): Enumerator
      raise 'Enumerator not implemented'
    end
  end
  
  # See Hash#keys.
  def keys
    map(&:first)
  end
  
  # See Hash#values.
  def values
    map(&:last)
  end
  
  # See Hash#has_key?
  def has_key?(key)
    !@tree.search(key).nil?
  end
  
  # See Hash#has_value?
  def has_value?(value)
    tree.inorder { |node| return true if value == node.value }
    false
  end
  
  # The [key, value] for the smallest key in the tree.
  def first
    node = @tree.minimum
    node.nil? ? (@default_proc ? @default_proc.call(nil) : @default) : node.to_a
  end
  
  # The [key, value] for the largest key in the tree.
  def last
    node = @tree.maximum
    node.nil? ? (@default_proc ? @default_proc.call(nil) : @default) : node.to_a
  end
  
  # Removes the largest key in the tree.
  def pop
    @tree.delete(@tree.maximum).to_a
  end
  
  # Removes the smallest key in the tree.
  def shift
    @tree.delete(@tree.minimum).to_a
  end
  
  # :nodoc:
  def to_s
    self.map { |k, v| k.to_s + v.to_s }.join
  end
  
  def to_hash
    Hash[to_a]
  end
  
  # :nodoc:
  def inspect
    contents = map { |k, v| "#{k.inspect}=>#{v.inspect}" }.join(', ')
    "#<RBTree: {#{contents}}, default=#{@default.inspect}, cmp_proc=#{@cmp_proc.inspect}>"
  end
end
