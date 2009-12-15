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
    activity_stream, block = Thread.current[:activity_stream], object.class.activity_callbacks[observed_method]
    # lets not log an activity if we don't have an actor or isn't an allowed callback
    return unless !!activity_stream and (block.is_a?(Proc) ? block.call(object) != false : block == true)
    
    verb = observed_method.to_s.gsub /^after_/, ''
    
    Activity.create(:object => object, :actor => activity_stream[:actor], :verb => verb, :context => activity_stream[:context])
  end
end