module Stex
  module Acts
    module Searchable
      class SessionHelper
        def initialize(session, controller_path, action)
          @session = session
          @controller_path = controller_path
          @action = action
        end

        def controller_path
          @controller_path
        end

        def action_name
          @action
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

        private

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