require 'rubygems'
require 'yaml'
require 'flowchart/flow_processor'
require 'flowchart/work_processor'
module FlowChart
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    attr_reader :flowprocessor,:workprocessor
    
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

    def workchart(&block)
      @workprocessor = FlowChart::WorkProcessor.new(&block)

      #Driver Instance Methods for each evet for triggering the delegation action!
      @workprocessor.delegate_actions.keys.each do |key|
        define_method "#{key}" do |assigned_to,assigned_by|
          process_delegate_action(key,assigned_to,assigned_by,:save_object=>false)
        end
        
        define_method "#{key}!" do |assigned_to,assigned_by|
          process_delegate_action(key,assigned_to,assigned_by,:save_object=>true)
        end
      end
    end

  end

  module InstanceMethods
    attr_accessor :previous_state

    def workprocessor
      self.class.workprocessor
    end

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

    def current_work_owners
      @current_work_owners ||= workprocessor.delegate_actions.map{|work_name,work_owners| {work_name=>work_owners.current_work_owners}}
      @current_work_owners
    end

    def set_current_work_owners(options = {})
      @current_work_owners = workprocessor.delegate_actions.map{|work_name,work_owners| {work_name=>work_owners.current_work_owners}}
      send("#{workprocessor.assigned_to_column}=".to_sym, YAML.dump(current_work_owners.map{|work| work.map{|work_name,owners| {work_name=>owners[workprocessor.assigned_to_column.to_sym]||""}}}.flatten))
      send("#{workprocessor.assigned_by_column}=".to_sym, YAML.dump(current_work_owners.map{|work| work.map{|work_name,owners| {work_name=>owners[workprocessor.assigned_by_column.to_sym]||""}}}.flatten))
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

    def process_delegate_action(action_name,assigned_to,assigned_by,options_for_delegate_action={})
      delegate_action = workprocessor.delegate_actions[action_name.to_sym]
      if delegate_action.nil?
        p "Error: #{action_name} not found!"
        raise FlowChart::InvalidWorkDelegateAction.new("Error: #{delegate_action} not found!")
      end
      delegate_action.process_delegate_action!(self,current_work_owners,assigned_to,assigned_by,options_for_delegate_action)
    end
  end
end