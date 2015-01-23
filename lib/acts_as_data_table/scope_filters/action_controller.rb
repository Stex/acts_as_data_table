module Acts
  module DataTable
    module ScopeFilters
      module ActionController
        def self.included(base)
          base.send :extend, ClassMethods
        end

        module ClassMethods

        end
      end
    end
  end
end
