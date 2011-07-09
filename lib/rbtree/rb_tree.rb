# Sorted hash that supports multiple keys for its values.
class RBTree
  include Enumerable
  
  # The red-black tree backing this store.
  attr_reader :tree
  
  # The value returned when trying to read keys that don't exist in the tree.
  def default(key = nil)
    @default_proc ? @default_proc.call(tree, key) : @default
  end
  
  # The value returned when trying to read keys that don't exist in the tree.
  def default=(new_default)
    @default_proc = nil
    @default = new_default
  end
  
  # Block called when trying to read keys that don't exist in the tree.
  attr_reader :default_proc
  
  # Block called when trying to read keys that don't exist in the tree.
  def default_proc=(new_proc)
    @default = nil
    @default_proc = new_proc
  end
  
  # Block used to implement custom comparisons.
  attr_reader :cmp_proc
  
  def initialize(default = nil, &default_proc)
    raise ArgumentError, "wrong number of arguments" if default && default_proc
    @default = default
    @default_proc = default_proc
    @cmp_proc = nil
    @lock_count = 0
    @tree = RBTree::Tree.new
  end

  def initialize_copy(source)
    super
    @tree = source.tree.dup
    @lock_count = 0
  end
  
  def self.[](*key_values)
    if key_values.length == 1
      hash = key_values.first
      unless hash.respond_to? :values_at
        raise ArgumentError, "expected a Hash-like argument"
      end
      tree = self.new
      begin
        hash.each { |k, v| tree[k] = v }
      rescue NoMethodError
        raise ArgumentError, "expected a Hash-like argument"
      end
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
  
  # Rejects changes while this method's block is executed.
  def lock_changes
    begin
      @lock_count += 1
      yield
    ensure
      @lock_count -= 1
    end
  end
  private :lock_changes
  
  def lower_bound(key)
    @tree.lower_bound(key).to_a
  end
  
  def upper_bound(key)
    @tree.upper_bound(key).to_a
  end
  
  def bound(lower_key, upper_key = nil)
    if upper_key
      node = @tree.lower_bound lower_key
    else
      node = @tree.minimum
      upper_key = lower_key
    end
    return block_given? ? self : [] unless node

    result = []
    lock_changes do
      if @cmp_proc
        # Slow path
        until node.nil? || @cmp_proc.call(node.key, upper_key) > 0
          if block_given?
            yield node.to_a
          else
            result << node.to_a
          end
          node = @tree.successor node
        end
      else
        # Fast path.
        until node.nil? || node.key > upper_key
          if block_given?
            yield node.to_a
          else
            result << node.to_a
          end
          node = @tree.successor node
        end
      end
    end
    block_given? ? self : result
  end
  
  def to_rbtree
    self
  end
  
  def readjust(*proc_arg, &new_cmp_proc)
    raise TypeError, 'cannot modify rbtree in iteration' if @lock_count > 0
    
    if new_cmp_proc
      cmp_proc = new_cmp_proc
      unless proc_arg.empty?
        raise ArgumentError, "expected 0 arguments when given a block"
      end
    else
      unless proc_arg.length <= 1
        raise ArgumentError, "expected 1 arguments (given #{proc_arg.length})"        
      end
      unless proc_arg.first.respond_to?(:call) || proc_arg.first.nil?
        raise TypeError, "expected a proc argument"
      end
      cmp_proc = proc_arg.first
    end
    
    lock_changes do
      if cmp_proc
        new_tree = RBTree::TreeCmp.new(&cmp_proc)
      else
        new_tree = RBTree::Tree.new
      end
      
      @tree.inorder do |node|
        new_tree.insert new_tree.node(node.key, node.value)
      end
      @tree = new_tree
      @cmp_proc = cmp_proc
    end
  end
  
  def replace(other)
    raise TypeError, 'cannot modify rbtree in iteration' if @lock_count > 0
    unless other.kind_of? RBTree
      raise TypeError, "expected RBTree, got #{other.class}"
    end
    
    @tree = other.tree.dup
    @default_proc = other.default_proc
    @default = other.default
    @cmp_proc = other.cmp_proc
  end
end

# :nodoc: array behavior
class RBTree
  # The [key, value] for the smallest key in the tree.
  def first
    node = @tree.minimum
    node.nil? ? default : node.to_a
  end
  
  # The [key, value] for the largest key in the tree.
  def last
    node = @tree.maximum
    node.nil? ? default : node.to_a
  end
  
  # Removes the largest key in the tree.
  def pop
    return default if (node = @tree.maximum).nil? 
    @tree.delete node
    node.to_a
  end
  
  # Removes the smallest key in the tree.
  def shift
    return default if (node = @tree.minimum).nil? 
    @tree.delete node
    node.to_a
  end
end

