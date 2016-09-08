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

function get_recent_checkins(sectionId, cb) {
  $.ajax('/sections/' + sectionId + '/userattendances?checkins_since=' + updated_at)
    .done(function(data) {
      data.forEach(function(ua) {
        var ua_updated = moment(ua.updated_at).valueOf();
        if (ua_updated > updated_at) updated_at = ua_updated;
      });
      cb(data);
    })
    .always(function() {
      setTimeout(function() {get_recent_checkins(sectionId, cb)}, 10000);
    });
}

function open_code_window(code) {
  var w = window.open('', '_blank', 'width=' + screen.width + ',height=' + screen.height + ',toolbar=no,menubar=no,location=no,status=no,');

  var size = (screen.width * 1.6 ) / 6;
  var css = {
    height: '100%',
    width: '100%',
    display: 'flex',
    'align-items': 'center',
    'justify-content': 'center',
    'font-family': 'monospace',
    'font-size': size + 'px'
  };

  var $div = $('<div>');
  $div.css(css);
  $div.text(code);
  $(w.document.body).css('background-color', '#363534');
  $(w.document.body).css('color', 'white');
  w.document.body.innerHTML = $div[0].outerHTML;
}
