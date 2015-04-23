#
# Default renderer for ActsAsDataTable sortable column links.
# It uses the javascript library shipped with the gem and does not depend on
# external sources like javascripts or additional stylesheets.
#
module Acts
  module DataTable
    module SortableColumns
      module Renderers
        def self.default_renderer
          @@default_renderer ||= 'Acts::DataTable::SortableColumns::Renderers::Default'
        end

        def self.default_renderer=(renderer)
          @@default_renderer = renderer.to_s
        end

        class Default
          def initialize(sortable, action_view)
            @action_view = action_view
            @sortable    = sortable
          end

          #
          # @return [String] an indicator about the sorting direction for the current column.
          #   The direction is either 'ASC' or 'DESC'
          #
          def direction_indicator
            @sortable.direction == 'ASC' ? '&Delta;' : '&nabla;'
          end

          #
          # @return [String] The column header's caption
          #
          def caption
            @sortable.caption
          end

          #
          # @return [String] a link to change the sorting direction for an already active column
          #
          def direction_link
            link_options                              = @sortable.html_options.clone
            link_options['data-init']                 = 'sortable-column-direction'
            link_options['data-remote']               = @sortable.remote
            link_options['data-url-change-direction'] = @sortable.urls.change_direction
            @action_view.link_to(direction_indicator, '#', link_options)
          end

          #
          # @return [String] a link to toggle a column
          #
          def caption_link
            link_options                              = @sortable.html_options.clone
            link_options['data-init']                 = 'sortable-column'
            link_options['data-remote']               = @sortable.remote
            link_options['data-url-toggle']           = @sortable.urls.toggle
            link_options['data-url-set-base']         = @sortable.urls.set_base
            link_options['data-url-change-direction'] = @sortable.urls.change_direction
            link_options['data-active']               = 'true' if @sortable.active

            @action_view.link_to(@sortable.caption, '#', link_options)
          end

          #
          # Generates the actual HTML (= caption and direction links)
          # to be embedded into the view
          #
          # @return [String] the generated HTML code
          #
          def to_html
            if @sortable.active
              caption_link + ' ' + direction_link
            else
              caption_link
            end
          end
        end
      end
    end
  end
end