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

            defaults = options.delete(:default) ||= {}

            around_filter(options) do |controller, block|

              af_params = controller.request.params[:sortable_columns]

              begin
                #Ensure that any scope filter related params are given and
                #that the given action is valid (add a filter, remove a filter, remove all filters)
                if af_params.present? && %w(add remove reset).include?(sf_params[:action])
                  case sf_action = sf_params[:action].to_s
                    when 'add'
                      #Ensure that a group and a scope name are given
                      if [:group, :scope].all? { |p| sf_params[p].present? }
                        unless controller.acts_as_data_table_session.add_filter(sf_params[:group], sf_params[:scope], sf_params[:args])
                          #TODO: add error message if the validation failed or the filter was not available
                        end
                      end
                    when 'remove'
                      #Ensure that a group and a filter name are given
                      if sf_params[:group].present?
                        controller.acts_as_data_table_session.remove_filter!(sf_params[:group])
                      end
                    when 'reset'
                      controller.acts_as_data_table_session.remove_all_filters!
                    else
                      raise ArgumentError.new "Invalid scope filter action '#{sf_action}' was given."
                  end
                end

                #Set the updated filters
                Acts::DataTable::SortableColumns::ActionController.set_request_sort_columns!(controller.acts_as_data_table_session.active_sort_columns)
                block.call
              ensure
                Acts::DataTable::SortableColumns::ActionController.clear_request_sort_columns!
              end

            end



          end

        end

        module OnDemand

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