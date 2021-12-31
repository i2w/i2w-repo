# frozen_string_literal: true

module I2w
  # a List represents a list of models.  Its source is either an activerecord scope, or an array of records.
  #
  # It can be send a limited number of standard active record query methods to reorder or refine the list.
  # The query is resolved when #each (and to_a) is called.  The resulting contains models that are serialized using a
  # Record::ToHash object.  Repository returns a List object from query methods setup with its model_class
  # and record_to_hash object.
  #
  # By design, you can't perform any further queries using this object, or call any repository methods.  But you
  # can pluck values, use #first and #last, and perform pagination using limit, count, offset and so on.
  #
  # You should use the repository to filter the models that are returned from the db, but in some cases you may want to
  # return a List object that allows filtering, but you should make these methods specific to your domain, and not
  # general such as #where
  #
  # If you want to extend the functionality of the List class, you can easily do this, and then declare the
  # new query as a dependency of your Repository.  If you expect to sometimes populate the query with an array,
  # then also define the equivalent new behaviour in its nested ArraySource class.
  #
  #   class UserList < I2w::List
  #     def admins = new(source.where(admin: true))
  #
  #     class ArraySource < I2w::List::ArraySource
  #       def admins = new(source.select { _1.admin == true })
  #     end
  #   end
  #
  #   class UserRepository < I2w::Repository
  #     dependency :list_class, UserList
  #   end
  class List
    class << self
      alias original_new new

      def new(source, ...)
        source.is_a?(Array) ? ArraySource.new(source, ...) : original_new(source, ...)
      end
    end

    def initialize(source, model_class:, record_to_hash: -> { _1.to_hash })
      @source = source
      @model_class = model_class
      @record_to_hash = record_to_hash

      freeze
    end

    include Enumerable

    def each = block_given? ? resolved.each { yield model _1 } : to_enum(:each)

    # count only counts records in List, provide your own list class for enhanced behaviour
    def count = source.count(:all)

    # these methods return basic types
    delegate :pluck, :size, to: :resolved

    # these methods return nil, object, array of objects
    %i[first last []].each do |meth|
      class_eval "def #{meth}(...) = nil_or_single_or_array(resolved.#{meth}(...))", __FILE__, __LINE__
    end

    # these methods are finders, and return a Result
    %i[first! last!].each do |meth|
      class_eval "def #{meth} = Result.wrap { model(resolved.#{meth}) }", __FILE__, __LINE__
    end

    # these methods return a new Models object, with a new source with the method applied
    %i[order reorder reverse_order limit offset].each do |meth|
      class_eval "def #{meth}(...) = new(source.#{meth}(...))", __FILE__, __LINE__
    end

    private

    attr_reader :source

    def resolved = @source

    def model(record) = @model_class.new(**@record_to_hash.call(record))

    def nil_or_single_or_array(arg)
      return arg.map { model _1 } if arg.is_a?(Array)
      return model(arg) if arg
    end

    def new(source = @source, model_class: @model_class, record_to_hash: @record_to_hash, **kwargs)
      self.class.new(source, model_class: model_class, record_to_hash: record_to_hash, **kwargs)
    end

    class ArraySource < List
      class RecordNotFound < RuntimeError
        def initialize(message = 'No record exists') = super
      end

      def self.new(...) = original_new(...)

      def initialize(source, limit: nil, offset: nil, order: nil, **kwargs)
        @limit = limit
        @offset = offset
        @order = order
        super(source, **kwargs)
      end

      delegate :count, to: :resolved

      def pluck(*cols) = resolved.map { _1.to_hash.yield_self { |r| cols.one? ? r[cols[0]] : r.values_at(*cols) } }

      def first! = Result.wrap { first or raise RecordNotFound }

      def last! = Result.wrap { last or raise RecordNotFound }

      def order(...) = new(order: { **order_hash, **OrderArray.parse_order(...) })

      def reorder(...) = new(order: OrderArray.parse_order(...))

      def reverse_order = new(order: OrderArray.reverse_order(**order_hash))

      def limit(limit) = new(limit: limit)

      def offset(offset) = new(offset: offset)

      private

      def resolved
        source = OrderArray.call(@source, **order_hash)
        source = source[@offset..] if @offset
        source = source[0, @limit] if @limit
        source
      end

      def order_hash = @order || {}

      def new(source = @source, limit: @limit, offset: @offset, order: @order, **kwargs)
        super(source, limit: limit, offset: offset, order: order, **kwargs)
      end
    end

    # order an array of to_hash-able objects using ActiveRecord order syntax
    # Note that nil values are put last in ascending order, and first in descending, which is the default for postgres
    class OrderArray
      def self.call(records, ...)
        order          = parse_order(...)
        hashed_records = records.to_h { [_1.to_hash, _1] }
        sorted_hashes  = sort_hashes_by_order(hashed_records.keys, **order)

        hashed_records.values_at(*sorted_hashes)
      end

      def self.parse_order(*args, **opts)
        return opts if args.empty?

        args.map { _1.to_s.split(',') }.flatten.to_h do
          [_1[/(\w+)/,1].to_sym, _1 =~ /\w +desc\b/i && :desc]
        end.merge(opts)
      end

      def self.reverse_order(**order) = order.to_h { [_1, (_2 == :desc ? nil : :desc)] }

      def self.sort_hashes_by_order(hashes, **order)
        hashes.sort { compare_hashes_by_order _1, _2, **order }
      end

      def self.compare_hashes_by_order(a, b, **order)
        order.each do |col, dir|
          return (dir == :desc ? 1 : -1) if b[col].nil? && !a[col].nil?
          return (dir == :desc ? -1 : 1) if a[col].nil? && !b[col].nil?
          unless (compare_result = a[col] <=> b[col]) == 0
            return (dir == :desc ? -compare_result : compare_result)
          end
        end
        0
      end
    end
  end
end