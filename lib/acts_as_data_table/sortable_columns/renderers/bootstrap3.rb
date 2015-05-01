module Acts
  module DataTable
    module SortableColumns
      module Renderers
        class Bootstrap3 < Default
          def direction_indicator
            if @sortable.direction == 'ASC'
              @action_view.content_tag(:i, nil, :class => 'glyphicon glyphicon-sort-by-attributes')
            else
              @action_view.content_tag(:i, nil, :class => 'glyphicon glyphicon-sort-by-attributes-alt')
            end
          end
        end
      end
    end
  end
end