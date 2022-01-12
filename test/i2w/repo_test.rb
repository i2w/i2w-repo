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
      optional_list :posts, -> { order(:content) }
    end

    class PostRepo < Repo
      dependency :record_class, -> { PostRecord }

      optional_model :user
      optional_list :reactions

      def all_for(user_id:)
        list scope.where(user_id: user_id)
      end

      def find_for(user_id:, **kwargs)
        scope all_for(user_id: user_id) do
          find(**kwargs)
        end
      end
    end

    class Post < Model::Persisted
      attribute :user_id
      attribute :content
      attribute :reactions
      attribute :user
    end

    class ReactionRepo < Repo
      dependency :record_class, ReactionRecord
    end

    class ReactionInput < Input
      dependency :record_class, ReactionRecord

      attribute :content
      attribute :likes
      attribute :pinned
    end

    class Reaction < Model::Persisted
      attribute :post_id
      attribute :user_id
      attribute :content
      attribute :pinned
      attribute :likes
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

    test 'repo #find(by: Hash)' do
      user = UserRepo.create(input: { email: 'fred@email.com' }).value

      assert_equal user, UserRepo.find(by: { email: 'fred@email.com' }).value

      actual = UserRepo.find(by: { email: 'fred@e.com' })
      refute actual.success?
      assert actual.failure.is_a?(ActiveRecord::RecordNotFound)
    end

    test 'repo #find(by: Input)' do
      user = UserRepo.create(input: { email: 'fred@email.com' }).value

      assert_equal user, UserRepo.find(by: UserInput.new(email: 'fred@email.com')).value

      bad_input = UserInput.new(email: 'fffff')
      actual = UserRepo.find(by: bad_input)
      refute actual.success?
      assert actual.failure.is_a?(ActiveRecord::RecordNotFound)
      assert_match(/Couldn\'t find UserRecord/, actual.errors.full_messages[0])
    end

    test 'repo #find(id:)' do
      user = UserRepo.create(input: { email: 'fred@email.com' }).value

      assert_equal user, UserRepo.find(id: user.id).value

      actual = UserRepo.find(id: 0)
      refute actual.success?
      assert actual.failure.is_a?(ActiveRecord::RecordNotFound)
    end

    test "repo .with example, #find_for, #all_for" do
      user = UserRepo.create(input: { email: 'fred@email.com' }).value
      post = PostRepo.create(input: { user_id: user.id, content: 'My Post' }).value

      actual = UserRepo.find(id: user.id).value
      assert_equal UnloadedAttribute.new(User, :posts), actual.posts

      actual = UserRepo.with(:posts).find(id: user.id).value
      assert_equal [post], actual.posts.to_a

      next_user = UserRepo.create(input: UserInput.new(email: 'jim@email.com')).value
      next_post = PostRepo.create(input: { user_id: next_user.id, content: 'Jim Post' }).value

      assert_equal [post, next_post], PostRepo.all.to_a
      refute PostRepo.find_for(user_id: next_user.id, id: post.id).success?
      assert PostRepo.find_for(user_id: user.id, id: post.id).success?
      assert_equal [post], PostRepo.all_for(user_id: user.id).to_a

      another_post = PostRepo.create(input: { user_id: next_user.id, content: 'Another Jim Post' }).value
      next_user = UserRepo.with(:posts).find(id: next_user).value
      assert_equal [another_post, next_post], next_user.posts.to_a
      assert_equal [next_post, another_post], next_user.posts.reorder(content: :desc).to_a
    end

    test 'Input with record_dependency infers types from the record' do
      actual = ReactionInput.new(likes: '12', pinned: 'true')
      assert_equal 12, actual.likes
      assert_equal true, actual.pinned
    end
  end
end
