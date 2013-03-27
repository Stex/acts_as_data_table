module ActsAsSearchableHelper
  def scope_filter_link(group, options = {})
    filter_name  = options.delete(:filter)
    caption      = options.delete(:caption) || t("activerecord.scopes.sales.#{filter_name}")
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