class Article < ApplicationRecord
  belongs_to :user
  
  validates :keyword, presence: true, length: { maximum: 255 }
  validates :tweetid, presence: true, length: { maximum: 50 }
  
  #ツイート検索時の条件指定 1~1000件まで検索可能
  validates :number, numericality: {
            only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000
          }
  validates :mode, length: { maximum: 30 }
  validates :analysisflag, inclusion: { in: [true, false] }
end
