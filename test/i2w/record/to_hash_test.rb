# frozen_string_literal: true

require 'test_helper'
require 'i2w/record/to_hash'

module I2w
  class RecordToHashTest < ActiveSupport::TestCase
    class FooRecord
      def attributes = { one: 1, two: 2, secret: 'stuff' }
      alias to_hash attributes

      def bars = ['bar1', 'bar2']
    end

    record = FooRecord.new

    test '(empty) #call(record) just returns the record attributes' do
      to_hash = Record::ToHash.new
      assert_equal({one: 1, two: 2, secret: 'stuff'}, to_hash.call(record))
    end

    test 'only just returns those attributes' do
      to_hash = Record::ToHash.new(only: [:one, :two])
      assert_equal({one: 1, two: 2}, to_hash.call(record))
    end

    test 'only cannot be used with except' do
      assert_raises ArgumentError do
        Record::ToHash.new(only: [:one, :two], except: :secret)
      end
    end

    test 'except returns all but the specified attributes' do
      to_hash = Record::ToHash.new(except: :secret)
      assert_equal({one: 1, two: 2}, to_hash.call(record))
    end

    test 'extra attributes are constructed from the record' do
      to_hash = Record::ToHash.new(extra: { bars: :bars }, except: :secret)
      assert_equal({one: 1, two: 2, bars: ['bar1', 'bar2']}, to_hash.call(record))

      to_hash = Record::ToHash.new(only: [], extra: { up_bars: -> { _1.bars.map(&:upcase) } })
      assert_equal({up_bars: ['BAR1', 'BAR2']}, to_hash.call(record))
    end

    test 'extra attributes override always attributes' do
      to_hash = Record::ToHash.new(extra: { bars: -> { _1.bars } }, always: :bars)
      assert_equal({one: 1, two: 2, secret: 'stuff', bars: ['bar1', 'bar2']}, to_hash.call(record))
    end

    test 'always attributes are nil if not present in record attributes, or extra attributes' do
      to_hash = Record::ToHash.new(always: :three, except: :secret)
      assert_equal({one: 1, two: 2, three: nil}, to_hash.call(record))

      to_hash = Record::ToHash.new(always: :three, except: :secret, extra: { three: ->(_) { 3 }})
      assert_equal({one: 1, two: 2, three: 3}, to_hash.call(record))
    end

    test 'missing always attributes can be configured via on_missing callable' do
      to_hash = Record::ToHash.new(only: [:one, :two],
                                   always: [:three],
                                   on_missing: -> { UnloadedAttribute.new('Foo', _1) })

      assert_equal({one: 1, two: 2, three: UnloadedAttribute.new('Foo', :three)}, to_hash.call(record))
    end

    test 'if record is a hash, does not mutate the record' do
      to_hash = Record::ToHash.new(extra: { three: ->(_) { 3 } })
      rec_hash = { one: 1, two: 2 }
      assert_equal({ one: 1, two: 2, three: 3 }, to_hash.call(rec_hash))
      assert_equal({ one: 1, two: 2 }, rec_hash)
    end
  end
end