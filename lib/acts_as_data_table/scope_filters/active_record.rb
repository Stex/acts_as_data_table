module Acts
  module DataTable
    module ScopeFilters
      module ActiveRecord
        def self.included(base)
          base.send :extend, ClassMethods
        end

        module ClassMethods
          #
          # Generates a scope filter in the given group, meaning that only one of the
          # filters in the same group may be active at one time.
          #
          # @param [String, Symbol] group
          #   The group name the new filter should be generated in
          #
          # @param [String, Symbol] scope
          #   The scope name the filter depends on
          #
          # @param [Hash] options
          #   Additional options to customize the generated filter
          #
          # @option options [Array<String, Symbol>] :args ([])
          #   Arguments needed by the scope. This is the case if the scope consists
          #   of a lambda object.
          #   The argument names have to be given in the same order as the scope function's
          #   formal parameters.
          #
          # @option options [Symbol, String, Proc] :caption (+:scope+)
          #   The caption displayed if the filter is used in the application
          #   The caption is either hardcoded or interpreted based on the given type:
          #
          #   - String: The given string is used as is
          #   - Symbol: The symbol is interpreted as I18n.t() key within the scope 'activerecord.scope_filters.group.scope'
          #             Possible scope arguments are passed in as strings
          #   - Proc: The given proc is executed with a hash containing the given arguments (if any)
          #
          # @option options [Proc] :validations (nil)
          #   A validation method for the scope filter. The filter is only applied if the validation method returns +true+
          #   This is useful if e.g. a scope needs two dates to work correctly and should only be applied
          #   if the dates have the correct format.
          #
          def has_scope_filter(group, scope, options = {})
            #Load additional helper methods into the model class
            extend Acts::DataTable::ScopeFilters::ActiveRecord::OnDemand

            unless scopes.has_key?(:with_scope_filters)
              named_scope :with_scope_filters, lambda { |filters|
                                               Event.future.with_sales.current_scoped_methods
                                           }
            end

            @@scope_filter_groups               ||= {}
            @@scope_filter_groups[group.to_sym] ||= {}

            #Check if the scope is valid
            unless scopes.has_key?(scope.to_sym)
              raise ArgumentError.new "The scope '#{scope}' in group '#{group_name}' does not exist in the model class '#{self.to_s}'"
            end

            #Save the given scope and its options
            @@scope_filter_groups[group.to_sym][scope.to_sym] = options
          end
        end

        #
        # This module is only included if at least one filter group was added to the model
        # to avoid pollution in other models.
        #
        module OnDemand

        end

        #
        # @return [TrueClass, FalseClass] +true+ if the given filter passed the validations
        #
        def self.valid_filter?(group, filter, options)

        end
      end
    end
  end
end
