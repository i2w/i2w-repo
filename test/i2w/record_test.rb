# frozen_string_literal: true

require 'test_helper'

module I2w
  class RecordTest < ActiveSupport::TestCase
    truncate_tables

    test 'double splat returns attributes' do
      u = UserRecord.create!(email: 'fred@mail.com')
      assert_equal({id: u.id, email: u.email, name: nil, updated_at: u.updated_at, created_at: u.created_at}, { **u })
    end

    test 'table_name defaults to standard active record table name, but can be overridden' do
      assert_equal 'users', UserRecord.table_name
      assert_equal 'posts', PostRecord.table_name
      assert_equal 'comments', ReactionRecord.table_name
    end

    test 'has_many' do
      reflection = UserRecord.reflect_on_association(:posts)
      assert_equal ActiveRecord::Reflection::HasManyReflection, reflection.class
      assert_equal 'PostRecord', reflection.class_name
      assert_equal 'user_id', reflection.foreign_key
    end

    test 'has_one' do
      reflection = UserRecord.reflect_on_association(:last_post)
      assert_equal ActiveRecord::Reflection::HasOneReflection, reflection.class
      assert_equal 'PostRecord', reflection.class_name
      assert_equal 'user_id', reflection.foreign_key
    end

    test 'belongs_to' do
      reflection = ReactionRecord.reflect_on_association(:post)
      assert_equal ActiveRecord::Reflection::BelongsToReflection, reflection.class
      assert_equal 'PostRecord', reflection.class_name
      assert_equal 'post_id', reflection.foreign_key
    end
  end
end
