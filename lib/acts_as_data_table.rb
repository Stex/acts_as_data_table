require 'acts_as_data_table/version'

require 'acts_as_data_table/multi_column_scopes'
#require 'acts_as_data_table/session_helper'

require 'acts_as_data_table/scope_filters/action_controller'
require 'acts_as_data_table/scope_filters/active_record'

module ActsAsDataTable
end

ActiveRecord::Base.class_eval do
  include Acts::DataTable::MultiColumnScopes
  include Acts::DataTable::ScopeFilters::ActiveRecord
end

ActionController::Base.class_eval do
  include Acts::DataTable::ScopeFilters::ActionController
end
