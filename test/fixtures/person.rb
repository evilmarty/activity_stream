class Person < ActiveRecord::Base
  has_many :comments
  
  acts_as_actor
  
  def to_s
    "#{firstname} #{lastname}"
  end
end