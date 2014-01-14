$(document).ready(function() {
	
	// Contact form Submission
	$('form#contact_form').submit(function () {

		$.ajax({
		  dataType: 'jsonp',
		  url: 'http://getsimpleform.com/messages/ajax?form_api_token=99a6f39446113987b88367b316be1079',
		  data: $(this).serializeArray()
		}).done(function() {
			$('#contact_thank_you').show();
			$('#contact_form').hide();
		});
		return false;
	});
	

	// Portfolio Lightbox
	$("a[rel^='lightbox']").magnificPopup({
		type:'image',
		showCloseBtn: false,
		gallery:{
	    enabled:true,
			arrowMarkup: '<button title="%title%" type="button" class="mfp-arrow mfp-arrow-%dir%"><span class="glyphicon glyphicon-chevron-%dir%"></span></button>', // markup of an arrow button
	  }
	});
	
})



