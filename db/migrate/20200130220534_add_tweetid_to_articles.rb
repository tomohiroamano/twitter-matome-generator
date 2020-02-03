class AddTweetidToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :tweetid, :string
  end
end
