module Acts
  module DataTable
    module Shared
      module ActionController
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

        end

        module OnDemand
          def self.included(base)
            base.helper_method :acts_as_data_table_session
          end

          def acts_as_data_table_session
            @acts_as_data_table_session ||= Acts::DataTable::Shared::Session.new(session, controller_path, action_name)
          end
        end
      end
    end
  end
end