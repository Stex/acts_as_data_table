module ActsAsSearchableHelper

  # Generates a link to to add or remove a certain filter to the
  # current controller/action.
  # Parameters:
  # group:: The group name the filter belongs to
  # options
  #   :filter:: The filter name to be applied
  #   :caption:: The link caption, defaults to a localization
  #   :remove:: If set to +true+, the filter will be removed instead of (re-)added
  #   :args:: Args to be used when applying the filter
  #   All other options will be used as html_options for the resulting link
  #--------------------------------------------------------------
  def scope_filter_link(group, options = {})
    filter_name  = options.delete(:filter)
    caption      = options.delete(:caption) || t("activerecord.scopes.#{searchable_session.model.table_name}.#{filter_name}")
    remove       = options.delete(:remove)
    args         = options.delete(:args)

    if remove
      link_to_remote caption, :url => {:scope_filters => {:remove => group}}, :method => :get, :html => options
    else
      classes = options[:class].try(:split, ' ') || []
      classes << 'act' if searchable_session.active_filter?(group, filter_name, args)
      options[:class] = classes.join(' ')
      link_to_remote caption, :url => {:scope_filters => {:group => group, :name => filter_name, :args => args}}, :method => :get, :html => options
    end
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

  # Returns all active filters in a format which is easier to
  # process than the original hash structure. Each element of the
  # returned array contains the following properties:
  #
  # :delete_url:: A url hash which contains the necessary parameters to
  #               remove the current filter from the active list
  # :group:: The filter group this filter is in (in case you want to
  #          user the +filter_link+ helper method)
  # :filter:: The filter name
  # :args:: The arguments the filter was applied to (for display reasons)
  #--------------------------------------------------------------
  def active_scope_filters
    active_filters = []
    searchable_session.active_filters.each do |group, filters|
      filters.each do |filter, args|
        active_filters << {:delete_url => {:scope_filters => {:remove => group}},
                           :group => group,
                           :filter => filter,
                           :args => args}
      end
    end
    active_filters
  end
end