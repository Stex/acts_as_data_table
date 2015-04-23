module Acts
  module DataTable
    module ScopeFilters
      module Validations

        def self.built_in_validation?(validation_name)
          self.singleton_methods(false).include?(validation_name.to_s)
        end

        def self.all_dates(args)
          result = []
          args.values.each do |d|
            date = Date.parse(d) rescue nil
            unless date
              result << Acts::DataTable.t('scope_filters.validations.invalid_date', :date => d)
            end
          end
          result
        end

      end
    end
  end
end