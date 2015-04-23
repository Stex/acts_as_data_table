module Acts
  module DataTable
    module SortableColumns
      module Renderers
        class Bootstrap2 < Default
          def direction_indicator
            if @sortable.direction == 'ASC'
              @action_view.content_tag(:i, nil, :class => 'icon-sort-by-alphabet')
            else
              @action_view.content_tag(:i, nil, :class => 'icon-sort-by-alphabet-alt')
            end
          end
        end
      end
    end
  end
end