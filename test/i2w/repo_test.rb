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

      def create_with_posts(email:, name:, posts:)
        model_result transaction: true do
          user_record = UserRecord.create!(email: email, name: name)
          posts = PostRepo.create_posts(*posts, user_id: user_record.id)
          { **user_record, posts: posts }
        end
      end
    end

    class PostRepo < Repo
      dependency :record_class, -> { PostRecord }

      optional_model :user
      optional_list :reactions

      default_order 'content DESC'

      def create_posts(*posts, user_id:)
        list Result.value(transaction do
          posts.map { PostRecord.create! user_id: user_id, content: _1 }
        end)
      end

      def all_for(user_id:)
        list scope.where(user_id: user_id)
      end

      def find_for(*args, user_id:, **kwargs)
        scope all_for(user_id: user_id) do
          find(*args, **kwargs)
        end
      end
    end

    class Post < Model::Persisted
      attribute :user_id
      attribute :content
      attribute :reactions
      attribute :user, default: -> { UserRepo.find(_1.user_id).value }
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
      assert_equal UserInput, ClassLookup.new { _1 + 'Input' }.resolve(User)
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
      user = UserRepo.create(email: 'fred@email.com').value

      assert_equal user, UserRepo.find(by: { email: 'fred@email.com' }).value

      actual = UserRepo.find(by: { email: 'fred@e.com' })
      refute actual.success?
      assert actual.failure.is_a?(ActiveRecord::RecordNotFound)
    end

    test 'repo #find(by: Input)' do
      user = UserRepo.create(email: 'fred@email.com').value

      assert_equal user, UserRepo.find(by: UserInput.new(email: 'fred@email.com')).value

      bad_input = UserInput.new(email: 'fffff')
      actual = UserRepo.find(by: bad_input)
      refute actual.success?
      assert actual.failure.is_a?(ActiveRecord::RecordNotFound)
      assert_match(/Couldn\'t find UserRecord/, actual.errors.full_messages[0])
    end

    test 'repo #find(id:)' do
      user = UserRepo.create(email: 'fred@email.com').value

      assert_equal user, UserRepo.find(user.id).value

      actual = UserRepo.find(0)
      refute actual.success?
      assert actual.failure.is_a?(ActiveRecord::RecordNotFound)
    end

    test "repo .with example, #find_for, #all_for" do
      user = UserRepo.create(email: 'fred@email.com').value
      post = PostRepo.create(user_id: user.id, content: 'My Post').value

      actual = UserRepo.find(user.id).value
      assert_equal UnloadedAttribute.new(User, :posts), actual.posts

      actual = UserRepo.with(:posts).find(user.id).value
      assert_equal [post], actual.posts.to_a

      next_user = UserRepo.create(UserInput.new(email: 'jim@email.com')).value
      next_post = PostRepo.create(user_id: next_user.id, content: 'Jim Post').value

      assert_equal [post, next_post], PostRepo.all.to_a
      refute PostRepo.find_for(post.id, user_id: next_user.id).success?
      assert PostRepo.find_for(post.id, user_id: user.id).success?
      assert_equal [post], PostRepo.all_for(user_id: user.id).to_a

      another_post = PostRepo.create(user_id: next_user.id, content: 'Another Jim Post').value
      next_user = UserRepo.with(:posts).find(next_user).value
      assert_equal [another_post, next_post], next_user.posts.to_a
      assert_equal [next_post, another_post], next_user.posts.reorder(content: :desc).to_a
    end

    test 'UserRepo#create_with_posts example (references Array list, other repo, nested transactions)' do
      actual = UserRepo.create_with_posts(email: 'fred@email.com', name: 'Fred', posts: ['One', 'Two'])
      assert actual.success?
      assert_instance_of User, actual.value
      assert_equal ['fred@email.com', 'Fred'], [actual.value.email, actual.value.name]
      assert_equal ['One', 'Two'], actual.value.posts.order(:name).pluck(:content)

      assert_equal UserRepo.all.count, 1
      assert_equal PostRepo.all.count, 2

      actual = UserRepo.with(:posts).create_with_posts(email: 'gary@email.com', name: 'Gary', posts: ['One', nil])
      assert actual.failure?

      assert_equal UserRepo.all.count, 1
      assert_equal PostRepo.all.count, 2
    end

    test "Repo.default_order provides default order, unless overridden by List.order" do
      user = UserRepo.create(email: 'fred@email.com').value
      post_a = PostRepo.create(user_id: user.id, content: 'Post A').value
      post_b = PostRepo.create(user_id: user.id, content: 'Post B').value
      post_c = PostRepo.create(user_id: user.id, content: 'Post C').value

      assert_equal [post_c, post_b, post_a], PostRepo.all.to_a
      assert_equal [post_a, post_b, post_c], PostRepo.all.order(:content).to_a
      assert_equal [post_a, post_b, post_c], UserRepo.with(:posts).find(user.id).value.posts.to_a
    end

    test "default attribute can be loaded by Repo, or not (load via Repo to void n+1 queries)" do
      user = UserRepo.create(email: 'fred@email.com').value
      post = PostRepo.create(user_id: user.id, content: 'Post A').value

      # load via default attribute
      actual = PostRepo.find(post.id).value
      assert_equal user, actual.user
      assert_equal UnloadedAttribute.new(User, :posts), actual.user.posts

      # load via Repo, loaded with :posts to show where it was loaded from
      actual = PostRepo.with(user: :posts).find(post.id).value
      assert_equal user, actual.user
      assert_equal [post], actual.user.posts.to_a
    end

    test 'Input with record_dependency infers types from the record' do
      actual = ReactionInput.new(likes: '12', pinned: 'true')
      assert_equal 12, actual.likes
      assert_equal true, actual.pinned
    end

    test 'Repo.transactional rollbacks transactions if the result is a failure, and returns the failure' do
      actual = Repo.transaction { :hi }
      assert actual.success?
      assert_equal :hi, actual.value

      actual = Repo.transaction do
        UserRepo.create(email: 'abe@email.com').and_tap do
          assert_equal 1, UserRepo.all.count
        end.and_then do |user|
          Result.failure(user) # for some business related reason
        end
      end

      assert actual.failure?
      assert_instance_of User, actual.failure
      assert_equal 'abe@email.com', actual.failure.email
      assert_equal 0, UserRepo.all.count
    end

    test 'Repo.transaction does not swallow non failure exceptions' do
      assert_raises NoMethodError do
        Repo.transaction { Object.new.foo }
      end
    end

    test 'Repo#to_result transaction: true' do
      Repo.to_result transaction: true do
        user = UserRecord.create!(email: 'abe@email.com')
        assert_equal 1, UserRecord.count
        PostRecord.create!(user_id: user.id, content: 'one')
        assert_equal 1, PostRecord.count
        PostRecord.create!
        raise 'never reached'
      end

      assert_equal 0, UserRecord.count
      assert_equal 0, PostRecord.count
    end

    test 'Repo.transaction test' do
      begin
        Repo.transaction do
          user = UserRecord.create!(email: 'abe@email.com')
          assert_equal 1, UserRecord.count
          PostRecord.create!(user_id: user.id, content: 'one')
          assert_equal 1, PostRecord.count
          PostRecord.create!
          raise 'never reached'
        end
      rescue ActiveRecord::NotNullViolation
      end

      assert_equal 0, UserRecord.count
      assert_equal 0, PostRecord.count
    end

    test 'nested Repo.transaction test' do
      begin
        Repo.transaction do
          user = UserRecord.create!(email: 'abe@email.com')
          assert_equal 1, UserRecord.count

          Repo.transaction do
            PostRecord.create!(user_id: user.id, content: 'one')
            assert_equal 1, PostRecord.count
            PostRecord.create!
            raise 'never reached'
          end
        end
      rescue ActiveRecord::NotNullViolation
      end

      assert_equal 0, UserRecord.count
      assert_equal 0, PostRecord.count
    end
  end
end
