module ActsAsSearchable
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
    # Parameters:
    #   If the last argument is a Hash, it will be used as options.
    #   Possible Options:
    #     :scope_name -- This name will be used for the named_scope
    #     :downcase   -- If set to true, the database values and search
    #                    queries will be set to use only lowercase (case insensitive search)
    #
    #
    # Examples:
    #
    #  1. A User Model with has_many :roles
    #    User.acts_as_searchable :first_name, :last_name, {:roles => :name}
    #
    #    Searches for users with either first or last name or a role matching the search term.
    #    This will not work for a search like "Will Smith" as first and last name are not concatenated
    #
    #  2. Example 1 with full name functionality
    #    User.acts_as_searchable [:first_name, :last_name], {:roles => :name}
    #
    #    This will automatically concatenate the first_name and last_name columns during the search
    #    so full names like "Will Smith" will be found as well as only "Will" or "Smith"
    #--------------------------------------------------------------
    def acts_as_searchable(*args)
      options = {:scope_name => :column_search, :downcase => true}
      options.merge!(args.pop) if args.size > 1 && args.last.is_a?(Hash)

      includes = []
      fields = args.map {|arg| process_column_arg(arg, includes)}.flatten

      fields = fields.map {|f| "CAST(#{f} AS TEXT)"}
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

    private

    # Processes a single argument for acts_as_searchable.
    # Handles
    #   - simple values (e.g. :first_name),
    #   - arrays which will be concatenated with a space character (e.g. [:first_name, :last_name])
    #   - hashes which represent associations on the main model (e.g. :student => [:mat_num])
    #--------------------------------------------------------------
    def process_column_arg(arg, includes)
      if arg.is_a?(Hash)
        res = []
        arg.each do |association, columns|
          includes << association
          Array(columns).each do |column|
            res << [association.to_s.pluralize, column.to_s].join('.')
          end
        end
        res
      elsif arg.is_a?(Array)
        columns = arg.map {|a| process_column_arg(a, includes)}
        "CONCAT(#{columns.join(", ' ', ")})"
      else
        if self.column_names.include?(arg.to_s)
          [self.table_name, arg.to_s].join('.')
        else
          throw ArgumentError.new("The table #{self.table_name} does not contain a column named #{arg}")
        end
      end
    end
  end
end