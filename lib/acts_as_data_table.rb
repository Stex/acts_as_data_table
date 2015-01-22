require 'acts_as_data_table/version'

require 'acts_as_data_table/multi_column_scopes'
require 'named_scope_filters'
require 'acts_as_data_table/session_helper'
#require 'acts_as_searchable/class_linkage_graph'
#require 'acts_as_searchable/configuration'
#require 'acts_as_searchable/data_holder'

module ActsAsDataTable
  # Your code goes here...
end

ActiveRecord::Base.class_eval do
  include Stex::Acts::DataTable::MultiColumnScopes
  include Stex::Acts::DataTable::NamedScopeFilters::ActiveRecord
end

ActionController::Base.class_eval do
  include Stex::Acts::DataTable::NamedScopeFilters::ActionController
end