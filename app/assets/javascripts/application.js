// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui/datepicker
//= require jquery-ui/datepicker-es
//= require turbolinks
//= require jquery.turbolinks
//= require foundation/foundation
//= require foundation/foundation.dropdown
//= require modernizr
//= require parallax
//= require moment
//= require moment/ca
//= require moment/es
//= require immutable
//= require social-share-button
//= require initial
//= require ahoy
//= require check_all_none
//= require dropdown
//= require ie_alert
//= require location_changer
//= require moderator_comment
//= require moderator_debates
//= require moderator_proposals
//= require moderator_meetings
//= require prevent_double_submission
//= require gettext
//= require annotator
//= require tags
//= require users
//= require annotatable
//= require i18n
//= require districts
//= require advanced_search
//= require react_ujs
//= require markerclusterer
//= require registration_form
//= require verification_form
//= require home_animations
//= require page_navigation
//= require menu
//= require share
//= require tracking
//= require votes
//= require bundle

var initialize_modules = function() {
  App.Users.initialize();
  App.Tags.initialize();
  App.Dropdown.initialize();
  App.LocationChanger.initialize();
  App.CheckAllNone.initialize();
  App.PreventDoubleSubmission.initialize();
  App.IeAlert.initialize();
  App.Annotatable.initialize();
  App.Districts.initialize();
  App.AdvancedSearch.initialize();
  App.RegistrationForm.initialize();
  App.HomeAnimations.initialize();
  App.PageNavigation.initialize();
  App.VerificationForm.initialize();
  App.Menu.initialize();
  App.Share.initialize();
  App.Votes.initialize();
  App.ModeratorMeetings.initialize();
};

$(function(){
  var locale = $("html").attr("lang");
  moment.locale(locale);

  Turbolinks.enableProgressBar();

  initialize_modules();

  $(document).on('ajax:complete', initialize_modules);
  $(document).on('ready page:load page:restore', function(){
    $('[data-parallax="scroll"]').parallax();
    $(window).trigger('resize').trigger('resize.px.parallax');
  });
});

GoogleMapsAPI = $.Deferred();

function gmapsLoaded () {
  GoogleMapsAPI.resolve(google);
}