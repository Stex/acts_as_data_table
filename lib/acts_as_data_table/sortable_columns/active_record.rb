module Acts
  module DataTable
    module SortableColumns
      module ActiveRecord
        def self.included(base)

          base.named_scope :with_column_sorting, lambda {
            sort_columns = Acts::DataTable::SortableColumns::ActionController.get_current_sort_columns

            if sort_columns.any?
              sort_string = sort_columns.each {|col, dir| "#{col} #{dir}"}.join(', ')
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