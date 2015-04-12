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
            include Acts::DataTable::ScopeFilters::ActionController::OnDemand

            #Add helper methods to this controller's views
            helper :acts_as_data_table

            model_name = (options.delete(:model) || self.name.underscore.split('/').last.sub('_controller', '')).to_s.camelize.singularize

            #Create a custom before filter
            before_filter options do |controller|
              params    = controller.request.params
              sf_params = params[:scope_filters]

              #Ensure that any scope filter related params are given
              return if sf_params.blank?

              #Ensure that the given action is valid (add a filter, remove a filter, remove all filters)
              return unless %w(add remove reset).include?(sf_params[:action])

              # case sf_params[:action]
              #
              # end

              #Ensure that the :group and :name param for the filter are actually given
              return if [:group, :name].any? { |p| params[:scope_filters][p].blank? }
            end
          end
        end

        module OnDemand
          def self.included(base)

          end
        end

        def self.set_request_filters!(model, filters)
          Acts::DataTable.ensure_nested_hash!(Thread.current, :scope_filters, model.to_s)
          Thread.current[:scope_filters][model.to_s] = filters
        end

        def self.get_request_filters(model)
          Acts::DataTable.lookup_nested_hash(Thread.current, :scope_filters, model.to_s)
        end

        def clear_request_filters!
          Thread.current[:scope_filters] = nil
        end
      end
    end
  end
end
