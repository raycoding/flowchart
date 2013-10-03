module FlowChart
  class InvalidWorkDelegateAction < NoMethodError; end

  class WorkOwner
  	attr_accessor :work_owner_model,:sla
    
    def initialize(work_owner_model, &workownerblock)
    	@work_owner_model,@sla = work_owner_model.to_s.classify.constantize,Hash.new
      instance_eval(&workownerblock) if block_given?
    end

    def goal_time(method = nil, &block)
      @sla[:goal_time] = method.nil? ? block : method
    end

    def dead_line(method = nil, &block)
      @sla[:dead_line] = method.nil? ? block : method
    end

    def self.work_assign(to,by)
    	assigned_to,assigned_by = to,by
    	return Hash[:assigned_to=> assigned_to, :assigned_by=>assigned_by]
    end
  end

  class WorkDelegateAction
  	attr_accessor :delegate_action_name
  	attr_accessor :current_work_owners
  	attr_accessor :work_owners_trace
  	
  	def initialize(delegate_action_name,workprocessor=nil,&block)
  		@current_work_owners = Hash.new
  		@work_owners_trace = []
  		@delegate_action_name = delegate_action_name
  	end

  	def process_delegate_action!(implementor_class,current_work_owners,assigned_to,assigned_by,options_for_delegate_action)
  		puts @delegate_action_name
  		new_work_owners = WorkOwner.work_assign(assigned_to,assigned_by)
  		@work_owners_trace << new_work_owners
  		@current_work_owners = new_work_owners
  		implementor_class.set_current_work_owners(options_for_delegate_action)
  	end

  end

   # Main Driver for WorkChart
  class WorkProcessor
  	attr_accessor :work_owners,:delegate_actions

  	def initialize(&workprocessor)
  		@work_owners, @delegate_actions = Hash.new, Hash.new
      begin
        instance_eval(&workprocessor)
      rescue => e
        p e.backtrace
      end
    end

    ## Default state_column is assumed to be assigned_to if not mentioned
    # You can override the default state_column by mentioning in your class
    # assigned_to_column :something_else
    def assigned_to_column(name = :assigned_to)
      @assigned_to_column ||= name
    end

    ## Default state_column is assumed to be assigned_by if not mentioned
    # You can override the default state_column by mentioning in your class
    # assigned_by_column :something_else
    def assigned_by_column(name = :assigned_by)
      @assigned_by_column ||= name
    end

    def workowner(work_owner_model, &block)
      work_owner = FlowChart::WorkOwner.new(work_owner_model,&block)
      @work_owners[work_owner_model.to_sym] = work_owner
    end

    def delegate(delegate_action_name, &block)
    	delegate_action = FlowChart::WorkDelegateAction.new(delegate_action_name,self,&block)
      @delegate_actions[delegate_action_name.to_sym] = delegate_action
    end

  end
end