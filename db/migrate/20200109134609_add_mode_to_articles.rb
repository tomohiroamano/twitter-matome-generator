class AddModeToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :mode, :string
  end
end
