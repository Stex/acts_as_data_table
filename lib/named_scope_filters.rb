module Stex
  module Acts
    module Searchable
      module NamedScopeFilters
        module ActiveRecord
          def self.included(base)
            base.send :extend, ClassMethods
          end

          module ClassMethods
            # Generates methods to automatically combine named scopes
            # based on the given input
            # Arguments are all named scopes you'd like to include into
            # The parameter includes all filters which may be used by the automatic
            # data filtering later.
            # {:group_name => [scope1, scope2, [scope_with_arguments, arg1, arg2], scope4]}
            #--------------------------------------------------------------
            def has_named_scope_filters(filter_groups = {})
              if filter_groups.empty? #No groups given, no filters created
                throw 'is_named_scope_filterable needs arguments to run.'
              end

              #Convert filters
              filter_groups.each do |group_name, filters|
                filters.map! {|f| Array(f)}
              end

              #Check if all given named scopes actually exist
              filter_groups.each do |name, named_scopes|
                named_scopes.each do |ns|
                  scope_name = ns.first
                  throw "The scope '#{scope_name}' in group '#{name}' does not exist." unless scopes.has_key?(scope_name)
                end
              end

              #Create a method to test if a given filter is valid
              define_singleton_method 'named_scope_filter?' do |group, name, args|
                filter_groups[group] && filter_groups[group].assoc(name).present?
              end

              #Generate a method to actually apply the various filters to the current
              #model.
              define_singleton_method(:apply_scope_filters) do |scope_filter_groups|
                result = self
                scope_filter_groups.each do |group_name, scope_filters|
                  set_scopes = filter_groups[group_name.to_sym]
                  scope_filters.each do |filter, args|
                    set_filter = set_scopes.assoc(filter.to_sym)
                    arg_names  = set_filter.drop(1)
                    scope_args = arg_names.map {|a| args[a.to_s]}
                    result = result.send(set_filter.first, *scope_args)
                  end
                end
                result
              end

              #Generate a method to label applied filters.
              #This method only does default labelling and will most likely be
              #overridden in the actual model
              define_singleton_method(:scope_caption) do |scope_name, args|
                I18n.t(scope_name, :scope => "activerecord.scopes.#{table_name}", :default => scope_name)
              end
            end

            #def is_named_scope_sortable(*args)
            #  options = args.pop if args.last.is_a?(Hash)
            #  processed_args = args.map {|a| generate_sortable_columns_and_includes(a)}.flatten
            #
            #  column_names = []
            #  unfiltered_includes = []
            #
            #  processed_args.each do |arg|
            #    column_names += arg[:columns]
            #    unfiltered_includes += arg[:includes]
            #  end
            #
            #  #TODO: filter longer include chains, have to get a real example first.
            #
            #
            #  1
            #end


            ## Processes arguments for the sortable generator
            ## Returns column names and necessary includes
            ##--------------------------------------------------------------
            #def generate_sortable_columns_and_includes(arg, model = self)
            #  columns  = []
            #  includes = []
            #  #Associations from the current model
            #  if arg.is_a?(Hash)
            #    arg.each do |association_name, columns_and_associations|
            #      association_endpoint = Stex::Acts::Searchable::DataHolder.graph.associations_for(model)[association_name.to_s]
            #      Array(columns_and_associations).each do |new_arg|
            #        processed_arg = generate_sortable_columns_and_includes(new_arg, association_endpoint)
            #        columns += processed_arg[:columns]
            #        if processed_arg[:includes].any?
            #          includes << {association_name => processed_arg[:includes]}
            #        else
            #          includes << association_name if processed_arg[:columns].any?
            #        end
            #      end
            #    end
            #  else
            #    columns << "#{model.table_name}.#{arg}" if model.column_names.include?(arg.to_s)
            #  end
            #
            #  {:columns => columns, :includes => includes}
            #end
          end
        end

        module ActionController
          def self.included(base)
            base.send :extend, ClassMethods
          end

          module ClassMethods
            # Generates the necessary controller methods to add and remove filters
            # Expects the model name and a list of methods the filters will be used for
            # Important: Do not use the model constant (e.g. User), it might break
            # your database setup.
            #
            # == Examples
            # scope_filters :user, :index
            #--------------------------------------------------------------
            def scope_filters(model_name, *args)
              helper_method :searchable_session

              before_filter :add_scope_filter, :only => args
              before_filter :remove_scope_filter, :only => args
              before_filter :remove_all_scope_filters, :only => args
              before_filter :load_active_scope_filters, :only => args

              helper :acts_as_searchable

              # Adds a filter to the current data table. Works with the
              # named scope filterable plugin.
              # Expects the following params to be set:
              #  :scope_filters =>
              #   :group -- The group the named scope belongs to
              #   :name  -- The named scope name inside the group
              #   :args  -- Array of arguments to be passed to the named scope
              # If any of these params (except filter_args which is optional)
              # is not set, the filter will not be added.
              #--------------------------------------------------------------
              define_method(:add_scope_filter) do
                return if params[:scope_filters].blank?
                return if [:group, :name].any? { |p| params[:scope_filters][p].blank? }

                group = params[:scope_filters][:group].to_sym
                name  = params[:scope_filters][:name].to_sym
                args  = params[:scope_filters][:args]
                args  = nil if args.blank? #No empty string here

                model = model_name.to_s.classify.constantize

                #If the given filter is not valid, do not add it to the filters list
                return unless model.named_scope_filter?(group, name, args)
                searchable_session.add_filter(group, name, args)
              end

              # Removes a filter from the current data table.
              # Expects the following params to be set:
              # :scope_filters =>
              #   :group -- The group the named scope belongs to
              #   :remove => true
              #--------------------------------------------------------------
              define_method(:remove_scope_filter) do
                return if params[:scope_filters].blank?
                return if params[:scope_filters][:remove].blank?
                searchable_session.remove_filter(params[:scope_filters][:remove])
              end

              # Removes all filters from the current controller and action
              #--------------------------------------------------------------
              define_method(:remove_all_scope_filters) do
                return if params[:scope_filters].blank?
                return if params[:scope_filters][:remove_all].blank?
                searchable_session.remove_all_filters
              end

              # Session Helper instance accessor
              #--------------------------------------------------------------
              define_method(:searchable_session) do
                @searchable_session = Stex::Acts::Searchable::SessionHelper.new(session, controller_path, action_name, model_name)
              end

              # Loads the active filters into an instance variable, just in case
              # that naming changes later
              #--------------------------------------------------------------
              define_method(:load_active_scope_filters) do
                @loaded_scope_filters = searchable_session.active_filters
              end

              #Make the helper methods private so rails does not handle them as actions
              private :add_scope_filter, :remove_scope_filter, :searchable_session, :load_active_scope_filters
            end

            # Adds methods for automatic column sorting to the controller
            # Parameters:
            # actions_and_defaults:: Hash of actions which will be used to
            #         display sortable content and their initial sorting
            #         columns.
            #
            # == Example
            #   column_sorting :index => [['users.last_name', 'ASC'], ['users.first_name', 'ASC']]
            #--------------------------------------------------------------
            def column_sorting(actions_and_defaults = {})

              before_filter :add_or_toggle_sorting_column, :only => actions_and_defaults.keys
              before_filter :replace_sorting_column, :only => actions_and_defaults.keys
              before_filter :remove_sorting_column, :only => actions_and_defaults.keys
              before_filter :load_sorting_columns, :only => actions_and_defaults.keys

              param_namespace = :sorting_columns

              # Adds a sorting column to the current sorting columns or
              # toggles its direction if it is already part of the
              # active sorting.
              #
              # Parameters
              #   :sorting_columns => {
              #     :model_name  => 'sale',
              #     :column_name => 'reference'
              #   }
              #--------------------------------------------------------------
              define_method(:add_or_toggle_sorting_column) do
                return if params[param_namespace].blank?
                return if [:add, :model_name, :column_name].select {|p| params[param_namespace][p].blank?}.any?
                searchable_session.add_or_toggle_sorting_column(params[param_namespace][:model_name], params[param_namespace][:column_name])
              end

              # Replaces all current sorting columsn with the given one
              #--------------------------------------------------------------
              define_method(:replace_sorting_column) do
                return if params[param_namespace].blank?
                return if [:replace, :model_name, :column_name].select {|p| params[param_namespace][p].blank?}.any?
                searchable_session.replace_sorting_column(params[param_namespace][:model_name], params[param_namespace][:column_name])
              end

              # Removes a column from the current sorting columns
              #--------------------------------------------------------------
              define_method(:remove_sorting_column) do
                return if params[param_namespace].blank?
                return if [:remove, :model_name, :column_name].select {|p| params[param_namespace][p].blank?}.any?
                searchable_session.remove_sorting_column(params[param_namespace][:model_name], params[param_namespace][:column_name])
              end

              # Loads the current sorting string into an instance variable
              #--------------------------------------------------------------
              define_method(:load_sorting_columns) do
                @current_sorting_string = searchable_session.sorting_columns_string

                #If there is no user-set sorting, load the default sorting into the session.
                if @current_sorting_string.blank?
                  searchable_session.load_sorting_defaults(actions_and_defaults[action_name.to_sym])
                end

                @current_sorting_string = searchable_session.sorting_columns_string
              end

            end
          end
        end
      end
    end
  end
end