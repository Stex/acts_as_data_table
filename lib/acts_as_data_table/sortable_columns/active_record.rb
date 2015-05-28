module Acts
  module DataTable
    module SortableColumns
      module ActiveRecord
        extend ActiveSupport::Concern

        included do
          send :extend, ClassMethods
        end

        module ClassMethods
          #
          # Scope which applies the currently active sorting directions.
          # The sorting columns are automatically fetched from the current thread space,
          # however, it is also possible to pass these values in as first argument.
          # This should only be done if absolutely necessary, e.g. if
          # the calculation happens in a different time or thread as it would in a
          # background calculation.
          #
          def with_sortable_columns(sort_columns = nil)
            sort_columns ||= Acts::DataTable::SortableColumns::ActionController.get_request_sort_columns

            chain = current_scope

            sort_columns.each do |col, dir|
              chain = chain.order("#{col} #{dir}")
            end

            chain
          end
        end
      end
    end
  end
end