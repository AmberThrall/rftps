task default: %w[run]

task :run do
    ruby 'bin/rftps'
end

task :test do
    if gem 'minitest'
        ruby 'test/helper.rb'
    else
        "Tests not run. Missing minitest dependency."
    end
end

begin
    require 'rubocop/rake_task'

    RuboCop::RakeTask.new(:lint) do |task|
        task.patterns = [ 'lib/**/*.rb', 'bin/rftps' ]
        task.fail_on_error = false
    end
rescue LoadError
    task default: %w[test]
end
