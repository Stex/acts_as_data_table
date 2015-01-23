module Acts
  module DataTable
    module SortableColumns
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods

      end
    end
  end
end
