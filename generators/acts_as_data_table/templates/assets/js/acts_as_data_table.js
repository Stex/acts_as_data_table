jQuery(document).ready(function() {
  jQuery(document).on("click", '[data-init=sortable-column]', function(e) {
    var active, remote, url, urlSetBase, urlToggle;
    e.preventDefault();
    urlToggle = jQuery(this).data('urlToggle');
    urlSetBase = jQuery(this).data('urlSetBase');
    remote = jQuery(this).data('remote');
    active = jQuery(this).data('active');
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
    e.preventDefault();
    url = jQuery(this).data('urlChangeDirection');
    remote = jQuery(this).data('remote');
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
