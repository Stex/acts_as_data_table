module Acts
  module DataTable
    module ScopeFilters
      class Validator

        def initialize(model, group, scope, args)
          @model = model
          @group = group
          @scope = scope
          @args  = args
        end

        #
        # Validates the given scope filter and returns possible error messages
        #
        # @see {Acts::DataTable::ScopeFilters::ActiveRecord}#register_filter for arguments
        #
        def validate
          validations = Acts::DataTable::ScopeFilters::ActiveRecord.filter_options(@model, @group, @scope)[:validate]

          Array(validations).inject([]) do |res, proc|
            res += run_validation(proc)
            res
          end.uniq.compact
        end

        def valid?
          validate.empty?
        end

        private

        #----------------------------------------------------------------
        #                      Built-in Validations
        #----------------------------------------------------------------

        #
        # @return [TrueClass, FalseClass] +true+ if the given validation
        #  is a built-in one.
        #
        def built_in_validation?(validation_name)
          private_methods.include?("validate_#{validation_name}")
        end

        #
        # Runs a built-in validation
        #
        def built_in_validation(validation_name)
          send("validate_#{validation_name}")
        end

        #
        # Each of the given arguments has to be parseable by Date.parse
        #
        def validate_all_dates
          validate_all :invalid_date do |k, v|
            Date.parse(v) rescue nil
          end
        end

        #
        # Each of the given arguments has to be present (!blank?)
        #
        def validate_all_present
          validate_all :blank do |k, v|
            v.present?
          end
        end

        #
        # Validates that all given arguments with names of the format /[a-z]+_id/
        # actually refer to valid records in the system
        #
        def validate_record_existence
          validate_all :invalid_record do |k, v|
            m = /([a-z]+)_id/.match(k.to_s)
            if m
              model  = m[1].camelize.constantize
              !!model.find_by_id(v)
            else
              true
            end
          end
        end

        #----------------------------------------------------------------
        #                        Helper Methods
        #----------------------------------------------------------------

        def run_validation(proc)
          case proc
            when Proc
              result = proc.call(@args)
            when Symbol
              if built_in_validation?(proc)
                result = built_in_validation(proc)
              elsif @model.respond_to?(proc)
                result = @model.send(proc, @args)
              else
                raise ArgumentError.new "The method '#{proc}' was set up as validation method for the scope '#{@scope}' in group '#{@group}' of model '#{@model.name}', but doesn't exist."
              end
            when NilClass
              result = true
            else
              raise ArgumentError.new "An invalid validations method was given for the scope '#{@scope}' in group '#{@group}' of model '#{@model.name}'"
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

        def validate_all(error, &proc)
          @args.inject([]) do |res, (k, v)|
            unless proc.call(k, v)
              res << Acts::DataTable.t("scope_filters.validations.#{error}", :arg_name => localized_arg_name(k), :arg_value => v)
            end
            res
          end
        end

        #
        # Looks up the given argument name in activerecord.scope_filters.args.MODEL.
        #
        # If no translation was specified, it behaves like I18n.t in rails 4 and tries
        # to make the best of the given given argument name
        #
        def localized_arg_name(arg_name)
          l = I18n.t(arg_name, :scope => "activerecord.scope_filters.args.#{@model.to_s.underscore}.#{@scope}")
          if l =~ /translation missing/
            arg_name.to_s.split('_').map(&:camelize).join(' ')
          else
            l
          end
        end
      end
    end
  end
end