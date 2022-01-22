# frozen_string_literal: true

require 'test_helper'

module I2w
  class ListTest < ActiveSupport::TestCase
    truncate_tables

    class User < Model::Persisted
      attribute :email
      attribute :name
    end

    setup do
      now = Time.current
      @abe_record = UserRecord.create!(name: 'abe', email: 'abe@email', created_at: now + 1.seconds)
      @non_record = UserRecord.create!(email: 'non@email', created_at: now)
      @zed_record = UserRecord.create!(name: 'zed', email: 'zed@email', created_at: now)
    end

    def abe = User.new(**@abe_record)
    def non = User.new(**@non_record)
    def zed = User.new(**@zed_record)

    def list(&source) = List.new(instance_exec(&source), model_class: User)

    # source is either an array of users, or an arel scope for the same
    def self.test_query_behaviour(desc, &source)
      test "#{desc} #count" do
        assert_equal 3, list(&source).count
      end

      test "#{desc} #size" do
        assert_equal 3, list(&source).size
      end

      test "#{desc} #length" do
        assert_equal 3, list(&source).length
      end

      test "#{desc} #exists?" do
        assert list(&source).exists?
        refute list(&source).limit(0).exists?
      end

      test "#{desc} #[]" do
        q = list(&source).order(:id)
        assert_equal non, q[1]
        assert_equal [non, zed], q[1..]
        assert_equal [non], q[1,1]
        assert_equal zed, q[-1]
        assert_nil q[3]
      end

      test "#{desc} #first" do
        q = list(&source).order(:id)
        assert_equal abe, q.first
        assert_equal [abe], q.first(1)
        assert_equal [abe, non], q.first(2)
        assert_equal [abe, non, zed], q.first(10)
      end

      test "#{desc} #first!" do
        assert_equal abe, list(&source).order(:id).first!.value
        assert list(&source).offset(10).first!.failure?
      end

      test "#{desc} #last" do
        q = list(&source).order(:id)
        assert_equal zed, q.last
        assert_equal [zed], q.last(1)
        assert_equal [non, zed], q.last(2)
        assert_equal [abe, non, zed], q.last(10)
      end

      test "#{desc} #last!" do
        assert_equal zed, list(&source).order(:id).last!.value
        assert list(&source).offset(10).last!.failure?
      end

      test "#{desc} #pluck" do
        q = list(&source).order(:id)

        assert_equal ['abe', nil, 'zed'], q.pluck(:name)
        assert_equal [nil, 'zed'], q.offset(1).pluck(:name)
        assert_equal [['abe', 'abe@email'], [nil, 'non@email'], ['zed', 'zed@email']], q.pluck(:name, :email)
        assert_equal [['abe', 'abe@email']], q.limit(1).pluck(:name, :email)
      end

      test "#{desc} #order" do
        q = list(&source)

        assert_equal [zed, non, abe], q.order(email: :desc).to_a
        assert_equal [abe, zed, non], q.order('name').to_a # nulls go first
        assert_equal [non, zed, abe], q.order('name DESC').to_a # null go last for DESC
        assert_equal [zed, non, abe], q.order(created_at: :asc, email: :desc).to_a
        assert_equal [zed, non, abe], q.order(created_at: :asc).order(email: :desc).to_a
        assert_equal [abe, non, zed], q.order('created_at desc, name DESC').to_a
        assert_equal [abe, zed, non], q.order(created_at: :desc, name: :asc).to_a
        assert_equal [abe, zed, non], q.order(created_at: :desc, name: :asc, email: :asc).to_a
        assert_equal [abe, zed, non], q.order(created_at: :desc).order(:name).order(:email).to_a
      end

      test "#{desc} #reorder and #reverse_order" do
        q = list(&source)

        assert_equal [zed, non, abe], q.order(:id).reorder(:email).reverse_order.to_a
        assert_equal [zed, non, abe], q.order(created_at: :desc).order('email').reverse_order.to_a
      end

      test "#{desc} #default_order provides order if none specified" do
        q = list(&source).default_order(email: :desc)

        assert_equal [zed, non, abe], q.to_a
        assert_equal [abe, zed, non], q.order(:name).to_a

        # default_order after order is ignored
        assert_equal [abe, zed, non], q.order(:name).default_order(name: :desc).to_a
      end

      test "#{desc} #offset and #limit" do
        q = list(&source).order(:id)

        assert_equal [abe, non], q.limit(2).to_a
        assert_equal 2, q.limit(2).count
        assert_equal 2, q.limit(2).length
        assert_equal 2, q.limit(2).size
        assert_equal [non, zed], q.offset(1).to_a
        assert_equal 2, q.offset(1).count
        assert_equal [non, zed], q.offset(1).limit(2).to_a
        assert_equal [non, zed], q.limit(2).offset(1).to_a
        assert_equal [abe, non, zed], q.limit(1).offset(1).offset(nil).limit(nil).to_a
        assert_equal [non, abe], q.order(:email).reverse_order.limit(2).offset(1).to_a
      end
    end

    test_query_behaviour('source is activerecord scope') { UserRecord.all }

    test_query_behaviour('source is array of records') { [@abe_record, @non_record, @zed_record] }

    test 'activrecord scope with join #default_order and #pluck' do
      PostRecord.create!(user_id: abe.id, content: "Abe Post")
      scope = UserRecord.distinct.joins(:posts).all
      actual = List.new(scope, model_class: User).default_order(:email)

      assert_equal [abe.id], actual.pluck(:id)
    end

    test 'OrderArray.parse_order' do
      method = List::OrderArray.method(:parse_order)
      assert_equal({a: nil, b: :desc}, method.call('a, b DESC'))
      assert_equal({a: :desc, b: nil, c: :desc, d: nil, e: :desc}, method.call('a DESC ', 'b,c desc', :d, e: :desc))
      assert_equal({a: nil, b: :desc}, method.call(*['a', { b: :desc }]))
      assert_equal({}, method.call(nil))
    end
  end
end