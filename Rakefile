require "bundler/gem_tasks"

desc "Compiles the plugin's coffeescript to a js file"
task :make do |t|
  input_files      = Dir['./app/coffeescripts/**/*.coffee']
  output_directory = './generators/acts_as_data_table/templates/assets/js'

  input_files.each do |file|
    `coffee -c --no-header -b  -o #{output_directory} #{file}`
  end
end
