jQuery(document).ready( function ($) {
  if ($('#rosterupdate').length > 0) {
    var target = $('#rosterupdate')[0];
    var spinner = new Spinner().spin(target);

    do_rosterupdate_post(1);
  }

  function do_rosterupdate_post(tries) {
    if (tries > 25) {
      $('#rosterupdate').html('Roster update took too long. Please reload the page to try again.');
      spinner.stop();
      return;
    }

    $.ajax({
      type: "POST",
      url: "/rosterupdate",
      timeout: 120000,
      data: { siteid: siteid }
    }).done(function(url) {
      if (url) {
        window.location.replace(url);
      } else {
        do_rosterupdate_post(tries+1);
      }
    }).fail(function(x, status, y) {
      if (status == 'timeout') {
        $('#rosterupdate').html('Roster update took too long. Please reload the page to try again.');
      } else {
        $('#rosterupdate').html('There was a problem updating the roster. Please reload the page to try again.');
      }
      spinner.stop();
    });
  }
});
