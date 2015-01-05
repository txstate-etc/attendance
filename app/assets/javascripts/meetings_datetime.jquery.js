jQuery(document).ready(function ($) {
  var DATE_FORMAT = "yy-mm-dd";

  $('#meeting_startdate').datepicker({dateFormat: DATE_FORMAT});

  // Set input to be readonly so keyboard doesn't pop up on mobile.
  $('#meeting_startdate').attr('readonly', 'true');
  
  $('#meeting_starttime').timepicker();
});
