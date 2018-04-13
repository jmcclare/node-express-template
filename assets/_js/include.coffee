# JQuery
#
# The Foundation 3.2.5 JS seems to work with JQuery 1.10.2, but it recommends
# 1.9.0
#= require libs/jquery/jquery-1.10.2.min.js
#
# If the Foundation JS has issues with JQuery 1.10.2, switch to this one.
# require libs/jquery/jquery-1.9.1.js
#
# Fetched from:
# http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js
# The Foundation 3.2.2 JS required jquery 1.8.3
# require libs/jquery/jquery-1.8.3.js


# JQuery UI
#
# We currently use this for the date picker.
#= require libs/jquery/jquery-ui.js

# JQuery UI Slider Accessibility Addon.
# Needed by JQuery UI timepicker.
#= require libs/jquery/jquery-ui-sliderAccess.js

# JQuery UI timepicker addon.
# Gives you a popup to choose date and time together.
#= require libs/jquery/jquery-ui-timepicker-addon.js


# AngularJS

# Fetched from:
# http://ajax.googleapis.com/ajax/libs/angularjs/1.0.8/angular.js
#= require libs/angular/angular.js

# Angular sanitize. Needed for inserting raw HTML into your Angular templates.
# Fetched from:
# http://ajax.googleapis.com/ajax/libs/angularjs/1.0.8/angular-sanitize.js
#= require libs/angular/angular-sanitize.js

# Fetched from:
# http://ajax.googleapis.com/ajax/libs/angularjs/1.0.8/angular-resource.js
#= require libs/angular/angular-resource.js


# The code for editing articles. Remove this if you are not using the articles
# app.
#= require articles/include.coffee


#
# Foundation framework JavaScript —currently 
#
# We don't use the full Foundation JavaScript because it includes its own
# version of JQuery and Modernizr, and we don't need everything in it. Instead,
# we use only the parts that we need and include our own (compatible) JQuery
# and Modernizr.
#
# This is how to import all Foundation components at once:
# require libs/foundation/foundation.min.js

# require libs/foundation/jquery.placeholder.js
# require libs/foundation/jquery.foundation.accordion.js
# require libs/foundation/jquery.foundation.alerts.js
# require libs/foundation/jquery.foundation.buttons.js
# require libs/foundation/jquery.foundation.clearing.js
#= require libs/foundation/jquery.foundation.forms.js
# require libs/foundation/jquery.foundation.joyride.js
# require libs/foundation/jquery.foundation.magellan.js
#= require libs/foundation/jquery.foundation.mediaQueryToggle.js
#= require libs/foundation/jquery.foundation.navigation.js
#= require libs/foundation/jquery.foundation.orbit.js
# require libs/foundation/jquery.foundation.reveal.js
#= require libs/foundation/jquery.foundation.tabs.js
# require libs/foundation/jquery.foundation.tooltips.js
#= require libs/foundation/jquery.foundation.topbar.js
#= require libs/foundation/app.js
#= require plugins.js


#
# Dependencies at the top. These will be prepended to the code below by
# connect-assets, which uses Snockets.  These require statements must be the
# first lines of the file. Required files are specified relative to this file.
# If you want to lighten things up, you can remove libs/foundation/app.js and
# require only the foundation scripts you currently need.
#


# Our own site-specific JavaScript
#= require application
