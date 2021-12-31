ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :email, null: false
    t.string :name
    t.timestamps
  end

  add_index :users, :email, unique: true

  create_table :posts, force: true do |t|
    t.integer :user_id, null: false
    t.string :content, null: false
    t.timestamps
  end

  add_index :posts, [:id, :user_id]

  create_table :comments, force: true do |t|
    t.integer :post_id, null: false
    t.integer :user_id
    t.string :content, null: false
    t.timestamps
  end

  add_index :comments, [:id, :post_id]
  add_index :comments, [:id, :user_id]
end