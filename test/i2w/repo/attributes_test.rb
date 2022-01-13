# frozen_string_literal: true

require 'test_helper'

module I2w
  class RepoAttributesTest < ActiveSupport::TestCase
    class FooRepo < Repo
      attributes except: [:one, :two]
    end

    class FooSubRepo < FooRepo
      dependency :model_class, -> { Foo }
      dependency :record_class, -> { FooRecord }

      config.except_attributes << :four
      # or
      # attributes except: [:one, :two, :four]
    end

    class Foo2Repo < FooSubRepo
      attributes except: nil, only: :three
    end

    class Foo < Model
      attribute :three
    end

    class FooRecord
      def self.all = self

      def self.find(id)
        case id
        when 3 then { three: 3 }
        when 123 then { one: 1, two: 2, three: 3 }
        when 1234 then { one: 1, two: 2, three: 3, four: 4 }
        end
      end
    end

    test 'attributes except: removes attributes before sending to the model' do
      actual = FooRepo.find(123)
      assert actual.success?
      assert_equal Foo, actual.value.class
      assert_equal({ three: 3 }, actual.value.to_h)
    end

    test 'attributes only: whitelists attributes before sending to the model' do
      actual = Foo2Repo.find(123)
      assert actual.success?
      assert_equal Foo, actual.value.class
      assert_equal({ three: 3 }, actual.value.to_h)
    end

    test 'attributes except: does nothing if the attributes are not in the record' do
      actual = FooRepo.find(3)
      assert actual.success?
      assert_equal Foo, actual.value.class
      assert_equal({ three: 3 }, actual.value.to_h)
    end

    test 'non ignored attributes in the record raise an error if the attribute is not defined on the model' do
      actual = assert_raises I2w::DataObject::UnknownAttributeError do
        FooRepo.find(1234)
      end
      assert_equal 'Unknown attribute four', actual.message
    end

    test 'only: and except: attributes are inherited and can be modified/added to' do
      actual = FooSubRepo.find(1234)
      assert actual.success?
      assert_equal Foo, actual.value.class
      assert_equal({ three: 3 }, actual.value.to_h)

      actual = Foo2Repo.find(1234)
      assert actual.success?
      assert_equal Foo, actual.value.class
      assert_equal({ three: 3 }, actual.value.to_h)
    end
  end
end