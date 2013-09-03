module Stex
  module Acts
    module DataTable
      class SessionHelper
        def initialize(session, controller_path, action, model_name)
          @session         = session
          @controller_path = controller_path
          @action          = action
          @model           = model_name.to_s.classify.constantize
        end

        def controller_path
          @controller_path
        end

        def action_name
          @action
        end

        def model
          @model
        end

        #----------------------------------------------------------------
        #                           Filters
        #----------------------------------------------------------------

        # Adds a filter for a specific view
        # If a filter for this group is already set, the new filter
        # will override the existing one.
        #--------------------------------------------------------------
        def add_filter(group, scope, args)
          controller_key = action_key(controller_path, action_name)
          @session[:scope_filters] ||= {}
          @session[:scope_filters][controller_key] ||= {}

          args = hash_keys_to_strings(args) if args

          @session[:scope_filters][controller_key][group.to_s] = {scope.to_s => args}
        end

        # Removes an active filter. As only one filter per group can
        # be active at a time, we can simply delete the whole group.
        # If all filters are deleted, we can also remove the namespaces
        # in the session
        #--------------------------------------------------------------
        def remove_filter(group)
          controller_key = action_key(controller_path, action_name)
          return unless @session[:scope_filters][controller_key]
          @session[:scope_filters][controller_key].delete(group.to_s)
          @session[:scope_filters].delete(controller_key) if @session[:scope_filters][controller_key].empty?
          @session.delete(:scope_filters) if @session[:scope_filters].empty?
        end

        # Removes all filters from the given controller + action
        #--------------------------------------------------------------
        def remove_all_filters
          @session[:scope_filters].delete(action_key(controller_path, action_name))
        end

        # Returns all active filters for the given controller and action
        #--------------------------------------------------------------
        def active_filters
          return {} unless @session[:scope_filters]
          @session[:scope_filters][action_key(controller_path, action_name)] || {}
        end

        # Checks if the given filter is currently active
        #--------------------------------------------------------------
        def active_filter?(group, scope, args)
          active = active_filters
          args = hash_keys_to_strings(args) if args

          active.any? &&
              active[group.to_s] &&
              active[group.to_s].has_key?(scope.to_s) &&
              (active[group.to_s][scope.to_s].to_a - args.to_a).empty? #sometimes the session hash contains {:raise => true}, whereever it comes from...
        end

        #----------------------------------------------------------------
        #                         Column Sorting
        #----------------------------------------------------------------

        # Replaces all current sorting columns with the new one
        #--------------------------------------------------------------
        def replace_sorting_column(model_name, column_name)
          args = generate_sorting_arguments(model_name, column_name)
          return unless args[:model].column_names.include?(column_name.to_s)

          @session[:column_sorting] ||= {}
          @session[:column_sorting][args[:key]] = [[args[:column], 'ASC']]
        end

        # Adds a new sorting column to the current controller and action
        #--------------------------------------------------------------
        def add_or_toggle_sorting_column(model_name, column_name)
          args = generate_sorting_arguments(model_name, column_name)

          return unless args[:model].column_names.include?(column_name.to_s)

          @session[:column_sorting] ||= {}
          @session[:column_sorting][args[:key]] ||= []

          existing_entry = @session[:column_sorting][args[:key]].assoc(args[:column])

          #Toggle the direction
          if existing_entry
            idx = @session[:column_sorting][args[:key]].index(existing_entry)

            direction = existing_entry.last == 'ASC' ? 'DESC' : 'ASC'

            @session[:column_sorting][args[:key]].delete(existing_entry)

            @session[:column_sorting][args[:key]].insert(idx, [args[:column], direction])
          else
            #Simply append the new column to the sorting list
            @session[:column_sorting][args[:key]] << [args[:column], 'ASC']
          end
        end

        # Removes a sorting column from current controller and action
        #--------------------------------------------------------------
        def remove_sorting_column(model_name, column_name)
          args = generate_sorting_arguments(model_name, column_name)
          return if @session[:column_sorting].nil? || @session[:column_sorting].empty?
          return unless @session[:column_sorting].has_key?(args[:key])

          existing_entry = @session[:column_sorting][args[:key]].assoc(args[:column])
          @session[:column_sorting][args[:key]].delete(existing_entry) if existing_entry

          #Remove the controller namespace from the session if it's empty
          @session[:column_sorting].delete(args[:key]) if @session[:column_sorting][args[:key]].empty?
        end

        # Returns all sorting columns as a string
        #--------------------------------------------------------------
        def sorting_columns_string
          controller_key = action_key(controller_path, action_name)
          return nil if @session[:column_sorting].nil? || @session[:column_sorting].empty?
          return nil unless @session[:column_sorting].has_key?(controller_key)

          @session[:column_sorting][controller_key].map {|column_and_direction| column_and_direction.join(' ')}.join(', ')
        end

        # Returns the current sorting direction for a given column
        # or nil if this column is currently not active.
        #--------------------------------------------------------------
        def sorting_direction(model_name, column_name)
          args = generate_sorting_arguments(model_name, column_name)

          return nil if @session[:column_sorting].nil? || @session[:column_sorting].empty?
          return nil unless @session[:column_sorting].has_key?(args[:key])
          entry = @session[:column_sorting][args[:key]].assoc(args[:column])
          entry ? entry.last : nil
        end

        # loads the sorting defaults for the current action
        # Parameters==
        #   defaults:: [['users.last_name', 'ASC'], ['users.first_name', 'ASC']]
        #--------------------------------------------------------------
        def load_sorting_defaults(defaults = [])
          return if defaults.empty?
          controller_key = action_key(controller_path, action_name)
          @session[:column_sorting] = {}
          @session[:column_sorting][controller_key] = defaults
        end

        private

        def generate_sorting_arguments(model_name, column_name)
          model = model_name.to_s.classify.constantize
          {
              :model  => model,
              :key    => action_key(controller_path, action_name),
              :column => "#{model.table_name}.#{column_name}"
          }
        end

        def action_key(controller, action)
          [controller.gsub("/", "_"), action].join('_')
        end

        def hash_keys_to_strings(hash)
          new_hash = {}
          hash.each do |key, value|
            new_hash[key.to_s] = value
          end
          new_hash
        end
      end
    end
  end
end