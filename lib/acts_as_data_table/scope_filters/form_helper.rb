module Acts
  module DataTable
    module ScopeFilters
      class FormHelper
        def initialize(action_view, group, scope)
          @action_view = action_view
          @group       = group.to_s
          @scope       = scope.to_s
        end

        def text_field(arg, options = {})
          value        = options.delete(:value) || current_arg(arg)
          options[:id] = FormHelper.field_id(@group, @scope, arg)
          @action_view.text_field_tag(FormHelper.field_name(arg), value, options)
        end

        #
        # @return [TrueClass, FalseClass] +true+ if the current filter is currently active
        #
        def active?
          @action_view.acts_as_data_table_session.active_filter(@group) == @scope
        end

        #
        # @return [String] The URL to remove the current filter group from the active filters
        #
        def remove_url
          @action_view.url_for({:scope_filters => {:action => 'remove', :group => @group}})
        end

        #
        # @return [String] A generated field name for the given arg to be used in filter forms
        #
        def self.field_name(arg)
          "scope_filters[args][#{arg}]"
        end

        #
        # @return [String] A generated DOM id for the given group, scope and arg
        #
        def self.field_id(group, scope, arg)
          [group, scope, arg].map(&:to_s).join('_')
        end

        private

        #
        # Retrieves the current value for the given arg name from the session.
        # Also searches the current request's params if the arg couldn't be found in the session.
        # This is useful to keep given values in case of validation errors.
        #
        def current_arg(arg)
          Acts::DataTable.lookup_nested_hash(@action_view.acts_as_data_table_session.active_filters, @group, @scope.to_s, arg.to_s) ||
              Acts::DataTable.lookup_nested_hash(@action_view.params, :scope_filters, :args, arg)
        end

      end
    end
  end
end