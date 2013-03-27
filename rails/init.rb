require 'searchable'
require 'named_scope_filters'
require 'acts_as_searchable/session_helper'

ActiveRecord::Base.class_eval do
  include Stex::Acts::Searchable
  include Stex::Acts::Searchable::NamedScopeFilters::ActiveRecord
end

ActionController::Base.class_eval do
  include Stex::Acts::Searchable::NamedScopeFilters::ActionController
end