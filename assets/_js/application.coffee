###
  Add your application's coffee-script code here
###


# This activates the sample content slider in our sample index.jade. Remove
# this, or use it to activate your own.
$(window).load () ->
  $("#orbiter").orbit
    pauseOnHover: false
    directionalNav: false
    bullets: true
    # Set fluid to the aspect ratio of your embedded content. Here we're
    # putting the actual dimensions of some YouTube videos we were testing
    # with. If you are only using images, you can leave this setting at the
    # default: true
    #fluid: '560x315'
    fluid: '420x315'
    # This makes the orbiter pause when any of the controls are clicked.
    resetTimerOnClick: false
