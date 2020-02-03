class AddScoreToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :score, :text
  end
end
