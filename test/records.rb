class UserRecord < I2w::Record
  has_many :posts
  has_one :last_post, -> { order('created_at DESC') }, class_name: 'PostRecord'
  has_many :my_reactions, class_name: 'ReactionRecord'
  has_many :reactions_to_me, class_name: 'ReactionRecord', through: :posts, source: :reactions
end

class PostRecord < I2w::Record
  belongs_to :user
  has_many :reactions
end

class ReactionRecord < I2w::Record
  self.table_name = 'comments'

  belongs_to :post
  belongs_to :user, optional: true
end