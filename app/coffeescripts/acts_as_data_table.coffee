#
# Handles clicks on table column headers and adds the functionality
# for CTRL+Click. The different actions are triggered as follows:
#
# Normal click: The column will be the only sorting column
# CTRL + click on inactive column: Column will be added to sorting list
# CTRL + click on active column: Column will be removed from sorting list
#
jQuery(document).ready () ->
  jQuery(document).on "click", '[data-init=sortable-column]', (e) ->
    urlToggle          = jQuery(@).data('urlToggle')
    urlSetBase         = jQuery(@).data('urlSetBase')

    remote             = jQuery(@).data('remote') == 'true'
    active             = jQuery(@).data('active') == 'true'

    jQuery(@).addClassName('active') if active

    url = urlSetBase

    if e.ctrlKey || e.metaKey
      url = urlToggle

    if remote
      jQuery.ajax
        'url': url,
        dataType: 'script'
    else
      window.location.href = url

    return false

  jQuery(document).on "click", "[data-init=sortable-column-direction]", (e) ->
    url    = jQuery(@).data('urlChangeDirection')
    remote = jQuery(@).data('remote') == 'true'

    if remote
      jQuery.ajax
        'url': url,
        dataType: 'script'
    else
      window.location.href = url

                                                   