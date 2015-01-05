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
