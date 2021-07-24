task default: %w[run]

def run_program(args = [])
    args.concat ARGV.drop(1 + ARGV.find_index { |s| s == '--' }) if ARGV.include? '--'
    ruby "rftps " + args.join(" ")
end

task :run do
    run_program
end

task :debug do
    args = [
        '--config etc/debug.conf',
        '--non-daemon'
    ]

    run_program(args)
end

task :test do
    if gem 'minitest'
        ruby 'test/helper.rb'
    else
        puts "Tests not run. Missing minitest dependency."
    end
end

begin
    require 'rubocop/rake_task'

    RuboCop::RakeTask.new(:lint) do |task|
        task.patterns = [ 'lib/**/*.rb', 'rftps' ]
        task.fail_on_error = false
    end
rescue LoadError
    task :lint do
        puts "Linter not run. Missing rubocop dependency."
    end
end
