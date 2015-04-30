module Acts
  module DataTable
    module MultiColumnScopes
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        #
        # Generates a scope to search for a given string in multiple
        # columns at once. Columns may either be in the own table
        # or in associated tables.
        # It also automatically generates concat queries to enable
        # full name searches, e.g. for a users table with
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
        # @example Including an association named :title (belongs_to :title)
        #   has_multi_column_scope :name_or_title, [:first_name, :last_name], {:title => :name}, {}
        #   #The empty has at the end is necessary as otherwise the title-hash would
        #   #be taken as options.
        #
        # The method does currently not support chained includes, this
        # will be added in the future (e.g. :user_rooms => {:room => :number})
        #
        def has_multi_column_scope(scope_name, *args)
          options = {:downcase => true}
          options.merge!(args.pop) if args.size > 1 && args.last.is_a?(Hash)

          include_chain = []

          fields        = args.map {|arg| Acts::DataTable::MultiColumnScopes.process_column_arg(arg, include_chain, self)}
          fields        = fields.flatten.map {|f| Acts::DataTable::MultiColumnScopes.database_cast(f)}
          fields        = fields.map {|f| "LOWER(#{f})"} if options[:downcase]

          conditions    = fields.map {|f| "#{f} LIKE ?"}.join(' OR ')
          include_chain = include_chain.uniq.compact

          named_scope scope_name, lambda {|search|
            if search.present?
              s = "%#{search}%"
              s = s.downcase if options[:downcase]
              { :include => include_chain, :conditions => [conditions] + Array.new(fields.size, s) }
            else
              {}
            end
          }
        end
      end

      #
      # Processes a single argument for has_multi_column_scope.
      # Handles
      #   - simple values (e.g. :first_name),
      #   - arrays which will be concatenated with a space character (e.g. [:first_name, :last_name])
      #   - hashes which represent associations on the main model (e.g. :student => [:mat_num])
      #
      def self.process_column_arg(arg, includes, model = self)
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
            raise ArgumentError.new "The table '#{model.table_name}' does not have a column named '#{arg}'"
          end
        end
      end

      #
      # Performs a cast to text-like for various database types
      #
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