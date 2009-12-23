class Activity < ActiveRecord::Base
  default_scope :order => 'timestamp DESC'
  
  belongs_to :actor, :polymorphic => true
  belongs_to :object, :polymorphic => true
  belongs_to :indirect_object, :polymorphic => true
  
  validates_presence_of :actor, :object, :verb
  
  def before_create
    self.timestamp ||= Time.now
  end
  
  def to_s
    default = ["objects.#{object_type.underscore}.#{verb}".intern, "verbs.#{verb}".intern, "#{actor_type.underscore} #{verb} #{object_type.intern}"]
    I18n.t "actors.#{actor_type.underscore}.#{object_type.underscore}.#{verb}", :scope => 'activity_streams', :default => default, :actor => actor, :verb => verb, :object => object, :object_type => object_type
  end
end