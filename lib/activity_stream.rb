module ActivityStream
  class Context
    attr_reader :options, :name, :actor, :indirect_object
    
    def initialize(options = {})
      @options = options
      @name = @options.delete(:context)
      @actor = @options.delete(:actor)
      @indirect_object = @options.delete(:indirect_object)
    end
    
    def call(&block)
      raise ArgumentError unless block_given?
      current_context = Thread.current[:activity_stream_context]
      Thread.current[:activity_stream_context] = self
      
      yield
      
      Thread.current[:activity_stream_context] = current_context
    end
    
    alias_method :to_s, :name
  end
  
  module ActiveRecord
    def self.included(base)
      base.extend ClassMethods
    end
  
    module ClassMethods
      def activity_triggers
        read_inheritable_attribute(:activity_triggers) || {}
      end
    
      def log_activities(*args, &block)
        args = [:create, :update, :destroy] if args.length == 0
      
        activity_triggers = self.activity_triggers
        callback = block_given?? block : true
        args.each { |verb| activity_triggers["after_#{verb}".intern] = callback }
        write_inheritable_attribute :activity_triggers, activity_triggers
      
        add_observer ActivityObserver.instance unless defined? @_activity_observed
        # to ensure we don't add the observer multiple times
        @_activity_observed = true
      end
    
      def skip_log_activity(*args)
        args = args.map(&:to_sym)
        write_inheritable_attribute :activity_triggers, activity_triggers.reject { |k, v| args.include?("after_#{k}".intern) }
      end
    
      def acts_as_actor
        class_eval do
          def log_activity(options = {}, &block)
            raise ArgumentError unless block_given?
            
            context = ActivityStream::Context.new options.merge(:actor => self)
            context.call(&block)
          end
          
          def log_activity_indirectly_for(record, options = {}, &block)
            log_activity options.merge(:indirect_object => record), &block
          end
        end
      
        has_many :activities, :as => :actor
      end
    end
  end
  
  module AssociationProxy
    def self.included(base)
      base.class_eval do
        private
        def find_indirect_object
          # we don't want activity to be our indirect object
          return nil if @owner.class == Activity

          # tried to use memoize but too many errors, bah!
          @indirect_object ||= if @owner.class.respond_to?(:activity_triggers)
            @owner
          elsif ivar = @owner.instance_variable_get('@_indirect_object')
            ivar
          else
            nil
          end
        end

        def tag_with_indirect_object(record)
          record.instance_variable_set '@_indirect_object', find_indirect_object if find_indirect_object
        end
        
        def set_belongs_to_association_for_with_indirect_object(record)
          tag_with_indirect_object record
          set_belongs_to_association_for_without_indirect_object record
        end
        alias_method_chain :set_belongs_to_association_for, :indirect_object
      end
    end
  end
  
  module AssociationCollection
    def self.included(base)
      base.class_eval do
        
      end
    end
  end
  
  module BelongsToAssociation
    def self.included(base)
      base.class_eval do
        def replace_with_indirect_object(record)
          tag_with_indirect_object record
          replace_without_indirect_object record
        end
        alias_method_chain :replace, :indirect_object
    
        def find_target_with_indirect_object
          record = find_target_without_indirect_object
          tag_with_indirect_object record
          record
        end
        alias_method_chain :find_target, :indirect_object
      end
    end
  end
  
  module HasOneAssociation
    def self.included(base)
      base.class_eval do
        def replace_with_indirect_object(*args)
          tag_with_indirect_object args.first
          replace_without_indirect_object *args
        end
        alias_method_chain :replace, :indirect_object
        
        def new_record_with_indirect_object(replace_existing, &block)
          new_record_without_indirect_object replace_existing do |reflection|
            record = block.call reflection
            # if we are going to replace_existing, this'll get done in our 
            # replace_with_parental_control above - no point in doing it twice
            tag_with_indirect_object record unless replace_existing
            record
          end
        end
        alias_method_chain :new_record, :indirect_object
    
        def find_target_with_indirect_object
          record = find_target_without_indirect_object
          tag_with_indirect_object record
          record
        end
        alias_method_chain :find_target, :indirect_object
      end
    end
  end
  
  module HasManyAssociation
    def self.included(base)
      base.class_eval do
        def add_record_to_target_with_callbacks_with_indirect_object(record, &block)
          tag_with_indirect_object record
          add_record_to_target_with_callbacks_without_indirect_object record, &block
        end
        alias_method_chain :add_record_to_target_with_callbacks, :indirect_object
        
        def find_target_with_indirect_object
          records = find_target_without_indirect_object
          records.each { |record| tag_with_indirect_object(record) }
          records
        end
        alias_method_chain :find_target, :indirect_object
      end
      
    end
  end
  
  module BelongsToPolymorphicAssociation
    def self.included(base)
      base.class_eval do
        def replace_with_indirect_object(record)
          tag_with_indirect_object record
          replace_without_indirect_object record
        end
        alias_method_chain :replace, :indirect_object
        
        def find_target_with_indirect_object
          record = find_target_without_indirect_object
          tag_with_indirect_object record
          record
        end
        alias_method_chain :find_target, :indirect_object
      end
    end
  end
end