window.actsAsDataTable =

  init: () ->
    @.registerSortableLinks()

  # Handles clicks on table column headers and adds the functionality
  # for CTRL+Click. The different actions are triggered as follows:
  #
  # Normal click: The column will be the only sorting column
  # CTRL + click on inactive column: Column will be added to sorting list
  # CTRL + click on active column: Column will be removed from sorting list
  #--------------------------------------------------------------
  registerSortableLinks: () ->
    jQuery(document).on "click", '.sortable-column-link', (e) ->
      urlAdd    = jQuery(@).attr('data-url-add')
      urlRemove = jQuery(@).attr('data-url-remove')
      remote    = jQuery(@).attr('data-remote') == 'true'
      active    = jQuery(@).attr('data-active') == 'true'

      url = jQuery(@).attr('href') #Default replace action

      if e.ctrlKey
        if active
          url = urlRemove
        else
          url = urlAdd

      if remote
        jQuery.ajax
          'url': url,
          dataType: 'script'
      else
        window.location.href = url

      return false


jQuery(document).ready () ->
  actsAsDataTable.init()
