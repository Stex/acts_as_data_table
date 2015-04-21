module Acts
  module DataTable
    module ScopeFilters
      module ActionController

        def self.included(base)
          base.send :extend, ClassMethods
        end

        module ClassMethods
          #
          # Adds scope filter support to this controller (or parts of it)
          #
          # @param [Hash] options
          #   Options to customize the behaviour
          #
          # @option options [Array<Symbol>] :only
          #   If given, filters are only applied to actions which are in the given array
          #
          # @option options [Array<Symbol>] :except
          #   If given, filters are only applied to actions which _not_ in the given array
          #
          # @option options [String, Symbol] :model
          #   The model name which will be used as filter base.
          #   If not given, the name is inferred from the controller name
          #
          def scope_filters(options = {})
            #Include on-demand methods
            include Acts::DataTable::Shared::ActionController::OnDemand

            #Add helper methods to this controller's views
            helper :acts_as_data_table

            model_name = (options.delete(:model) || self.name.underscore.split('/').last.sub('_controller', '')).to_s.camelize.singularize

            #Create a custom before filter
            around_filter(options) do |controller, block|

              sf_params = controller.request.params[:scope_filters]

              begin

                #Set current filters before adding/removing based on the current request
                #This is needed for certain actions within the session
                Acts::DataTable::ScopeFilters::ActionController.set_request_filters!(model_name, controller.acts_as_data_table_session.active_filters)

                #Ensure that any scope filter related params are given and
                #that the given action is valid (add a filter, remove a filter, remove all filters)
                if sf_params.present? && %w(add remove reset).include?(sf_params[:action])
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
                Acts::DataTable::ScopeFilters::ActionController.set_request_filters!(model_name, controller.acts_as_data_table_session.active_filters)
                block.call
              ensure
                Acts::DataTable::ScopeFilters::ActionController.clear_request_filters!
              end
            end
          end
        end

        #
        # Saves the current request's active filters to the thread space
        #
        def self.set_request_filters!(model, filters)
          Acts::DataTable.ensure_nested_hash!(Thread.current, :scope_filters)

          current_scopes = filters.inject({}) do |h, (group, scope)|
            h[group] = [scope.keys.first, scope[scope.keys.first]]
            h
          end

          Thread.current[:scope_filters] = {:model => model.to_s, :filters => current_scopes}
        end

        #
        # Fetches the current request's filter data from the thread space
        #
        def self.get_request_data
          Acts::DataTable.lookup_nested_hash(Thread.current, :scope_filters)
        end

        #
        # Fetches the current request's active filters from the thread space
        #
        def self.get_request_filters
          self.get_request_data[:filters]
        end

        #
        # @return [ActiveRecord::Base] the model used for filtering in the current request
        #
        def self.get_request_model
          model = self.get_request_data[:model]
          model.camelize.constantize
        end

        #
        # Clears all active filters from the thread space.
        #
        def self.clear_request_filters!
          Thread.current[:scope_filters] = nil
        end
      end
    end
  end
end
