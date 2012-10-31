desc "Runs bacon tests without code coverage"
task :bacon do
  require File.expand_path('spec/init.rb')
end