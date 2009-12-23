class Post < ActiveRecord::Base
  belongs_to :person
  
  has_many :comments
  
  log_activities
  
  def to_s
    message
  end
end