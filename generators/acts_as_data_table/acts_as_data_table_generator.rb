class ActsAsDataTableGenerator < Rails::Generator::NamedBase
  def manifest
    record do |m|
      m.file File.join('assets', 'js', 'acts_as_data_table.js'), File.join('public', 'javascripts', 'acts_as_data_table.js')
    end
  end

  protected

  def banner
    "Usage: #{$0} acts_as_data_table js"
  end
end
