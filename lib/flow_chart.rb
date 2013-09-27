require 'flowchart/flow_processor'
module FlowChart
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    attr_reader :flowprocessor
    
    def flowchart(&block)
      @flowprocessor = FlowChart::FlowProcessor.new(&block)
      @flowprocessor.flowstates.values.each do |flowstate|
        flowstate_name = flowstate.flowstatename
        # Helper Methods to verify is this is the current_state, example object.uploaded? , object.closed? etc 
        define_method "#{flowstate_name}?" do
          flowstate_name == current_state.flowstatename
        end
      end
      
      #Driver Instance Methods for each evet for triggering the action action!
      @flowprocessor.actions.keys.each do |key|
        define_method "#{key}" do
          process_action(key,:save_object=>false)
        end
        
        define_method "#{key}!" do
          process_action(key,:save_object=>true)
        end
      end
    end
  end

  module InstanceMethods
    attr_accessor :previous_state

    def flowprocessor
      self.class.flowprocessor
    end

    def current_state 
      if (flowprocessor.state_column.to_sym.nil? or send(flowprocessor.state_column.to_sym).nil? or send(flowprocessor.state_column.to_sym)=="")
        @current_state ||=  flowprocessor.flowstates[flowprocessor.starting_flowstate.flowstatename]
      else
        @current_state ||= flowprocessor.flowstates[send(flowprocessor.state_column.to_sym).to_sym]
      end
      @current_state
    end
    
    def set_current_state(new_state, options = {})
      send("#{flowprocessor.state_column}=".to_sym, new_state.flowstatename.to_s)
      @current_state = new_state
      send("#{flowprocessor.state_column.to_s}=".to_sym,"#{current_state.flowstatename.to_s.to_s}") #Updates the instance variable
      # If asked to save action with bang! and if inherits from ActiveRecord in Rails then do save!
      ## Important check to support both Non-ActiveRecord Models in Ruby and ActiveRecord Models in Rails
      if options[:save_object] and !(defined?(ActiveRecord::Base).nil?) and self.class.ancestors.include? ActiveRecord::Base 
        self.save
      end
    end
    
    private
    def process_action(action_name,options_for_action = {})
      action = flowprocessor.actions[action_name.to_sym]
      if action.nil?
        p "Error: #{action_name} not found!"
        raise FlowChart::InvalidState.new("Error: #{action_name} not found!")
      end
      action.process_action!(self,current_state,options_for_action)
    end
  end
end