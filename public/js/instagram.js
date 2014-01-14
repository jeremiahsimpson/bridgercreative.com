$(function(){


var my_json_str = php_params.my_arr.replace(/&quot;/g, '"');
var my_php_arr = $.parseJSON(my_json_str);

var INSTAGRAM_FOOTER_COUNT = 17;
var INSTAGRAM_CONTACT_COUNT = 14;
var INSTAGRAM_SIDEBAR_COUNT = 10;
var INSTAGRAM_ACCESS_TOKEN = my_php_arr['accessToken'];
var INSTAGRAM_USER_ID = my_php_arr['userID'];

$(document).ready(function(){
    var access_parameters = {access_token:INSTAGRAM_ACCESS_TOKEN};
    grabImagesFooter(access_parameters, INSTAGRAM_FOOTER_COUNT, $("#instagram-target-footer"));
});

$(document).ready(function(){
    var access_parameters = {access_token:INSTAGRAM_ACCESS_TOKEN};
    grabImagesFooter(access_parameters, INSTAGRAM_CONTACT_COUNT, $(".page-template-page-contact-php").find("#instagram-target"));
});

$(document).ready(function(){
    var access_parameters = {access_token:INSTAGRAM_ACCESS_TOKEN};
    grabImagesFooter(access_parameters, INSTAGRAM_SIDEBAR_COUNT, $("#sidebar").find("#instagram-target"));
});

function grabImagesFooter(access_parameters, count, targetID) {
    var instagramUrl = 'https://api.instagram.com/v1/users/' + INSTAGRAM_USER_ID + 
    '/media/recent/?callback=?&count=' + count + '&access_token=' + INSTAGRAM_ACCESS_TOKEN;
    //?callback=?count=' + count;

    $.getJSON(instagramUrl, access_parameters, function(instagram_data){
        if(instagram_data.meta.code == 200) {
        // create a variable that holds all returned payload
        var photos = instagram_data.data;

            //as long as that variable holds data (does not = ) then...

            if(photos.length > 0) {
              //since there are multiple objects in the payload we have
              //to create a loop
              for (var key in photos ){
                //we create a variable for one object
                var photo = photos[key];
                //then we create and append to the DOM an  element in jQuery
                //the source of which is the thumbnail of the photo
                targetID.append('<div class="instagram-photo"><a href="' + photo.link + '"><img src="' + photo.images.thumbnail.url + '" /></a></div>');
              }
            }
            else {
              //if the photos variable doesn’t hold data
              targetID.append("Hmm.  I couldn’t find anything!");
            }
        }
        else  {
          //if we didn’t get a 200 (success) request code from instagram
          //then we display instagram’s error message instagram
          var error = data.meta.error_message;
          targetID.append('Something happened, Instagram said: ' + error);
        }
    });
}
function onDataLoaded(instagram_data) {
  // instagram_data.meta is where the secret messages from Instagram live
  // and instagram_data.meta.code holds the status code of the request
  // 404 means nothing was found, and 200 means everything is all good so...

  if(instagram_data.meta.code == 200) {
    // create a variable that holds all returned payload
    var photos = instagram_data.data;

        //as long as that variable holds data (does not = ) then...

        if(photos.length > 0) {
          //since there are multiple objects in the payload we have
          //to create a loop
          for (var key in photos ){
            //we create a variable for one object
            var photo = photos[key];
            //then we create and append to the DOM an  element in jQuery
            //the source of which is the thumbnail of the photo
            $('#instagram-target').append('<div class="instagram-photo"><a href="' + photo.link + '"><img src="' + photo.images.thumbnail.url + '" /></a></div>');
          }
        }
        else {
          //if the photos variable doesn’t hold data
          $('#instagram-target').append("Hmm.  I couldn’t find anything!");
        }
    }
    else  {
      //if we didn’t get a 200 (success) request code from instagram
      //then we display instagram’s error message instagram
      var error = data.meta.error_message;
      $('#instagram-target').append('Something happened, Instagram said: ' + error);
    }
  }


  });