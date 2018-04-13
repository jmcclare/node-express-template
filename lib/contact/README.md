# contact #

Provides a site contact form that sends email to addresses specified on the
backend.


## Installation ##

Copy or symlink the contents of `views` into your app's main `views` directory.

Wherever you add your app' routes, add this package's routes like so:

    contact = require('./lib/contact');
    contact.addRoutes(app, '/contact');

The second parameter is the path to add the contact form's routes under. If you
leave this blank, the routes will be added at the root.

In your app's config, before you add the routes, call
`contact.addDefaults(app)`, or set your own values for the required variables.