# :nodoc: hash behavior
class RBTree
  # See Hash#[]
  def [](key)
    node = tree.search key
    node ? node.value : default(key)
  end
  
  # See Hash#[]=
  def []=(key, value)
    raise TypeError, 'cannot modify rbtree in iteration' if @lock_count > 0

    key = key.clone.freeze if key.kind_of? String
    @tree.insert(@tree.node(key, value)).value = value
  end
  
  # See Hash#size
  def size
    @tree.size
  end
  
  # See Hash#empty
  def empty?
    @tree.empty?
  end

  # See Hash#clear  
  def clear
    @tree = RBTree::Tree.new
  end
  
  # See Hash#==
  def ==(other)
    return false unless other.instance_of?(RBTree)
    return false unless other.cmp_proc == @cmp_proc
    return false unless other.size == size

    lock_changes do
      other_tree = other.tree
      other_node = other_tree.minimum
      @tree.inorder do |node|
        return false if node.key != other_node.key ||
                        node.value != other_node.value
        other_node = other_tree.successor other_node
      end
    end
    true
  end
  
  # See Hash#each
  def each
    if block_given?
      lock_changes do
        @tree.inorder { |node| yield *node.to_a }
      end
    else
      Enumerator.new self, :each
    end
  end
  alias :each_pair :each
  
  # See Hash#reverse_each
  def reverse_each
    if block_given?
      lock_changes do
        @tree.reverse_inorder { |node| yield *node.to_a }
      end
    else
      Enumerator.new self, :reverse_each
    end
  end
  
  
  # See Hash#index
  def index(value)
    @tree.inorder { |node| return node.key if node.value == value }
    nil
  end
  
  # See Hash#fetch
  def fetch(key, *default)
    if default.length > 1
      raise ArgumentError, "expected at most 1 default, got #{default.length}"
    end
    if default.length == 1 && block_given?
      $stderr << "warning: block supersedes default value argument"
    end
    
    node = tree.search key
    return node.value if node
    if block_given?
      yield key
    else
      if default.length == 1
        default.first
      else
        raise IndexError, 'key not found'
      end
    end
  end
  
  # See Hash#delete
  def delete(key)
    node = @tree.search key
    unless node
      return block_given? ? yield : nil
    end
    @tree.delete node
    node.value
  end
  
  # See Hash#delete_if
  def delete_if
    dead_nodes = []
    if block_given?
      lock_changes do
        @tree.inorder do |node|
          dead_nodes << node if yield node.key, node.value
        end
        dead_nodes.each { |node| @tree.delete node }
      end
      self
    else
      Enumerator.new self, :each
    end
  end
  
  # See Hash#reject!
  def reject!
    dead_nodes = []
    if block_given?
      lock_changes do
        @tree.inorder do |node|
          dead_nodes << node if yield node.key, node.value
        end
        dead_nodes.each { |node| @tree.delete node }
      end
      dead_nodes.empty? ? nil : self
    else
      Enumerator.new self, :each
    end
  end
  
  # See Hash#reject
  def reject(&block)
    copy = self.dup
    copy.reject!(&block)
    # NOTE: the correct answer should be "copy", but we're copying RBTree
    #       bug-for-bug
    # copy
  end
  
  # See Hash#each_key.
  def each_key
    if block_given?
      lock_changes do
        @tree.inorder { |node| yield node.key }
      end
    else
      Enumerator.new self, :each_key
    end
  end

  # See Hash#each_value.
  def each_value
    if block_given?
      lock_changes do
        @tree.inorder { |node| yield node.value }
      end
    else
      Enumerator.new self, :each_value
    end
  end
  
  # See Hash#keys.
  def keys
    result = Array.new
    lock_changes do
      @tree.inorder { |node| result << node.key }
    end
    result
  end
  
  # See Hash#values.
  def values
    result = Array.new
    lock_changes do
      @tree.inorder { |node| result << node.value }
    end
    result
  end
  
  # See Hash#has_key?
  def has_key?(key)
    !!@tree.search(key)
  end
  
  # See Hash#has_value?
  def has_value?(value)
    lock_changes do
      tree.inorder { |node| return true if value == node.value }
    end
    false
  end
  
  # See Hash#invert
  def invert
    tree = RBTree.new
    @tree.inorder { |node| tree[node.value] = node.key }
    tree
  end
  
  # See Hash#values_at
  def values_at(*keys)
    keys.map { |key| self[key] }
  end
  
  # See Hash#merge!
  def merge!(other)
    unless other.instance_of? RBTree
      raise TypeError, "wrong argument type #{other.class} (expected RBTree)"
    end
    
    if block_given?
      other.tree.inorder do |other_node|
        key = other_node.key
        if node = @tree.search(key)
          node.value = yield key, node.value, other_node.value
        else
          self[key] = other_node.value
        end
      end
    else
      other.tree.inorder { |node| self[node.key] = node.value }
    end
    self
  end
  alias :update :merge!
  
  # See Hash#merge
  def merge(other)
    copy = self.dup
    copy.merge! other
    copy
  end
  
  # :nodoc:
  def to_s
    to_a.to_s
  end
  
  # A new Hash with the same contents and defaults as this RBTree instance.
  def to_hash
    if @default_proc && !Hash.method_defined?(:default_proc=)
      # Slow path for default block and Ruby 1.8.7
      hash = Hash.new &@default_proc
      each { |key, value| hash[key] = value }
      return hash
    end

    hash = Hash[to_a]
    if @default_proc
      hash.default_proc = @default_proc if hash.respond_to? :default_proc=
    else
      hash.default = @default
    end
    hash
  end
  
  # :nodoc:
  def inspect
    contents = map { |k, v|
      k_inspect = k.equal?(self) ? '#<RBTree: ...>' : k.inspect
      v_inspect = v.equal?(self) ? '#<RBTree: ...>' : v.inspect
      "#{k_inspect}=>#{v_inspect}"
    }.join(', ')
    default_inspect = default.equal?(self) ? '#<RBTree: ...>' : default.inspect
    "#<RBTree: {#{contents}}, default=#{default_inspect}, cmp_proc=#{@cmp_proc.inspect}>"
  end
  
  def pretty_print(q)
    q.group(1, '#<RBTree: ', '>') do
      q.pp_hash self
      q.text ','
      q.breakable ' '
      q.text 'default='
      q.pp default
      q.text ','
      q.breakable ' '
      q.text 'cmp_proc='
      q.pp cmp_proc
    end
  end
  
  def pretty_print_cycle(q)
    q.text '"#<RBTree: ...>"'
  end
end
