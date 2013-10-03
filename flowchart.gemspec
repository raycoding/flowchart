Gem::Specification.new do |f|
  f.name          = 'flowchart'
  f.version       = '1.0.1'
  f.date          = %q{2013-09-27}
  f.summary       = %q{State Flow and Work Flow Process gem in Ruby}
  f.description   = %q{Flowchart is a StateFlow(states-actions-transitions) and WorkFlow(users-assigned-assigners) process design for Non-ActiveRecord and ActiveRecord Model in Ruby or Rails}
  f.authors       = %q{Shuddhashil Ray}
  f.email         = %q{rayshuddhashil@gmail.com}
  f.files         = ["README.rdoc","LICENSE.txt","flowchart.gemspec","lib/flow_chart.rb","lib/flowchart/flow_processor.rb","lib/flowchart/work_processor.rb","sample/sample_state.rb","sample/sample_work.rb","sample/sample_flowchart.rb"]
  f.require_paths = ["lib"]
  f.homepage      = %q{http://github.com/raycoding/flowchart}
  f.license       = "MIT"
end