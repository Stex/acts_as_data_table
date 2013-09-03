require 'rake'
require 'rake/testtask'
require 'rdoc/task'

desc 'Default: run unit tests.'
task :default => :test

desc "Compiles the plugin's coffeescript to a js file"
task :make do |t|
  input_files      = ['./app/coffeescripts/acts_as_data_table.coffee']
  output_directory = './generators/acts_as_data_table/templates/assets/js'

  input_files.each do |file|
    `coffee -l -c -o #{output_directory} #{file}`
  end
end

desc 'Test the acts_as_searchable plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_searchable plugin.'
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsSearchable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
