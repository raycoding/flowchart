# Example of a Non-ActiveRecord Class using FlowChart in Ruby - showing State Machine & Work Machine = Flowchart
# requires 'active_record' for Workflow
class User
  attr_accessor :email
  def initialize(email)
    @email=email
  end
end
u1=User.new("1@gmail.com")
u2=User.new("2@gmail.com")
u3=User.new("3@gmail.com")
u4=User.new("4@gmail.com")

class SampleFlowchart
  include FlowChart
  require 'active_record'
  attr_accessor :process_status
  attr_accessor :assigned_to,:assigned_by

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

  workchart do

    assigned_to_column :assigned_to
    assigned_by_column :assigned_by

    workowner :user do
      goal_time lambda{ 2.days }
      dead_line lambda{ 3.days }
    end

    delegate :feed_pairing_work
    delegate :feed_publishing_work
    delegate :confirmation_work
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