module ActsAsDataTableHelper
  require 'ostruct'

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
  # @option options [Array, Hash, ActiveRecord::Base] :url (nil)
  #   If given, the link will not point to the current action, but to the
  #   given URL with the additional scope filter arguments.
  #   Using this is usually not encouraged as scope filters are bound
  #   to certain actions and arguments will only be fetche for the current one.
  #
  #
  def scope_filter_link(group, scope, options = {})
    caption         = options.delete(:caption) || scope_filter_caption(group, scope, options[:args])
    surrounding_tag = options.delete(:surrounding)
    args            = options[:args]
    url             = scope_filter_link_url(group, scope, options)

    classes = options[:class].try(:split, ' ') || []
    classes << 'active' if scope && acts_as_data_table_session.active_filter?(group, scope, args)

    options[:class] = classes.join(' ')

    link = link_to caption, url, options

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
    auto_remove     = scope && toggle && acts_as_data_table_session.active_filter?(group, scope, args)
    remove          = options.delete(:remove) || auto_remove
    predefined_url  = options.delete(:url)

    url_params      = remove ? {:action => 'remove', :group => group} :
                               {:action => 'add', :group => group, :scope => scope, :args => args}

    if predefined_url
      polymorphic_path(predefined_url, {:scope_filters => url_params})
    else
      url_for(:scope_filters => url_params)
    end
  end

  #
  # Generates a URL to be used as form action for filters which require
  # dynamic arguments
  #
  # @return [String] the generated URL
  #
  # @example Using the rails form helper with a scope filter url
  #
  #     - form_tag(scope_filter_form_url) do
  #       ...
  #
  def scope_filter_form_url(group, scope)
    url_for({:scope_filters => {:action => 'add', :group => group, :scope => scope}})
  end


  def scope_filter_form(group, scope, options = {}, &proc)
    content = capture(Acts::DataTable::ScopeFilters::FormHelper.new(self, group, scope), &proc)
    options[:method] ||= :get
    form_tag scope_filter_form_url(group, scope), options do
      concat(content)
    end
  end

  #
  # @return [String] URL to remove all active scope filters for the current action
  #
  def scope_filter_reset_url
    url_for({:scope_filters => {:action => :reset}})
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
  # @return [Hash] Arguments used for the given filter
  #
  def scope_filter_args(group, scope)
    Acts::DataTable.lookup_nested_hash(acts_as_data_table_session.active_filters, group.to_s, scope.to_s) || {}
  end

  #
  # Generates a scope filter caption
  #
  def scope_filter_caption(group, scope, args = {})
    model = Acts::DataTable::ScopeFilters::ActionController.get_request_model
    Acts::DataTable::ScopeFilters::ActiveRecord.scope_filter_caption(model, group, scope, args)
  end

  def active_scope_filter(group)
    acts_as_data_table_session.active_filter(group)
  end

  #----------------------------------------------------------------
  #                       Sortable Columns
  #----------------------------------------------------------------

  def sortable_column(model, column, caption, options = {}, &proc)
    renderer_class = options.delete(:renderer) || Acts::DataTable::SortableColumns::Renderers.default_renderer

    sortable                 = sortable_column_data(model, column)
    sortable[:html_options]  = options
    sortable[:caption]       = caption
    sortable[:remote]        = options.delete(:remote)
    sortable[:remote]        = true if sortable[:remote].nil? || sortable[:remote] == ''
    sortable                 = OpenStruct.new(sortable)

    #If a block is given, we let the user handle the content of the table
    #header himself. Otherwise, we'll generate the default links.
    if block_given?
      yield sortable
    else
      renderer = renderer_class.is_a?(Class) ? renderer_class : renderer_class.constantize
      renderer.new(sortable, self).to_html
    end
  end

  def sortable_column_data(model, column)
    sortable                = {}

    sortable[:direction]    = acts_as_data_table_session.sorting_direction(model, column)
    sortable[:active]       = acts_as_data_table_session.active_column?(model, column)

    urls                    = {}
    urls[:toggle]           = url_for({:sortable_columns => {:action => :toggle, :model => model, :column => column}})
    urls[:change_direction] = url_for({:sortable_columns => {:action => :change_direction, :model => model, :column => column}})
    urls[:set_base]         = url_for({:sortable_columns => {:action => :set_base, :model => model, :column => column}})
    sortable[:urls]         = OpenStruct.new(urls)

    sortable
  end

end