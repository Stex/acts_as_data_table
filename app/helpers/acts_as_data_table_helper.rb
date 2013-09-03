module ActsAsDataTableHelper

  #----------------------------------------------------------------
  #                          Filters
  #----------------------------------------------------------------

  # Generates a link to to add or remove a certain filter to the
  # current controller/action.
  # Parameters:
  # +group+::            The group name the filter belongs to
  #
  # ===Options
  #   +:filter+::        The filter name to be applied
  #   +:caption+::       The link caption, defaults to a localization
  #   +:remove+::        If set to +true+, the filter will be removed instead of (re-)added
  #   +:args+::          Args to be used when applying the filter
  #   +:auto_remove+::   If set to true, a click on an active filter will remove it again.
  #
  #   All other options will be used as html_options for the resulting link
  #--------------------------------------------------------------
  def scope_filter_link(group, options = {})
    filter_name     = options.delete(:filter)
    caption         = options.delete(:caption) || t("activerecord.scopes.#{searchable_session.model.table_name}.#{filter_name}")
    args            = options.delete(:args)
    surrounding_tag = options.delete(:surrounding)
    auto_remove     = options.delete(:auto_remove) && searchable_session.active_filter?(group, filter_name, args)
    remove          = options.delete(:remove)

    if remove || auto_remove
      url = {:scope_filters => {:remove => group}}
    else
      url = {:scope_filters => {:group => group, :name => filter_name, :args => args}}
    end

    classes = options[:class].try(:split, ' ') || []
    classes << 'active' if searchable_session.active_filter?(group, filter_name, args)
    options[:class] = classes.join(' ')
    link = link_to_remote caption, :url => url, :method => :get, :html => options
    surrounding_tag ? content_tag(surrounding_tag, link, :class => options[:class]) : link
  end

  # Generates the URL to remove all filters from the current action
  #--------------------------------------------------------------
  def remove_all_scope_filters_url
    {:scope_filters => {:remove_all => true}}
  end

  # Generates the URL to be used as form action to add a new filter
  #--------------------------------------------------------------
  def scope_filter_form_url(group, filter_name)
    {:scope_filters => {:group => group, :name => filter_name}}
  end

  # Generates the form element name for filter args inside
  # a form
  #--------------------------------------------------------------
  def scope_filter_field_name(arg_name)
    "scope_filters[args][#{arg_name}]"
  end

  # Builds the caption for an active filter
  #--------------------------------------------------------------
  def scope_filter_caption(active_filter)
    searchable_session.model.scope_caption(active_filter[:filter], active_filter[:args])
  end

  # Returns the arguments for a currently active filter or nil
  # if the given filter is currently not active.
  #-------------------------------------------------------------
  def scope_filter_arg(filter_name, arg_name)
    @filter_args ||= {}
    @filter_args[filter_name.to_s] ||= {}

    unless @filter_args[filter_name.to_s].has_key? arg_name.to_s
      filter = active_scope_filters.select{|f| f[:filter].to_s == filter_name.to_s}.first
      if filter
        @filter_args[filter_name.to_s] = filter[:args]
      else
        #If the filter is currently not active, cache the argument anyway with nil
        @filter_args[filter_name.to_s] ||= {}
        @filter_args[filter_name.to_s][arg_name.to_s] = nil
      end
    end

    @filter_args[filter_name.to_s][arg_name.to_s]
  end

  # Returns all active filters in a format which is easier to
  # process than the original hash structure. Each element of the
  # returned array contains the following properties:
  #
  # +:delete_url+:: A url hash which contains the necessary parameters to
  #                 remove the current filter from the active list
  #
  # +:group+::      The filter group this filter is in (in case you want to
  #                 user the +filter_link+ helper method)
  #
  # +:filter+::     The filter name
  #
  # +:args+::       The arguments the filter was applied to (for display reasons)
  #--------------------------------------------------------------
  def active_scope_filters
    return @active_filters if @active_filters

    @active_filters = []
    searchable_session.active_filters.each do |group, filters|
      filters.each do |filter, args|
        @active_filters << {:delete_url => {:scope_filters => {:remove => group}},
                            :group      => group,
                            :filter     => filter,
                            :args       => HashWithIndifferentAccess.new(args)}
      end
    end
    @active_filters
  end

  # Returns the active scope filter for a given filter group
  # If you hand in a block, the filter will be available inside
  # If there is no active filter for the given group,
  # the block is not executed.
  #--------------------------------------------------------------
  def active_scope_filter(group, &proc)
    filter = active_scope_filters.select {|sf| sf[:group].to_s == group.to_s}.first
    if block_given?
      yield filter if filter
    else
      filter
    end
  end

  #----------------------------------------------------------------
  #                        Sorting Columns
  #----------------------------------------------------------------

  def sortable_column(model_name, column_name, caption = nil, &proc)
    sortable = Struct.new(:caption, :direction, :active, :url_replace, :url_add_toggle, :url_remove).new

    sortable.direction      = searchable_session.sorting_direction(model_name, column_name)
    sortable.active         = sortable.direction.present?

    sortable.url_replace    = {:sorting_columns => {:replace => true, :model_name => model_name, :column_name => column_name}}
    sortable.url_add_toggle = {:sorting_columns => {:add     => true, :model_name => model_name, :column_name => column_name}}
    sortable.url_remove     = {:sorting_columns => {:remove  => true, :model_name => model_name, :column_name => column_name}}
    sortable.caption        = caption


    #If a block is given, we let the user handle the content of the table
    #header himself. Otherwise, we'll generate the default links.
    if block_given?
      yield sortable
    else
      render :partial => 'shared/sortable_column', :object => sortable
    end
  end
end