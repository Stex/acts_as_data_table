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
          #   - Symbol: The symbol is interpreted as I18n.t() key within the scope 'activerecord.scope_filters.model.scope'
          #             Possible scope arguments are passed in as strings
          #   - Proc: The given proc is executed with a hash containing the given arguments (if any)
          #
          # @option options [Proc, Symbol] :validations (nil)
          #   A validation method for the scope filter. The filter is only applied if the validation method returns +true+
          #   This is useful if e.g. a scope needs two dates to work correctly and should only be applied
          #   if the dates have the correct format.
          #   If a Symbol is given, the system expects a method with that name
          #   to be defined as class method in the model class.
          #
          def has_scope_filter(group, scope, options = {})
            #Load additional helper methods into the model class
            extend Acts::DataTable::ScopeFilters::ActiveRecord::OnDemand

            model = self

            unless scopes.has_key?(:with_scope_filters)
              # Generate the named scope which will handle the dynamically given filters
              # A filter is only applied if a given validation method returns +true+
              # The +filters+ argument is a hash of the structure {group_name => [scope_name, *args]}
              named_scope :with_scope_filters, lambda { |filters|
                scope_chain = self
                filters.each do |group_name, scope_and_args|
                  scope_name = scope_and_args.first
                  args       = scope_and_args[1..-1]

                  #Filters should already be validated when they are added through
                  #the controller, this check is to ensure that no invalid filter is
                  #ever applied to the model as final protection.
                  if Acts::DataTable::ScopeFilters::ActiveRecord.valid_scope_filter?(model, group_name, scope_name, args)
                    scope_chain = scope_chain.send(scope_name, *args)
                  end
                end

                conditions = scope_chain.current_scoped_methods[:find][:conditions]
                {:conditions => conditions}
              }
            end

            Acts::DataTable::ScopeFilters::ActiveRecord.register_filter(self, group, scope, options)
          end
        end

        #
        # This module is only included if at least one filter group was added to the model
        # to avoid pollution in other models.
        #
        module OnDemand

        end

        #
        # Registers a filter in the system which is then accessed when applying filters through a scope
        # The filters are kept in this module as it can be accessed from everywhere,
        # while a model class may not be known from within these methods.
        #
        # @param [ActiveRecord::Base] model
        #   The model class the scope to be added belongs to
        #
        # @param [String, Symbol] group
        #   The group name the scope belongs to within the +model+
        #
        # @param [String, Symbol] scope
        #   The scope name, it has to be a valid (named) scope within +model+
        #
        # @param [Hash] options
        #   Filter options, see #has_scope_filter
        #
        def self.register_filter(model, group, scope, options)
          unless model.scopes.has_key?(scope.to_sym)
            raise ArgumentError.new "The scope '#{scope}' in group '#{group}' does not exist in the model class '#{model.to_s}'"
          end

          @@registered_filters ||= {}
          Acts::DataTable.ensure_nested_hash!(@@registered_filters, model.to_s, group.to_s)
          @@registered_filters[model.to_s][group.to_s][scope.to_s] = options
        end

        #
        # @see #register_filter for arguments
        #
        # @return [Hash, NilClass] options given for the chosen filter if available
        #
        def self.filter_options(model, group, scope)
          Acts::DataTable.lookup_nested_hash(@@registered_filters, model.to_s, group.to_s, scope.to_s)
        end

        #
        # @see #register_filter for arguments
        #
        # @return [TrueClass, FalseClass] +true+ if the given filter passed the validations
        #
        def self.valid_scope_filter?(model, group, scope, args)
          case proc = self.filter_options(model, group, scope)[:validations]
            when Proc
              proc.call(args)
            when Symbol
              self.send(proc, args)
            when NilClass
              true
            else
              raise ArgumentError.new("An invalid validations method was given for the scope '#{scope}' in group '#{group}' of model '#{model.to_s}'")
          end
        end


      end
    end
  end
end
