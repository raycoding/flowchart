# Example of a Non-ActiveRecord Class using FlowChart in Ruby - showing only Work Machine
# Require 'active_record'
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

class SampleWork
	include FlowChart
  require 'active_record'
	attr_accessor :assigned_to,:assigned_by
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

end