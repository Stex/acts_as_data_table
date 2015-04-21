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
          # ----
          #
          # @option options [Array<String, Symbol>] :args ([])
          #   Arguments needed by the scope. This is the case if the scope consists
          #   of a lambda object.
          #   The argument names have to be given in the same order as the scope function's
          #   formal parameters.
          #
          # @option options [Symbol, String, Proc] :caption (nil)
          #   The caption displayed if the filter is used in the application
          #   The caption is either hardcoded or interpreted based on the given type:
          #
          #   - String: The given string is used as is
          #   - Symbol: The system expects a function with the given name to be defined in the current model.
          #             It is called with 3 arguments:
          #               1. The group name
          #               2. The scope name
          #               3. The arguments the scope was called with (if any)
          #   - Proc: The given proc is executed with a hash containing the given arguments (if any)
          #
          #   If nothing is given, the default caption is used, meaining the system will use I18n.t
          #   to search for a defined scope name within the scope 'activerecord.scope_filters.model.SCOPE'
          #   Possible scope arguments are passed in as strings
          #
          # @option options [Proc, Symbol] :validations (nil)
          #   A validation method for the scope filter. The filter is only applied if the validation method returns +true+
          #   This is useful if e.g. a scope needs two dates to work correctly and should only be applied
          #   if the dates have the correct format.
          #   If a Symbol is given, the system expects a method with that name
          #   to be defined as class method in the model class.
          #
          #   The validation method is supposed to return an Array<String>
          #   containing the error messages or a simple boolean value.
          #
          # ----
          #
          # @example A filter group for locked and not locked records, expecting the scopes :locked and :not_locked to be present.
          #
          #     has_scope_filter :status, :locked
          #     has_scope_filter :status, :not_locked
          #
          # @example A full text search with one argument (scope: full_text, formal parameter: text)
          #
          #     has_scope_filter :quick_search, :full_text, [:text]
          #
          # @example A date range filter
          #
          #     has_scope_filter :date, :between, [:start_date, :end_date]
          #
          def has_scope_filter(group, scope, options = {})
            #Load additional helper methods into the model class
            extend Acts::DataTable::ScopeFilters::ActiveRecord::OnDemand

            model = self

            unless scopes.has_key?(:with_scope_filters)
              # Generate the named scope which will handle the dynamically given filters
              # A filter is only applied if a given validation method returns +true+
              named_scope :with_scope_filters, lambda {
                filters = Acts::DataTable::ScopeFilters::ActionController.get_request_filters

                scope_chain = self
                filters.each do |group_name, (scope, args)|

                  #Filters should already be validated when they are added through
                  #the controller, this check is to ensure that no invalid filter is
                  #ever applied to the model as final protection.
                  # TODO: Check if the filter is causing an exception (probably through a wrong valiation method)
                  #       And remove it in this case, adding an error to the log or the module.
                  if Acts::DataTable::ScopeFilters::ActiveRecord.valid_scope_filter?(model, group_name, scope, args)
                    actual_args = Acts::DataTable::ScopeFilters::ActiveRecord.actual_params(model, group_name, scope, args)
                    scope_chain = scope_chain.send(scope, *actual_args)
                  end
                end

                conditions = Acts::DataTable.lookup_nested_hash(scope_chain.current_scoped_methods, :find, :conditions)
                conditions ? {:conditions => conditions} : {}
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

        def self.registered_filters
          @@registered_filters ||= {}
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

          Acts::DataTable.ensure_nested_hash!(self.registered_filters, model.to_s, group.to_s)
          self.registered_filters[model.to_s][group.to_s][scope.to_s] = options
        end

        #
        # @see #register_filter for arguments
        #
        # @return [Hash, NilClass] options given for the chosen filter if available
        #
        def self.filter_options(model, group, scope)
          res = Acts::DataTable.lookup_nested_hash(self.registered_filters, model.to_s, group.to_s, scope.to_s)
          unless res
            raise ArgumentError.new("The scope '#{scope}' was expected to be defined in group '#{group}' of model '#{model}' but couldn't be found.")
          end
          res
        end

        #
        # @return [Array<String, Symbol>] the args set up when registering the given filter
        #
        # @see #filter_options for parameters
        #
        def self.filter_args(*args)
          self.filter_options(*args)[:args] || []
        end

        #
        # @return [Fixnum] the amount of formal parameters the scope is defined with
        #   Note that this will return 0 for no formal parameters which differs to the way
        #   ruby 1.8 handles lambda expressions (returning -1)
        #
        # @see #filter_options for parameters
        #
        def self.filter_arity(*args)
          self.filter_args(*args).size
        end

        #
        # @return [TrueClass, FalseClass] +true+ if the given filter was actually registered before.
        #
        # @see #filter_options for parameters
        #
        def self.registered_filter?(*args)
          !!(self.filter_options(*args))
        end

        #
        # Checks whether the given argument count matches the given scope filter's formal
        # parameter count.
        #
        # @return [TrueClass, FalseClass] +true+ if the given argument count is
        #   sufficient for the chosen filter.
        #
        def self.matching_arity?(model, group, scope, arg_count)
          self.filter_arity(model, group, scope) == arg_count
        end

        #
        # @see #register_filter for arguments
        #
        # @return [TrueClass, FalseClass] +true+ if the given filter passed the validations
        #   It also checks whether the given argument count matches the amount of
        #   formal parameters specified for the filter.
        #
        def self.valid_scope_filter?(*args)
          self.validation_errors(*args).empty?
        end

        #
        # Validates the given scope filter and returns possible error messages
        #
        # @see #register_filter for arguments
        #
        def self.validation_errors(model, group, scope, args)
          #If they match, check the actual validation method
          case proc = self.filter_options(model, group, scope)[:validations]
          when Proc
            result = proc.call(args)
          when Symbol
            if model.respond_to?(proc)
              result = model.send(proc, args)
            else
              raise ArgumentError.new "The method '#{proc}' was set up as scope filter validation method in model '#{model.name}', but doesn't exist."
            end
          when NilClass
            result = true
          else
            raise ArgumentError.new "An invalid validations method was given for the scope '#{scope}' in group '#{group}' of model '#{model.name}'"
          end

          #If the result is already an array of error messages, we can simply return it.
          #Otherwise, we have to generate an error array based on the boolean result
          #the validation method produced.
          if result.is_a?(Array)
            result
          else
            result ? [] : [Acts::DataTable.t('scope_filters.validations.general_error')]
          end
        end

        #
        # @return [String] The scope filter caption for the given scope
        # @see #has_scope_filter for more information about how the caption is generated.
        #
        def self.scope_filter_caption(model, group, scope, args)
          args ||= {}
          case caption = self.filter_options(model, group, scope)[:captions]
          when String
            caption
          when Symbol
            if model.respond_to?(caption)
              model.send(caption, group, scope, args)
            else
              raise ArgumentError.new "The method '#{caption}' was set up as scope filter caption method in model '#{model.name}', but doesn't exist."
            end
          when Proc
            caption.call(args)
          else
            options = {:scope => "activerecord.scope_filters.#{model.name.underscore}"}
            options.merge!(args.symbolize_keys)
            I18n.t(scope, options)
          end
        end

        #
        # @return [Array<Object>] The actual parameters for a scope call
        #   based on the registered filter and the given arguments.
        #   This method should be used to ensure the correct order
        #   of arguments when applying a scope.
        #
        # @example Actual parameter generation for a date range scope
        #
        #   #has_scope_filter :date, :between, [:start_date, :end_date]
        #   actual_params(model, :date, :between, {:end_date => '2015-04-01', :start_date => '2015-03-01'})
        #   #=> ['2015-03-01', '2015-04-01']
        #
        def self.actual_params(model, group, scope, args)
          res = []
          self.filter_args(model, group, scope).each do |arg_name|
            res << args.stringify_keys[arg_name.to_s]
          end
          res
        end
      end
    end
  end
end
