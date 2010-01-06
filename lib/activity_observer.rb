class ActivityObserver < ActiveRecord::Observer
  class << self
    # we don't want to include the activity model
    def observed_class
      nil
    end
  end
  
  def update(observed_method, object)
    # check the object isn't an activity
    return if object.is_a? Activity
    context, block = Thread.current[:activity_stream_context], object.class.activity_triggers[observed_method]
    # lets not log an activity if we don't have an actor or isn't an allowed callback
    return unless !!context and (block.is_a?(Proc) ? block.call(object) != false : block == true)
    
    verb = observed_method.to_s.gsub /^after_/, ''
    
    attributes = context.attributes.merge :verb => verb, :object => object
    attributes[:indirect_object] ||= object.instance_variable_get('@_indirect_object')
    
    Activity.create(attributes)
  end
end