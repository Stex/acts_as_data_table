require 'searchable'
require 'named_scope_filters'
require 'acts_as_data_table/session_helper'
#require 'acts_as_searchable/class_linkage_graph'
#require 'acts_as_searchable/configuration'
#require 'acts_as_searchable/data_holder'

ActiveRecord::Base.class_eval do
  include Stex::Acts::DataTable
  include Stex::Acts::DataTable::NamedScopeFilters::ActiveRecord
end

ActionController::Base.class_eval do
  include Stex::Acts::DataTable::NamedScopeFilters::ActionController
end