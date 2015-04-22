module Acts
  module DataTable
    module SortableColumns
      module ActionController
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods

          #
          # Sets up automatic column sorting for this controller
          #
          # @param [Hash] options
          #   Options to specify which controller actions should have column sorting
          #   and to customize the filter's behaviour.
          #   Options are everything that #around_filter would accept
          #
          # @option options [Hash] :default
          #   Default sorting columns for different actions.
          #   If none are specified for an action, the default order (usually 'id ASC') is used
          #
          # @example Set up automatic column sorting only for the index action
          #          with the default ordering "deleted_at ASC, name ASC"
          #
          #     sortable_columns :only => [:index], :default => {:index => [['deleted_at', 'ASC'], ['name', 'ASC']]}
          #
          def sortable_columns(options = {})
            #Include on-demand methods
            include Acts::DataTable::Shared::ActionController::OnDemand

            defaults = (options.delete(:default) || {}).stringify_keys

            around_filter(options) do |controller, block|

              af_params        = controller.request.params[:sortable_columns]
              request_defaults = defaults[controller.action_name.to_s] || []

              begin
                #Ensure that the given action is valid
                if af_params.present? && %w(toggle change_direction set_base set).include?(af_params[:action].to_s)
                  case af_action = af_params[:action].to_s
                    when 'toggle'
                      controller.acts_as_data_table_session.toggle_column!(af_params[:model], af_params[:column])
                    when 'change_direction'
                      controller.acts_as_data_table_session.change_direction!(af_params[:model], af_params[:column])
                    when 'set_base'
                      controller.acts_as_data_table_session.set_base_column!(af_params[:model], af_params[:column])
                    when 'set'
                      controller.acts_as_data_table_session.set_columns!(af_params[:columns])
                    else
                      raise ArgumentError.new "Invalid scope filter action '#{af_action}' was given."
                  end
                end

                #Set the defaults as sorting columns none were set by the user
                if controller.acts_as_data_table_session.active_columns.empty?
                  controller.acts_as_data_table_session.set_columns!(request_defaults)
                end

                #Set the updated filters
                Acts::DataTable::SortableColumns::ActionController.set_request_sort_columns!(controller.acts_as_data_table_session.active_columns)
                block.call
              ensure
                Acts::DataTable::SortableColumns::ActionController.clear_request_sort_columns!
              end

            end
          end
        end

        #
        # Retrieves the columns to order by for the current request from the thread space. This is used in the
        # model's scope, so no string has to be supplied in the controller action manually.
        #
        # @return [Array<String>] the columns and their sorting directions in the format
        #   [["col1", "dir1"], ["col2", "dir2"], ...]
        #
        def self.get_request_sort_columns
          Thread.current[:sortable_columns] || []
        end

        #
        # Sets the columns to order by for the current request
        # in the thread space
        #
        # @param [Array<String>] columns
        #
        def self.set_request_sort_columns!(columns)
          Thread.current[:sortable_columns] = columns
        end

        #
        # Deletes the current sort columns from the thread space
        #
        def self.clear_request_sort_columns!
          Thread.current[:sortable_columns] = nil
        end
      end
    end
  end
end