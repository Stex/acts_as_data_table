module Acts
  module DataTable
    module MultiColumnScopes
      extend ActiveSupport::Concern

      included do
        send :extend, ClassMethods
      end

      module ClassMethods
        #
        # Generates a scope to search for a given string in multiple
        # columns at once. Columns may either be in the own table
        # or in associated tables.
        # It also automatically generates concat queries to enable
        # full name searches, e.g. for a user's table with
        # separate columns for first and last name (see examples below)
        #
        # The result can be used further to chain the query like
        # every other scope
        #
        # @param [String, Symbol] scope_name
        #   The newly generated scope's name, e.g. :full_text
        #
        # If the last argument is a Hash, it will be used as options.
        #
        # @option options [Boolean] :downcase (true)
        #   If set to +true+, the both searched query and
        #   database values will be converted to lowercase to support
        #   case insensitivity
        #
        # @example Basic usage, searching in two columns
        #   has_multi_column_scope :email_or_name, :email, :name
        #
        # @example Searching for a full name by concatenating two columns
        #   has_multi_column_scope :email_or_name, :email, [:first_name, :last_name]
        #
        # @example Including an association
        #   has_multi_column_scope :name_or_title, [:first_name, :last_name], {:title => :title}, {}
        #   #The empty has at the end is necessary as otherwise the title-hash would
        #   #be taken as options.
        #
        # The method does currently not support chained includes, this
        # will be added in the future (e.g. :user_rooms => {:room => :number})
        #
        def has_multi_column_scope(scope_name, *args)
          options = {:downcase => true}
          options.merge!(args.pop) if args.size > 1 && args.last.is_a?(Hash)

          extend AASMethods

          include_chain = []
          fields = args.map {|arg| aas_process_column_arg(arg, include_chain)}.flatten
                       .map {|f| aas_arel_command(:cast_as_text, f)}
                       .map {|f| aas_arel_command(:downcase, f)} if options[:downcase]

          scope scope_name, lambda {|string|
                            if string.present?
                              s = "%#{string.strip}%"
                              s.downcase! if options[:downcase]

                              conditions = fields.first.matches(s)
                              fields[1..-1].each {|f| conditions = conditions.or(f.matches(s))} if fields.size > 1

                              where(conditions).includes(include_chain).references(include_chain)
                            end
                          }
        end
      end

      #
      # These methods are only loaded as class methods if at least one
      # +has_multi_column_scope+ was created
      #
      module AASMethods

        #
        # Generates a database query, will hopefully become database agnostic.
        #
        # Currently available commands:
        #  - cast_as_text:: The first argument will be taken as a table column
        #    and be casted to text
        #
        #  - downcase:: Performs a LOWER to the given table column
        #
        #  - concat:: Expects as many arguments as you want.
        #             Strings will be taken as strings, Arel values as themselves.
        #
        #  - trim:: Runs a TRIM on the given table column
        #
        def aas_arel_command(command, *args)
          case command.to_sym
            when :cast_as_text
              Arel::Nodes::NamedFunction.new 'CAST', [args.first.as('TEXT')]
            when :downcase
              args.first.lower(args.first)
            when :concat
              if aas_database?(:sqlite)
                vals = args.map do |a|
                  if a.is_a?(Arel::Attributes::Attribute)
                    "`#{a.relation.name}`.`#{a.name}`"
                  elsif a.is_a?(Arel::Nodes::NamedFunction)
                    a.to_sql
                  else
                    "'#{a}'"
                  end
                end
                Arel::Nodes::NamedFunction.new '', [Arel::Nodes::SqlLiteral.new(vals.join(' || '))]
              else
                Arel::Nodes::NamedFunction.new 'CONCAT', args
              end
            when :trim
              Arel::Nodes::NamedFunction.new 'TRIM', [args.first]
            else
              raise 'Invalid argument given: ' + command
          end
        end

        def aas_database?(type)
          ActiveRecord::Base.connection.adapter_name.downcase == type.to_s.downcase
        end

        #
        # Processes a single argument.
        # Handles
        #   - simple values (e.g. :first_name),
        #   - arrays which will be concatenated with a space character (e.g. [:first_name, :last_name])
        #   - hashes which represent associations on the main model (e.g. :student => [:mat_num])
        #
        def aas_process_column_arg(arg, include_chain, model = self)
          table = model.arel_table

          if arg.is_a?(Hash)
            res = []
            arg.each do |association, columns|
              association_model = association.to_s.singularize.classify.constantize
              include_chain << association.to_sym
              columns = [columns] unless columns.is_a?(Array)
              columns.each do |column|
                res << aas_process_column_arg(column, include_chain, association_model)
              end
            end
            res
          elsif arg.is_a?(Array)
            columns = arg.map {|a| aas_process_column_arg(a, include_chain, model)}
            columns = columns.map {|c| aas_arel_command(:trim, c)}
            aas_arel_command(:concat, *(columns.map {|c| [c, ' ']}).flatten)
          else
            if model.column_names.include?(arg.to_s)
              table[arg.to_sym]
            else
              logger.warn ArgumentError.new("The table #{model.table_name} does not contain a column named #{arg}")
            end
          end
        end
      end
    end
  end
end