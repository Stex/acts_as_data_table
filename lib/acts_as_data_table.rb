require 'acts_as_data_table/version'

require 'acts_as_data_table/multi_column_scopes'

require 'acts_as_data_table/shared/session'
require 'acts_as_data_table/shared/action_controller'

require 'acts_as_data_table/scope_filters/action_controller'
require 'acts_as_data_table/scope_filters/active_record'
require 'acts_as_data_table/scope_filters/validator'

require 'acts_as_data_table/sortable_columns/action_controller'
require 'acts_as_data_table/sortable_columns/active_record'
require 'acts_as_data_table/scope_filters/form_helper'

#Sortable Column Renderers
require 'acts_as_data_table/sortable_columns/renderers/default'
require 'acts_as_data_table/sortable_columns/renderers/bootstrap2'
require 'acts_as_data_table/sortable_columns/renderers/bootstrap3'

module ActsAsDataTable
end

module Acts
  module DataTable
    I18n_LOCALES = %w(en)

    def self.log(level, message)
      Rails.logger.send(level, "Acts::DataTable [#{level}] -- #{message}")
    end

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
        return nil if h[key].nil?
        h = h[key]
      end
      h
    end

    #
    # Retrieves a value from the gem's locale namespace.
    # If there are no translations for the application's locale, the
    # english versions are used.
    #
    def self.t(key, options = {})
      locale = I18n_LOCALES.include?(I18n.locale.to_s) ? I18n.locale : 'en'
      I18n.t(key, options.merge({:scope => 'acts_as_data_table', :locale => locale}))
    end
  end
end

ActiveRecord::Base.class_eval do
  include Acts::DataTable::MultiColumnScopes
  include Acts::DataTable::ScopeFilters::ActiveRecord
  include Acts::DataTable::SortableColumns::ActiveRecord
end

ActionController::Base.class_eval do
  include Acts::DataTable::ScopeFilters::ActionController
  include Acts::DataTable::SortableColumns::ActionController
end
