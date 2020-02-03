class AddAnalysisflagToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :analysisflag, :boolean, default: false, null: false
  end
end
