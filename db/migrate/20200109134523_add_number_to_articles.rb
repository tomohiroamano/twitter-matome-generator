class AddNumberToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :number, :integer
  end
end
