module FlowChart
  class InvalidTransition < NoMethodError; end
  class InvalidState < NoMethodError; end
  class InvalidAction < NoMethodError; end

  # Driver for States in FlowChart
  class State
    attr_accessor :flowstatename, :before_and_after_works
    
    def initialize(flowstatename, &flowblock)
      @flowstatename,@before_and_after_works = flowstatename,Hash.new
      instance_eval(&flowblock) if block_given?
    end
    
    ## Optional in State flow
    ##Preprocess Things-To-Do before entering this state => Usecase Notifications
    ## Takes a proc or instance method as block
    def preprocess(method = nil, &block)
      @before_and_after_works[:preprocess] = method.nil? ? block : method
    end

    ## Optional in State flow
    #PostProcess Things-To-Do before entering this state => Usecase Notifications
    ## Takes a proc or instance method as block
    def postprocess(method = nil, &block)
      @before_and_after_works[:postprocess] = method.nil? ? block : method
    end
    
    ##Defines how the flow for a State executes with preprocess and postprocess
    def process_flow(action,base)
      action = @before_and_after_works[action.to_sym]
      case action
      when Symbol, String
        base.send(action)
      when Proc
        action.call(base)
      end
    end
  end

  # Driver for Transition in FlowChart
  class Transition
    attr_reader :condition #boolean condition to verify if transition can be done!
    attr_reader :branch #selection from multiple branch transition based on condition! 
    attr_reader :from #transit from!
    attr_reader :to #transit to!
    
    def initialize(options)
      @condition = options[:condition]
      @branch = options[:branch]
      @from = [options[:from]].flatten
      @to = options[:to]
    end 
    
    def get_me_next_state(base)
      raise InvalidTransition.new("You cannot transit from multiple states without a decision condition!") if @to.is_a?(Array) && @branch.nil?
      ## If to is a single state then just pass it on!
      if !@to.is_a?(Array)
        return @to
      end
      ## If to is an Array it means decision has to be made based on branching conditions to choose the to state!
      to = process_flow(@branch, base)
      ## If result to state coming from branching condition is not part of the set mentioned in to then next state transit is not possible!
      raise InvalidState.new("Your decision condition did not lead to transition state mentioned in :to clause!") unless @to.include?(to)
      to
    end

    def shall_i_trasit?(base)
      return true unless @condition ## If no condition has been given then transition is possible!
      ## If condition has been given then evaluate truth or falsity for transition to be possible!
      process_flow(@condition, base)
    end
      
    private
    def process_flow(action,base)
      case action
      when Symbol, String
        base.send(action)
      when Proc
        action.call(base)
      end
    end
  end

  # Driver for Actions in FlowChart
  class Action
    attr_accessor :name 
    attr_accessor :transitions
    attr_accessor :flowprocessor
    
    def initialize(name, flowprocessor=nil, &transitions)
      @name = name
      @flowprocessor = flowprocessor
      @transitions = Array.new
      instance_eval(&transitions)
    end
    
    def process_action!(implementor_class,current_state,options_for_action)
      transition = @transitions.select{ |t| t.from.include? current_state.flowstatename }.first
      raise InvalidTransition.new("No transition found for action #{@name}") if transition.nil?
      return false unless transition.shall_i_trasit?(implementor_class)
      new_state = implementor_class.flowprocessor.flowstates[transition.get_me_next_state(implementor_class)]
      raise InvalidState.new("Invalid state #{transition.to.to_s} for transition.") if new_state.nil?
      current_state.process_flow(:postprocess, implementor_class)
      implementor_class.previous_state = current_state.flowstatename.to_s
      new_state.process_flow(:preprocess, implementor_class)
      implementor_class.set_current_state(new_state,options_for_action)
      true
    end
    
    private
    def transitions(args = {})
      transition = FlowChart::Transition.new(args)
      @transitions << transition
    end
    
    def any
      @flowprocessor.flowstates.keys
    end
  end

  # Main Driver for FlowChart
  class FlowProcessor
    attr_accessor :flowstates
    attr_accessor :starting_flowstate
    attr_accessor :actions
    
    def initialize(&flowprocessor)
      @flowstates, @actions = Hash.new, Hash.new
      begin
        instance_eval(&flowprocessor)
      rescue => e
        p e.to_s
      end
    end
    
    ## Default state_column is assumed to be process_status if not mentioned
    # You can override the default state_column by mentioning in your class
    # state_column :something_else
    def state_column(name = :process_status)
      @state_column ||= name
    end

    private    
    def init_flowstate(flowstate_name)
      @starting_flowstate_name = flowstate_name
    end
    
    def flowstate(*flowstatenames, &options)
      flowstatenames.each do |flowstatename|
        flowstate = FlowChart::State.new(flowstatename, &options)
        if @flowstates.empty? || @starting_flowstate_name == flowstatename
          @starting_flowstate = flowstate
        end
        @flowstates[flowstatename.to_sym] = flowstate
      end
    end
    
    def action(action_name, &transitions)
      action = FlowChart::Action.new(action_name, self, &transitions)
      @actions[action_name.to_sym] = action
    end
  end
end