module ActsAsDataTableHelper


  #
  # Generates a link to add/remove a certain scope filter
  #
  # @param [Hash] options
  #   Options to customize the generated link
  #
  # @option options [String, Symbol] :scope
  #   The scope within the given +group+ to be added/removed
  #
  # @option options [TrueClass, FalseClass] :toggle (false)
  #   If set to +true+, the link will automatically remove the filter
  #   if it's currently active without having to explicitly set +:remove+
  #
  # @option options [TrueClass, FalseClass] :remove (false)
  #   If set to +true+, the link will always attempt to remove
  #   the given +:scope+ within the given +group+ and cannot be used
  #   to add it.
  #
  #
  #
  def scope_filter_link(group, scope, options = {})
    caption         = options.delete(:caption) || scope_filter_caption(group, scope, options[:args])
    surrounding_tag = options.delete(:surrounding)
    remote          = options.delete(:remote)
    args            = options[:args]
    url             = scope_filter_link_url(group, scope, options)

    classes = options[:class].try(:split, ' ') || []
    classes << 'active' if acts_as_data_table_session.active_filter?(group, scope, args)

    options[:class] = classes.join(' ')

    if remote
      link = link_to_remote caption, :url => url, :method => :get, :html => options
    else
      link = link_to caption, url, options
    end

    surrounding_tag ? content_tag(surrounding_tag, link, :class => options[:class]) : link
  end

  #
  # Generates a URL to add/remove/toggle a given scope filter
  #
  # @see #scope_filter_link for arguments
  #
  # @return [String] The generated URL
  #
  def scope_filter_link_url(group, scope, options)
    args            = options.delete(:args)
    toggle          = options.delete(:toggle)
    auto_remove     = toggle && acts_as_data_table_session.active_filter?(group, scope, args)
    remove          = options.delete(:remove) || auto_remove

    if remove
      url_for({:scope_filters => {:action => 'remove', :group => group}})
    else
      url_for({:scope_filters => {:action => 'add', :group => group, :scope => scope, :args => args}})
    end
  end

  #
  # Looks up a set argument for a given filter, e.g. to highlight it
  # in the search results
  #
  # @return [Object, NilClass] the argument used for the given scope
  #   or +nil+ if the filter is currently not active
  #
  def scope_filter_arg(group, scope, name)
    Acts::DataTable.lookup_nested_hash(acts_as_data_table_session.active_filters, group.to_s, scope.to_s, name.to_s)
  end

  #
  # Generates a scope filter caption
  #
  def scope_filter_caption(group, scope, args = {})
    model = Acts::DataTable::ScopeFilters::ActionController.get_request_model
    Acts::DataTable::ScopeFilters::ActiveRecord.scope_filter_caption(model, group, scope, args)
  end

end