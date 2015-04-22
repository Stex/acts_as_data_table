jQuery(document).ready(function() {
  jQuery(document).on("click", '[data-init=sortable-column]', function(e) {
    var active, remote, url, urlSetBase, urlToggle;
    urlToggle = jQuery(this).data('urlToggle');
    urlSetBase = jQuery(this).data('urlSetBase');
    remote = jQuery(this).data('remote') === 'true';
    active = jQuery(this).data('active') === 'true';
    if (active) {
      jQuery(this).addClassName('active');
    }
    url = urlSetBase;
    if (e.ctrlKey || e.metaKey) {
      url = urlToggle;
    }
    if (remote) {
      jQuery.ajax({
        'url': url,
        dataType: 'script'
      });
    } else {
      window.location.href = url;
    }
    return false;
  });
  return jQuery(document).on("click", "[data-init=sortable-column-direction]", function(e) {
    var remote, url;
    url = jQuery(this).data('urlChangeDirection');
    remote = jQuery(this).data('remote') === 'true';
    if (remote) {
      return jQuery.ajax({
        'url': url,
        dataType: 'script'
      });
    } else {
      return window.location.href = url;
    }
  });
});
