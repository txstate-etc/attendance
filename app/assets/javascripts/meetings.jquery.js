jQuery(document).ready( function ($) {
  $.post_that_times_out = function( url, data, success, dataType, timeout ) {      
    return $.ajax({
      type : "POST", //predefine request type to POST
      'url'  : url,
      'data' : data,
      'success' : success,
      'dataType': dataType,
      'timeout' : timeout
    })
  };
  	
	function settle_row(tr) {
		$(tr).find('td').stop(true).css('background-color', 'transparent');
		var ipt = $(tr).find('input:checked')
		ipt.closest('td').css('background-color', attendancetype_colors[ipt.val()]);
	}
	
	$('#meeting_attendance td.attendancetype input[type="radio"]').click( function (e) {
		e.preventDefault();
		e.stopPropagation();
		var clicked = $(e.target);
		var table = clicked.closest('table');
		var row = clicked.closest('tr');
		var tr = row.get(0); 
		var td = clicked.closest('td');
		
		loopBackgroundColor(clicked.closest('td'), '#CCCCCC', '#EEEEEE');
		clearTimeout(tr.ajax_timer);
		
		td.css('background-color', 'transparent');

		var post_url = clicked.closest('form').attr('action');
		var auth_token = $('#meeting_attendance > div > input[name="authenticity_token"]').val();
		var name = clicked.attr('name');
		var value = clicked.val();
		var params = {};
		params['authenticity_token'] = auth_token;
		params[name] = value;
		params['json'] = 1;
		
		tr.ajax_timer = setTimeout( function () {
			$.post_that_times_out(post_url, params, function (data, textStatus, jqXHR) {
				if (data.length > 0) {
					settle_row(tr);
					show_alert('Failed to '+clicked.attr('title'), 0, true, table);
				} else {
					clicked.prop('checked', true);
					settle_row(tr);
					show_alert('Successfully saved '+row.find('.name a').html()+' as '+clicked.attr('data-atype-name').toLowerCase()+'.', 3, false, table);
				}
			}, 'json', 10000)
			.fail(function () {
				settle_row(tr);
				show_alert('Failed to '+clicked.attr('title'), 0, true, table);
			});
		}, 400);
	});
	
	$('#meeting_attendance td.attendancetype').click( function (e) {
		e.stopPropagation();
		$(e.target).find('input').click();
	}).add('input[type="radio"]').css('cursor', 'pointer');

	//$('#meeting_attendance input[type="submit"]').hide();
	
	// show background colors on page load
	$('#meeting_attendance td.attendancetype input[type="radio"]:checked').each( function (idx, ipt) {
		$(ipt).closest('td').css('background-color', attendancetype_colors[ipt.value]);
	});

  $('#new-code').click(function() {
    var url = $('#new-code').data('action');
    $.post_that_times_out(url, {}, function(data) {
      $('#checkin-code').text(data.checkin_code);
      $('#remove-code').show();
    }).fail(function() {
      alert('failed');
    }, 10000);
  });

  $('#remove-code').click(function() {
    var url = $('#remove-code').data('action');
    $.post_that_times_out(url, {}, function(data) {
      $('#checkin-code').text('');
      $('#remove-code').hide();
    }).fail(function() {
      alert('failed');
    }, 10000);
  });

  if ($('#checkin-code').text().length < 1) {
    $('#remove-code').hide();
  }

  $('#generate_code').change(function() {
    if (this.checked) {
      $('.type-radio').hide();
      $('#initialtype-label').text('Mark all active students as: Absent');
    } else {
      $('.type-radio').show();
      $('#initialtype-label').text('Mark all active students as:');
    }
  })
});
