module Stex
  module Acts
    module DataTable
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        # Creates a named scope in the model which can be used to
        # perform a multi-column-search easily.
        #
        # TODO: allow nested includes like in my QueryGenerator Plugin
        #       e.g. {:student => [:mat_num, {:solutions => [:a, :b, :c]]}
        # TODO: Allow custom associations which do not follow the rails
        #       naming conventions
        # TODO: Check for column errors in associated tables
        # TODO: Only cast values if necessary (numbers, etc.)
        #
        # == Parameters
        #   If the last argument is a Hash, it will be used as options.
        #   Possible Options:
        #     :scope_name -- This name will be used for the named_scope
        #     :downcase   -- If set to true, the database values and search
        #                    queries will be set to use only lowercase (case insensitive search)
        #
        #
        # == Examples:
        #
        #  1. A User Model with has_many :roles
        #     User.acts_as_searchable :first_name, :last_name, {:roles => :name}
        #
        #     Searches for users with either first or last name or a role matching the search term.
        #     This will not work for a search like "Will Smith" as first and last name are not concatenated
        #
        #  2. Example 1 with full name functionality
        #     User.acts_as_searchable [:first_name, :last_name], {:roles => :name}
        #
        #     This will automatically concatenate the first_name and last_name columns during the search
        #     so full names like "Will Smith" will be found as well as only "Will" or "Smith"
        #--------------------------------------------------------------
        def acts_as_searchable(*args)
          options = {:scope_name => :column_search, :downcase => true}
          options.merge!(args.pop) if args.size > 1 && args.last.is_a?(Hash)

          includes = []
          fields = args.map {|arg| process_column_arg(arg, includes)}.flatten

          fields = fields.map {|f| Stex::Acts::DataTable.database_cast(f)}
          fields = fields.map {|f| "LOWER(#{f})"} if options[:downcase]
          conditions = fields.map {|f| "#{f} LIKE ?"}.join(' OR ')

          includes = includes.uniq.compact

          named_scope options[:scope_name], lambda {|search|
            if search.present?
              s = "%#{search}%"
              s = s.downcase if options[:downcase]
              { :include => includes, :conditions => [conditions] + Array.new(fields.size, s) }
            end
          }
        end

        def is_date_filterable(options = {})
          column       = options.delete(:column) || 'created_at'
          scope_prefix = options.delete(:prefix) || 'scoped'
          column_type  = columns.select {|c| c.name == column }.first.type
          date_column  = nil

          column = "#{table_name}.#{column}"

          case column_type
            when :datetime
              date_column = "DATE(#{column})"
            when :date
              date_column = column
            else
              logger.warn "The column #{column} has no valid type for is_date_filterable."
          end

          scopes = {:today      => lambda {{:conditions => ["#{date_column} = ?", Date.today]}},
                    :tomorrow   => lambda {{:conditions => ["#{date_column} = ?", Date.today + 1.day]}},
                    :this_week  => lambda {{:conditions => ["#{date_column} >= ? AND #{date_column} <= ?", Date.today.at_beginning_of_week, Date.today.at_end_of_week]}},
                    :this_month => lambda {{:conditions => ["#{date_column} >= ? AND #{date_column} <= ?", Date.today.at_beginning_of_month, Date.today.at_end_of_month]}},
                    :this_year  => lambda {{:conditions => ["#{date_column} >= ? AND #{date_column} <= ?", Date.today.at_beginning_of_year, Date.today.at_end_of_year]}}}

          scopes.each do |key, value|
            named_scope Stex::Acts::DataTable.build_scope_name(scope_prefix, key), value
          end
        end

        private

        # Processes a single argument for acts_as_searchable.
        # Handles
        #   - simple values (e.g. :first_name),
        #   - arrays which will be concatenated with a space character (e.g. [:first_name, :last_name])
        #   - hashes which represent associations on the main model (e.g. :student => [:mat_num])
        #--------------------------------------------------------------
        def process_column_arg(arg, includes, model = self)
          if arg.is_a?(Hash)
            res = []
            arg.each do |association, columns|
              includes << association
              Array(columns).each do |column|
                res << process_column_arg(column, includes, association.to_s.singularize.classify.constantize)
              end
            end
            res
          elsif arg.is_a?(Array)
            columns = arg.map {|a| process_column_arg(a, includes, model)}
            columns = columns.map {|c| "TRIM(#{c})"}
            "CONCAT(#{columns.join(", ' ', ")})"
          else
            if model.column_names.include?(arg.to_s)
              [model.table_name, arg.to_s].join('.')
            else
              logger.warn "The table #{model.table_name} does not contain a column named #{arg}"
            end
          end
        end
      end

      # Performs a cast to text-like for various database types
      #--------------------------------------------------------------
      def self.database_cast(content)
        case ActiveRecord::Base.connection.adapter_name
          when 'MySQL'
            "CAST(#{content} AS CHAR(10000) CHARACTER SET utf8)"
          else
            "CAST(#{content} AS TEXT)"
        end
      end

      def self.build_scope_name(*args)
        args.join('_').to_sym
      end
    end
  end
end