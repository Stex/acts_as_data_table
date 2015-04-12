require 'acts_as_data_table/version'

require 'acts_as_data_table/multi_column_scopes'
#require 'acts_as_data_table/session_helper'

require 'acts_as_data_table/scope_filters/action_controller'
require 'acts_as_data_table/scope_filters/active_record'

module ActsAsDataTable
end

module Acts
  module DataTable
    def self.ensure_nested_hash!(hash, *keys)
      h = hash
      keys.each do |key|
        h[key] ||= {}
        h = h[key]
      end
    end

    def self.lookup_nested_hash(hash, *keys)
      return nil if hash.nil?

      h = hash
      keys.each do |key|
        return nil unless h[key]
        h = h[key]
      end
      h
    end
  end
end

ActiveRecord::Base.class_eval do
  include Acts::DataTable::MultiColumnScopes
  include Acts::DataTable::ScopeFilters::ActiveRecord
end

ActionController::Base.class_eval do
  include Acts::DataTable::ScopeFilters::ActionController
end
