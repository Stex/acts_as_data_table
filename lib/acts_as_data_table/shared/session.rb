module Acts
  module DataTable
    module Shared
      class Session

        def initialize(session, controller_path, action_name)
          @session         = session
          @controller_path = controller_path
          @action_name     = action_name
        end

        def sf_session
          @session[:scope_filters] ||= {}
        end

        def sc_session
          @session[:sortable_columns] ||= {}
        end

        def model
          Acts::DataTable::ScopeFilters::ActionController.get_request_model
        end

        def errors
          @errors ||= []
        end

        #----------------------------------------------------------------
        #                        Filter Management
        #----------------------------------------------------------------

        #
        # @return [Hash] all active filters for the current controller action
        #   by the group they are registered in.
        #
        def active_filters
          sf_session[current_action_key] || {}
        end

        #
        # Checks whether the given filter is currently active
        # Note that it also checks if it is active with exactly the given arguments.
        #
        # @return [TrueClass, FalseClass] +true+ if the filter is active AND
        #   the given +args+ match the ones used in the filter.
        #
        def active_filter?(group, scope, args)
          args ||= {}
          used_args = Acts::DataTable.lookup_nested_hash(active_filters, group.to_s, scope.to_s)
          used_args && (args.stringify_keys.to_a - used_args.to_a).empty?
        end

        #
        # Adds a new filter to the current controller action
        # Before the filter is added, the following things are checked to ensure
        # that no invalid filter is added (which could cause reoccurring errors in the application)
        #
        #   1. The given +scope+ has to be registered in the currently used model
        #   2. The given arguments have to be sufficient for the given +scope+
        #   3. The +scope+ has to pass the set up validation check
        #
        # @param [String] group
        #   The group the given +scope+ is part of in the current #model
        #
        # @param [String] scope
        #   The scope name within +group+ and #model
        #
        # @param [Hash] args
        #   Arguments to be passed to the scope. They have to be in the format
        #   {arg_name => arg_value} as set up in the model. This is necessary
        #   to make validations as easy as possible.
        #
        def add_filter(group, scope, args)
          reset_errors!

          #Ensure that the argument hash is set properly. The following methods
          #might fail for filters which do not require arguments otherwise.
          args = {} unless args.is_a?(Hash)

          #Check whether the given filter was registered properly in the model
          unless Acts::DataTable::ScopeFilters::ActiveRecord.registered_filter?(model, group, scope)
            add_error Acts::DataTable.t('scope_filters.add_filter.filter_not_registered', :model => model.name, :group => group, :scope => scope)
            return false
          end
          
          #Check whether the given arguments are sufficient for the given filter
          unless Acts::DataTable::ScopeFilters::ActiveRecord.matching_arity?(model, group, scope, args.size)
            add_error Acts::DataTable.t('scope_filters.add_filter.non_matching_arity', :model => model.name, :group => group, :scope => scope)
            return false
          end

          #Run possible validation methods on the given filter and add generated error messages
          if (errors = Acts::DataTable::ScopeFilters::ActiveRecord.validation_errors(model, group, scope, args)).any?
            errors.each {|e| add_error(e)}
            return false
          end

          #Add the new filter to the session
          current_action_session[group.to_s] = {scope.to_s => args.stringify_keys}
          true
        end

        #
        # Removes the given filter group from the current controller action
        # It is sufficient to only specify the group here as only one filter in a group
        # may be active at a time.
        #
        def remove_filter!(group)
          current_action_session.delete(group.to_s)
        end

        #
        # Resets all filters for the current controller action
        #
        def remove_all_filters!
          sf_session[current_action_key] = {}
        end

        #----------------------------------------------------------------
        #                        Sortable Columns
        #----------------------------------------------------------------

        #
        # Adds or removes a column from the current sorting columns
        # This happens whenever the user decides to sort a table by multiple columns
        #
        def toggle_column!(model_name, column_name)

        end

        #
        # Changes the sorting direction for the given column
        #
        def change_direction!(model_name, column_name)

        end

        #
        # Replaces all current sorting columns with the given one
        #
        def set_base_column!(model_name, column_name)

        end

        #
        # Retrieves the current sorting direction for a given column.
        #
        # @return [String, NilClass] 'ASC' or 'DESC' if the given column
        #   is currently active, +nil+ otherwise
        #
        def sorting_direction(model_name, column_name)
          d = column_data(model_name, column_name)
          current_action_session(sc_session).assoc(d[:column]).try(:last)
        end

        #
        # @return [TrueClass, FalseClass] +true+ if the given column is currently
        #   used for sorting
        #
        def active_column?(model_name, column_name)
          !!sorting_direction(model_name, column_name)
        end

        private

        #
        # @return [ActiveRecord::Base] The constantized model
        #
        def get_model(model_name)
          model_name.camelize.constantize
        end

        #
        # @return [Hash] The constantized model and column name with table prefix
        #
        def column_data(model_name, column_name)
          m      = get_model(model_name)
          column = "#{m.table_name}.#{column_name}"
          {:model => m, :column => column}
        end

        def current_action_session(s = sf_session)
          s[current_action_key] ||= {}
        end

        #
        # Clears old error messages. This is useful whenever only error messages from
        # a current action should be retrieved.
        #
        def reset_errors!
          @errors = []
        end

        #
        # Adds an error message to the errors array
        #
        # @param [String] message
        #   The error message to be added.
        #
        def add_error(message)
          errors << message
        end

        #
        # Generates a key from the given controller and action name
        #
        def action_key(controller, action)
          [controller.gsub('/', '_'), action].join('_')
        end

        #
        # @see #action_key, uses the current controller path and action name
        #
        def current_action_key
          action_key(@controller_path, @action_name)
        end

      end
    end
  end
end