module Acts
  module DataTable
    module SortableColumns
      module ActiveRecord
        def self.included(base)

          #
          # Scope which applies the currently active sorting directions.
          # The sorting columns are automatically fetched from the current thread space,
          # however, it is also possible to pass these values in as first argument.
          # This should only be done if absolutely necessary, e.g. if
          # the calculation happens in a different time or thread as it would in a
          # background calculation.
          #
          base.named_scope :with_sortable_columns, lambda {|*args|
            sort_columns   = args.first
            sort_columns ||= Acts::DataTable::SortableColumns::ActionController.get_request_sort_columns

            if sort_columns.any?
              sort_string = sort_columns.map {|col, dir| "#{col} #{dir}"}.join(', ')
              {:order => sort_string}
            else
              {}
            end
          }

        end



      end
    end
  end
end