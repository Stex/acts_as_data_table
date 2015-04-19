module Acts
  module DataTable
    module SortableColumns
      module ActionController
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods

          def sortable_columns(options = {})




          end

        end
      end
    end
  end
end