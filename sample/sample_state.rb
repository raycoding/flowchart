# Example of a Non-ActiveRecord Class using FlowChart in Ruby - showing only State Machine

class SampleState
  include FlowChart
  attr_accessor :process_status

  flowchart do
    init_flowstate :init

    flowstate :init do
      preprocess Proc.new { |o| p "Initializing File" }
      postprocess :notify_user
    end

    flowstate :uploaded do
      preprocess Proc.new  { |o| p "Validating File" }
      postprocess Proc.new  { |o| p "File has been uploaded in system" }
    end

    flowstate :open do
      postprocess :notify_user
      postprocess Proc.new  { |o| p "File has been closed" }
    end

    flowstate :closed do
      preprocess Proc.new  { |o| p "File closed" }
      postprocess :notify_user
    end

    action :upload do
      transitions :from => :init, :to => :uploaded, :condition => :file_parsable?
    end

    action :process do
      transitions :from => :uploaded, :to => [:open, :closed], :branch => :choose_branch
    end

    action :close do
      transitions :from => [:init,:uploaded,:open], :to => :closed, :condition => :file_close?
    end

  end

  def choose_branch
    6 > 5 ? :open : :closed
  end

  def notify_user
    p "Notifying User!"
  end

  def file_parsable?
    3 > 2 ? true : false
  end

  def file_close?
    1 > 0 ? true : false 
  end
end