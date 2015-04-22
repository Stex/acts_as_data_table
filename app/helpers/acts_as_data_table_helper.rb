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

  #----------------------------------------------------------------
  #                       Sortable Columns
  #----------------------------------------------------------------

  def sortable_column(model, column, caption, options = {}, &proc)
    sortable                 = sortable_column_data(model, column)
    sortable[:html_options]  = options
    sortable[:caption]       = caption
    sortable[:remote]        = options.delete(:remote)
    sortable[:remote]        = true if sortable[:remote].blank?
    sortable                 = OpenStruct.new(sortable)

    #If a block is given, we let the user handle the content of the table
    #header himself. Otherwise, we'll generate the default links.
    if block_given?
      yield sortable
    else
      capture_haml do
        link_options                              = sortable.html_options
        link_options['data-init']                 = 'sortable-column'
        link_options['data-remote']               = sortable.remote
        link_options['data-url-toggle']           = sortable.urls.toggle
        link_options['data-url-set-base']         = sortable.urls.set_base
        link_options['data-url-change-direction'] = sortable.urls.change_direction
        link_options['data-active']               = 'true' if sortable.active

        dir_caption = sortable.direction == 'ASC' ? '&Delta;' : '&nabla;'

        haml_concat link_to(caption, '#', link_options)

        if sortable.active
          link_options['data-init'] = 'sortable-column-direction'
          haml_concat link_to(dir_caption, '#', link_options)
        end
      end
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