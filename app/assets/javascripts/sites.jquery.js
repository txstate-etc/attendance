jQuery(document).ready(function ($) {
  var icons = {
    Present: 'fa-check-square-o',
    Absent: 'fa-times-circle',
    Late: 'fa-exclamation-triangle',
    Excused: 'fa-check-circle-o'
  };
  var sectionId = location.pathname.slice(location.pathname.lastIndexOf('/') + 1);
  var $tablediv = $('#table-main');
  var $dialog = $('#csv-dialog').dialog({
    autoOpen: false,
    modal: true,
    width: 400,
    height: 125,
    resizable: false,
    draggable: false,
    position: { my: 'left top', at: 'left bottom', of: $('#download-csv')}
  });
  $('#download-csv').click(function() {
    $dialog.dialog('open');
  });

  $('#csv-dialog a').click(function() {
    this.search = '?sessions='+ $('#include-sessions').is(':checked')
      + '&checkins=' + $('#include-checkins').is(':checked')
      + '&totals=' + $('#include-totals').is(':checked');
    $dialog.dialog('close');
  });

  $('#site_attendance td.attendancetype select').each(function (i, select) {
    $(select).data('current', $(select).val());
  });

  function refreshSelectMenu($select) {
    var $widget = $select.siblings('span');
    var $text = $widget.find('.ui-selectmenu-text');
    $text.prepend('<i class="fa ' + icons[$text.text()] + '"></i>');
    $widget.css('color', attendancetype_colors[$select.val()]);
  }

  $('#site_attendance td.attendancetype select').on('selectmenuchange', function (e) {
    var $changed = $(e.target);
    var $widget = $(e.target).siblings('span');
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
      beforeSend: function (jqXHR, setting) {
        $changed.prop('disabled', true);
        $changed.selectmenu('refresh');
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
      error: function (jqXHR, textStatus, errorThrown) {
        $changed.val($changed.data('current'));
        show_alert('Failed to mark ' + studentName + ' as ' + attendanceName + '.', 0, true, $tablediv);
      },
      complete: function (data, textState, jqXHR) {
        $td.stop(true);
        $td.css('background-color', 'transparent')
        $changed.prop('disabled', false);
        $changed.selectmenu('refresh');
        $changed.closest('div').find('i.fa-bell').removeClass('fa-bell').addClass('fa-bell-slash-o');
        refreshSelectMenu($changed);
      }
    });
  });

  $('#site_attendance input[type="submit"]').hide();

  $('.attendancetype select').each(function() {
    var $select = $(this);
    $select.selectmenu({
      width: '62%'
    });
    var $text = $select.siblings('span').find('.ui-selectmenu-text');
    $text.prepend('<i class="fa ' + icons[$text.text()] + '"></i>');
  });

  $('#site_attendance td.attendancetype select').each(function (i, select) {
    $(select).siblings('span').css('color', attendancetype_colors[$(select).find(':selected').val()]);
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
    if ($(this).text() == 'Show Cancelled') {
      $(this).html('<i class="fa fa-eye-slash"></i>Hide Cancelled');
      $('.cancelled').show();
    } else {
      $(this).html('<i class="fa fa-eye"></i>Show Cancelled');
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
    get_recent_checkins(sectionId, function(data) {
      data.forEach(function(ua) {
        var $select = $('select[name="meeting-'+ua.meeting_id+'_member-'+ua.membership_id+'"]');
        $select.val(ua.attendancetype_id);
        $select.css('background-color', attendancetype_colors[ua.attendancetype_id]);
        if (ua.checkins.length) {
          var checkin = ua.checkins[0];
          var time = moment(checkin.time);
          $select.siblings('span').after('<i class="fa fa-bell checkin" title="Checked in with ' + checkin.source + ' at ' + time.format('h:mma') + '"/>');
          $select.selectmenu('refresh');
          refreshSelectMenu($select)
        }
      });
      if (data.length) {
        var pluralize = data.length > 1 ? 'checkins' : 'checkin';
        show_alert(data.length + ' new ' + pluralize, 3, false, $tablediv)
      }
    });
	}

  $('input[name="gradesettings_score_type"]:radio').change(function(){
    if ($('#gradesettings_score_deduct').is(':checked')) {
      $('#site_gradesettings_attributes_deduction').prop('disabled', false);
    } else {
      $('#site_gradesettings_attributes_deduction').val(0);
      $('#site_gradesettings_attributes_deduction').prop('disabled', true);
    }
  });

  $('input[name="gradesettings_late"]:radio').change(function(){
    if ($('#gradesettings_late_partial').is(':checked')) {
      $('#site_gradesettings_attributes_tardy_value').prop('disabled', false);
      $('#site_gradesettings_attributes_tardy_per_absence').val(0);
      $('#site_gradesettings_attributes_tardy_per_absence').prop('disabled', true);
    } else {
      $('#site_gradesettings_attributes_tardy_per_absence').prop('disabled', false);
      $('#site_gradesettings_attributes_tardy_value').val(100);
      $('#site_gradesettings_attributes_tardy_value').prop('disabled', true);
    }
  });

  $('input[name="site[gradesettings_attributes][auto_max_points]"]').change(function() {
    if ($('#site_gradesettings_attributes_auto_max_points_true').is(':checked')) {
      $('#site_gradesettings_attributes_max_points').prop('disabled', true);
    } else {
      $('#site_gradesettings_attributes_max_points').prop('disabled', false);
    }
  });

  $('button.code-action').click(function() {
    var $button = $(this);
    if ($button.data('code')) {
      open_code_window($button.data('code'));
    } else {
      var meeting_id = $button.closest('th').data('meeting-id');
      var url = '/meetings/' + meeting_id + '/code';
      $.ajax({
        url: url,
        method: 'POST'
      }).done(function(data) {
        $button.find('span').text('SHOW CHECKIN CODE');
        $button.data('code', data.checkin_code);
      }).fail(function() {
        alert('failed to add code');
      });
    }
  });
});
