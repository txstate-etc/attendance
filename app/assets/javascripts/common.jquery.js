// Alternates the background color of the element between color1 and color2
function loopBackgroundColor($element, color1, color2) {
  $element.animate({backgroundColor: color1}, 300)
         .animate({backgroundColor: color2}, 300, 
                  function () { 
                    loopBackgroundColor($element, color1, color2);
                  });
}

jQuery(document).ready(function ($) {
  // Hide inactive users on sections and meetings show page
  $('tr.inactive').hide();
  $('tr.moved').hide();
});

var updated_at = Date.now() - 5000;
function get_recent_checkins(sectionId, cb) {
  var updated_since = updated_at;
  updated_at = Date.now();
  $.ajax('/sections/' + sectionId + '/userattendances?checkins_since=' + updated_since)
    .done(function(data) {
      cb(data);
    })
    .always(function() {
      setTimeout(function() {get_recent_checkins(sectionId, cb)}, 10000);
    });
}
