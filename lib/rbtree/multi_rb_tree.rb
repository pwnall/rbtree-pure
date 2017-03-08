# Sorted hash that supports multiple keys for its values.
class MultiRBTree < RBTree
  def initialize(default = nil, &default_proc)
    super(default, &default_proc)
    @size = 0
  end

  def lower_bound(key)
    node = @tree.lower_bound(key)
    [node.key, node.value.first]
  end

  def upper_bound(key)
    node = @tree.lower_bound(key)
    [node.key, node.value.last]
  end

  def bound(lower_key, upper_key = nil)
    result = []
    bound_nodes lower_key, upper_key do |node|
      if block_given?
        node.value.each { |value| yield node.key, value }
      else
        node.value.each { |value| result << [node.key, value] }
      end
    end
    block_given? ? self : result
  end

  def to_rbtree
    self
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
    @size = other.size

    unless other.instance_of? MultiRBTree
      # Wrap values in arrays to convert RBTree -> MultiRBTree.
      @tree.inorder do |node|
        node.value = [node.value]
      end
    end

    self
  end
end

# :nodoc: array behavior
class MultiRBTree
  # The [key, value] for the smallest key in the tree.
  def first
    node = @tree.minimum
    node.nil? ? default : [node.key, node.value.first]
  end

  # The [key, value] for the largest key in the tree.
  def last
    node = @tree.maximum
    node.nil? ? default : [node.key, node.value.last]
  end

  # Removes the largest key in the tree.
  def pop
    return default if (node = @tree.maximum).nil?
    value = node.value.pop
    @tree.delete node if node.value.empty?
    @size -= 1
    [node.key, value]
  end

  # Removes the smallest key in the tree.
  def shift
    return default if (node = @tree.minimum).nil?
    value = node.value.shift
    @tree.delete node if node.value.empty?
    @size -= 1
    [node.key, value]
  end
end

# :nodoc: hash behavior
class MultiRBTree
  # See Hash#[]
  def [](key)
    node = tree.search key
    node ? node.value.first : default(key)
  end

  # See Hash#[]=
  def []=(key, value)
    raise TypeError, 'cannot modify rbtree in iteration' if @lock_count > 0

    key = key.clone.freeze if key.kind_of? String
    @tree.insert(@tree.node(key, [])).value << value
    @size += 1
    value
  end

  # See Hash#size
  attr_reader :size

  # See Hash#empty
  def empty?
    @tree.empty?
  end

  # See Hash#clear
  def clear
    super
    @size = 0
  end

  # See Hash#each
  def each
    if block_given?
      lock_changes do
        @tree.inorder do |node|
          node.value.each { |value| yield node.key, value }
        end
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
        @tree.reverse_inorder do |node|
          node.value.each { |value| yield node.key, value }
        end
      end
    else
      Enumerator.new self, :reverse_each
    end
  end

  # See Hash#index
  def index(value)
    each { |k, v| return k if v.include? value }
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
    return node.value.first if node
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
    value = node.value.shift
    @tree.delete node if node.value.empty?
    @size -= 1
    value
  end

  # See Hash#reject!
  def reject!
    if block_given?
      dead_nodes = []
      lock_changes do
        @tree.inorder do |node|
          node.value.reject! do |value|
            @size -= 1 if result = yield(node.key, value)
            result
          end
          dead_nodes << node if node.value.empty?
        end
      end
      dead_nodes.each { |node| @tree.delete node }
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
        @tree.inorder { |node| node.value.each { yield node.key } }
      end
    else
      Enumerator.new self, :each_key
    end
  end


  # See Hash#each_value.
  def each_value
    if block_given?
      lock_changes do
        @tree.inorder { |node| node.value.each { |value| yield value } }
      end
    else
      Enumerator.new self, :each_value
    end
  end

  # See Hash#merge!
  def merge!(other)
    unless other.instance_of? RBTree
      raise TypeError, "wrong argument type #{other.class} (expected RBTree)"
    end

    if block_given?
      other.each do |key, value|
        if node = @tree.search(key)
          self[key] = yield key, node.value.first, value
        else
          self[key] = value
        end
      end
    else
      other.each { |key, value| self[key] = value }
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

  # A new Hash with the same contents and defaults as this RBTree instance.
  def to_hash
    raise TypeError, "can't convert MultiRBTree to Hash"
  end

  # :nodoc:
  def inspect
    contents = map { |k, v|
      k_inspect = k.equal?(self) ? '#<RBTree: ...>' : k.inspect
      v_inspect = v.equal?(self) ? '#<RBTree: ...>' : v.inspect
      "#{k_inspect}=>#{v_inspect}"
    }.join(', ')
    default_inspect = default.equal?(self) ? '#<RBTree: ...>' : default.inspect
    "#<MultiRBTree: {#{contents}}, default=#{default_inspect}, cmp_proc=#{@cmp_proc.inspect}>"
  end

  # :nodoc: custom pp output
  def pretty_print(q)
    q.group(1, "#<#{self.class.name}: ", '>') do
      q.group(1, '{', '}') do
        first = true
        each do |key, value|
          if first
            first = false
          else
            q.text ','
            q.breakable ' '
          end
          q.pp key
          q.text '=>'
          q.pp value
        end
      end
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

  # :nodoc: custom pp output
  def pretty_print_cycle(q)
    q.text '"#<MultiRBTree: ...>"'
  end
end  # class RBTree::MultiRBTree
