# frozen_string_literal: true

require 'test_helper'

module I2w
  class RepoTest < ActiveSupport::TestCase
    truncate_tables

    class User < Model::Persisted
      attribute :email
      attribute :name
      attribute :posts
    end

    class UserInput < Input
      attribute :email
    end

    UserRecord = ::UserRecord

    class UserRepo < Repo
      optional :posts, -> { PostRepo.models(_1.posts) }, scope: -> { includes(:posts) }
    end

    class PostRepo < Repo
      dependency :record_class, -> { PostRecord }

      def all_for(user_id:)
        list scope.where(user_id: user_id)
      end

      def find_for(user_id:, **kwargs)
        scope_of_list all_for(user_id: user_id) do
          find(**kwargs)
        end
      end
    end

    class Post < Model::Persisted
      attribute :user_id
      attribute :content
    end

    test 'default dependencies' do
      assert_equal User, UserRepo.model_class
      assert_equal UserRecord, UserRepo.record_class
      assert_equal UserInput, ClassLookup.call(User) { _1 + 'Input' }
    end

    test 'overridden dependencies' do
      assert_equal ::PostRecord, PostRepo.record_class
    end

    test "cannot instantiate Repo" do
      assert_raises NoMethodError do
        UserRepo.new
      end
    end

    test "Repo.instance is private" do
      assert_raises NoMethodError do
        UserRepo.instance
      end
    end

    test 'repo instance is memoized and frozen' do
      assert UserRepo.send(:instance).equal?(UserRepo.send(:instance))
      assert UserRepo.send(:instance).frozen?
    end

    test '.with(*optional) is memoized and frozen' do
      assert UserRepo.with(:posts).equal?(UserRepo.with(:posts))
      assert UserRepo.with(:posts).frozen?
    end

    test "repository example" do
      user_id = UserRepo.create(input: { email: 'fred@email.com' }).value.id
      post_id = PostRepo.create(input: { user_id: user_id, content: 'My Post' }).value.id

      user = UserRepo.find(by: { email: 'fred@email.com' }).value
      assert_equal 'fred@email.com', user.email

      user = UserRepo.find(by: UserInput.new(email: 'fred@email.com')).value
      assert_equal 'fred@email.com', user.email

      user = UserRepo.find(id: user_id).value
      assert_equal 'fred@email.com', user.email
      assert_equal UnloadedAttribute.new(User, :posts), user.posts

      user_with_posts = UserRepo.with(:posts).find(id: user_id).value
      assert_equal 'fred@email.com', user_with_posts.email
      assert_equal [Post.from(id: post_id)], user_with_posts.posts.to_a

      next_user_id = UserRepo.create(input: UserInput.new(email: 'jim@email.com')).value.id
      next_post_id = PostRepo.create(input: { user_id: next_user_id, content: 'Jim Post' }).value.id

      assert [Post.from(id: post_id), Post.from(id: next_post_id)], PostRepo.all.to_a
      refute PostRepo.find_for(user_id: next_user_id, id: post_id).success?
      assert PostRepo.find_for(user_id: user_id, id: post_id).success?
      assert_equal [Post.from(id: post_id)], PostRepo.all_for(user_id: user_id).to_a
    end
  end
end
