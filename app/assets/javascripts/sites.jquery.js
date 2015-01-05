jQuery(document).ready(function ($) {
  $('#site_attendance td.attendancetype select').each(function (i, select) {
    $(select).data('current', $(select).val());
  });

  $('#site_attendance td.attendancetype select').change(function (e) {
    var $changed = $(e.target);
    var $td = $changed.closest('td');
    var $tr = $changed.closest('tr');

    var column = $td.parent().children().index($td) + 1;
    var row = $tr.parent().children().index($tr) + 1;
    var $col_th = $('#table-head > table > thead > tr > th:nth-child(' + column + ')');
    var $row_td = $('#table-names > table > tbody > tr:nth-child(' + row + ') > td');

    var post_url = $changed.closest('form').attr('action');
    var name = $changed.attr('name');

    var studentName = $row_td.html();
    var attendanceName = $changed.find(':selected').html().toLowerCase();
    var $tablediv = $('#table-main');
    
    var params = {};
    params[name] = $changed.val();
    params['authenticity_token'] = $('#site_attendance > div > input[name="authenticity_token"]').val();
    params['json'] = 1;

    $.ajax({
      type: "POST",
      url: post_url,
      dataType: "json",
      data: params,
      timeout: 10000,
      beforeSend: function(jqXHR, setting) {
        $changed.prop('disabled', true);
        loopBackgroundColor($td, '#aaaaaa', "#dddddd");
      },
      success: function (data, textStatus, jqXHR) {
        if (data.length > 0) {
          $changed.val($changed.data('current'));
          show_alert('Failed to mark ' + studentName + ' as ' + attendanceName + '.', 0, true, $tablediv);
        } else {
          $changed.data('current', $changed.val());
          show_alert('Successfully saved ' + studentName + ' as ' + attendanceName + '.', 3, false, $tablediv);
        }
      },
      error: function(jqXHR, textStatus, errorThrown) {
        $changed.val($changed.data('current'));
        show_alert('Failed to mark ' + studentName + ' as ' + attendanceName + '.', 0, true, $tablediv);
      },
      complete: function (data, textState, jqXHR) {
        $td.stop(true);
        $td.css('background-color', 'transparent')
        $changed.css('background-color', attendancetype_colors[$changed.val()]);
        $changed.prop('disabled', false);
      }
    });
  });

  $('#site_attendance input[type="submit"]').hide();

  $('#site_attendance td.attendancetype select').each(function (i, select) {
    $(select).css('background-color', attendancetype_colors[$(select).find(':selected').val()]);
  });

  $('#site_attendance .cancelled').hide();
  
  // "Remove User" link on section#show
  $('#site_attendance .remove-user-link').click(function(e) {
  	e.preventDefault();
  	if (confirm("All attendance data will be purged for this user in this section.\n\n"+
				"However, they will re-appear with default attendance records if the LMS thinks "+
				"they are still enrolled.")) {
  		$.post($(this).attr('href'), '', function() {
  			window.location.reload();
  		});
  	}
  });

  $('#toggle_cancelled').click(function (e) {
  	e.preventDefault();
    if ($(this).html() == 'Show Cancelled') {
      $(this).html('Hide Cancelled');
      $('.cancelled').show();
    } else {
      $(this).html('Show Cancelled');
      $('.cancelled').hide();
    }
  });

  $('tr.separator').click(function (e) {
    classToToggle = 'tr.inactive';
    spanId = '#expand-inactives';
    if ($(this).hasClass('moved-separator')) {
      classToToggle = 'tr.moved';
      spanId = '#expand-moved';
    }

    heightOfInactives = 0;
    $(classToToggle).each(function(i, element) {
      heightOfInactives += $(element).height()
    });
    if ($(spanId).html() == '+') {
      $(classToToggle).show();
      $(spanId).html('-');
      if ($('#table-main').length > 0) {
        $('#table-main').scrollTop($('#table-main').scrollTop() + heightOfInactives);
      } else {
        $(window).scrollTop($(window).scrollTop() + heightOfInactives);
      }
    } else {
      $(classToToggle).hide();
      $(spanId).html('+');
    }
  });

  $('#table-main').scroll(function (e) {
    $('#table-head').scrollLeft($(this).scrollLeft());
    $('#table-names').scrollTop($(this).scrollTop());
  });

  function getScrollBarWidth() {
    document.body.style.overflow = 'hidden'; 
    var width = document.body.clientWidth;
    document.body.style.overflow = 'scroll'; 
    width -= document.body.clientWidth; 
    if(!width) width = document.body.offsetWidth - document.body.clientWidth;
    document.body.style.overflow = ''; 
    return width; 
  }

  var SCROLLBAR_WIDTH = getScrollBarWidth();

  function resize_tables() {
    var $mainTable = $('#table-main');
    var $headTable = $('#table-head');
    var $namesTable = $('#table-names');

    var hasHorizontalScrollbar = $(window).width() < $mainTable.get(0).scrollWidth + $mainTable.offset().left + SCROLLBAR_WIDTH;
    var hasVerticalScrollbar = $(window).height() < $mainTable.get(0).scrollHeight + $mainTable.offset().top + 10 + SCROLLBAR_WIDTH;

    // Add a scrollbar under the names column if there's one on the main table,
    // so they line up correctly 
    if (hasHorizontalScrollbar) {
      $namesTable.css('overflow-x', 'scroll');
    }
    else {
      $namesTable.css('overflow-x', 'hidden');
    }

    var headMaxWidth = $(window).width() - $headTable.offset().left;

    if (hasVerticalScrollbar) {
      headMaxWidth -= SCROLLBAR_WIDTH;
    }

    $headTable.css('max-width', headMaxWidth);
    $mainTable.css('max-width', $(window).width() - $mainTable.offset().left - SCROLLBAR_WIDTH);

    $mainTable.css('max-height', $(window).height() - $mainTable.offset().top - 10);
    $namesTable.css('max-height', $(window).height() - $namesTable.offset().top - 10);
  }

  if ($('#table-main').length > 0) {
  	$(window).resize(resize_tables);
    $('#table-main').css('padding-right', SCROLLBAR_WIDTH);
		resize_tables();
	}
	
	// fix the page title on sections#show to not overlap buttons
	function adjust_title() {
		var default_margin = 15;
		var title = $('h2.collapsed-page-header');
		var actions = $('#site-actions');
		var usable = actions.width();
		var leftbuttonwidths = 0;
		$('#site-actions .linkbutton').each(function(i, b) {
			var bwidth = $(b).outerWidth(true);
			if (!$(b).is('.lessimportant')) leftbuttonwidths += bwidth;
			usable -= bwidth;
		});
		var twidth = title.width();
		if (twidth >= usable) {
			title.css('margin-top', (actions.height()+default_margin)+'px');
			actions.css('margin-bottom', (title.height()+default_margin)+'px');
		} else {
			title.css('margin-top', default_margin+'px');
			actions.css('margin-bottom', '0px');
		}
		title.css('left', ((usable - twidth)/2+leftbuttonwidths)+'px');
	}
	adjust_title();
	$(window).resize(adjust_title);

  $('input[name="gradesettings_score_type"]:radio').change(function(){
    if ($('#gradesettings_score_deduct').is(':checked')) {
      $('#gradesettings_deduction').prop('disabled', false);
    } else {
      $('#gradesettings_deduction').val(0);
      $('#gradesettings_deduction').prop('disabled', true);
    }
  });

  $('input[name="gradesettings_late"]:radio').change(function(){
    if ($('#gradesettings_late_partial').is(':checked')) {
      $('#gradesettings_tardy_value').prop('disabled', false);
      $('#gradesettings_tardy_per_absence').val(0);
      $('#gradesettings_tardy_per_absence').prop('disabled', true);
    } else {
      $('#gradesettings_tardy_per_absence').prop('disabled', false);
      $('#gradesettings_tardy_value').val(100);
      $('#gradesettings_tardy_value').prop('disabled', true);
    }
  });
});
