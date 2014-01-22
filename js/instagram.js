$(function() {

	var access_token = "753097420.39170cd.2d8908f704c24f34b24ca8666860e75d";

	$(document).ready(function() {
		$('.instagram-container').each(function(i, el) {
			grabImagesFooter($(el))
		})
	});

	function grabImagesFooter(target) {

		var count = parseInt(target.data('image-count'));
		var cols = parseInt(target.data('cols-count'));
		var user = target.data('user-id');
		var size = target.data('photo-size');

		var url = 'https://api.instagram.com/v1/users/' + user + '/media/recent/?callback=?';

		$.getJSON(url, { count: count, access_token: access_token }, function(instagram_data) {
			if (instagram_data.meta.code == 200) {
				// create a variable that holds all returned payload
				var photos = instagram_data.data;

				//as long as that variable holds data (does not = ) then...
				if (photos.length > 0) {
					//since there are multiple objects in the payload we have
					//to create a loop
					for (var key in photos) {
						//we create a variable for one object
						var photo = photos[key];
						//then we create and append to the DOM an  element in jQuery
						//the source of which is the thumbnail of the photo
						
						var size_key = 'thumbnail';
						if (size == 'large')  size_key = 'standard_resolution'
						if (size == 'medium') size_key = 'low_resolution'
						
						var photo_url = photo.link;
						var photo_src = photo.images[size_key].url
						var col_class = "col-md-"+(12/cols)
						// Build HTML for photo
						target
							.addClass('row')
							.append($("<div>")
								.addClass('instagram-photo')
								.addClass(col_class)
								.append($("<a>")
									.attr('href',photo_url)
									.append($("<img>")
										.attr('src',photo_src))))
					}
				} else {
					//if the photos variable doesn’t hold data
					target.append("Hmm.  I couldn’t find anything!");
				}
			} else {
				//if we didn’t get a 200 (success) request code from instagram
				//then we display instagram’s error message instagram
				var error = data.meta.error_message;
				target.append('Something happened, Instagram said: ' + error);
			}
		});
	}
});
