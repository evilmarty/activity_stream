module ActivityStream
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def activity_callbacks
      read_inheritable_attribute(:activity_callbacks) || {}
    end
    
    def log_activities(*args, &block)
      args = [:create, :update, :destroy] if args.length == 0
      
      activity_callbacks = self.activity_callbacks
      callback = block_given?? block : true
      args.each { |verb| activity_callbacks["after_#{verb}".intern] = callback }
      write_inheritable_attribute :activity_callbacks, activity_callbacks
      
      add_observer ActivityObserver.instance unless defined? @_activity_observed
      # to ensure we don't add the observer multiple times
      @_activity_observed = true
    end
    
    def skip_log_activity(*args)
      args = args.map(&:to_sym)
      write_inheritable_attribute :activity_callbacks, activity_callbacks.reject { |k, v| args.include?("after_#{k}".intern) }
    end
    
    def acts_as_actor
      class_eval do
        def log_activity(context = nil)
          raise ArgumentError unless block_given?
          
          current_activity_stream = Thread.current[:activity_stream]
          Thread.current[:activity_stream] = {:actor => self, :context => context}
          
          yield
          
          Thread.current[:activity_stream] = current_activity_stream
        end
      end
      
      has_many :activities, :as => :actor
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActivityStream
end