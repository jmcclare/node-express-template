# node-express #

A template for a [Node.js](http://nodejs.org/) [Express](http://expressjs.com/)
site.

_Note_: This project is no longer maintained. See my [Koa.js site
template](https://github.com/jmcclare/koa-template) for a newer app boilerplate
with lots of useful features already working.

We add:

* markup and JavaScript from [HTML5 Boilerplate](http://html5boilerplate.com/)
* our own Jade layout and starting styles that use [Stylus](http://learnboost.github.com/stylus/)
* our own stylus adaptation of [Foundation](http://foundation.zurb.com/), "ground-floor"
* icon font [Font Awesome](http://fontawesome.io/)
* an articles app that uses AngularJS for editing
* Compiling and minifying of CoffeeScript and JavaScript for the front end
* a `url` helper function to get URLs for resources
* Redis session store
* mongoose MongoDB data access


## Software Versions ##

`node-express` has been tested with Node.js version 0.10.1.

The Stylus framework, groundfloor, is based on the Foundation 3.2.2 SCSS.

The Foundation JavaScript is also taken from Foundation 3.2.2.

The [JQuery](https://jquery.com/) version is stipulated by what works with the
Foundation JavaScript we are using. See `app/assets/_js/include.coffee` to see
which JQuery library we are currently including.

See `assets/_js/libs/jquery/jquery-ui.js` for the current [jQuery
UI](https://jqueryui.com/) version.

See the `jquery-ui` JavaScript files in `assets/_js/libs/jquery/` for the
jQuery UI plugin versions.

See the `modernizr` JavaScript file in `public/_js/libs` for the current
[Modernizr](http://modernizr.com) version.

See the Font Awesome directory in `public/_css` for the current [Font
Awesome](http://fontawesome.io/) version.

See `package.json` for all other versions.


## Using node-express ##

Setup node and npm, create a directory for the Express app, copy or link in the
node-express files and install the node packages. See below for details.

### Pre-Setup ###

Install Node and npm and make sure the `node` and `npm` commands are available
to you.

Create a directory for your Express site; this is usually called `app`. Create the directories that we will copy the node-express files into. See the directory layout below.

Create a lib directory nearby and extract the latest version of `web-templates`
into it.

This is a good directory layout:

    site-name
        |-> app
            |-> config
                |-> routes
                |-> site
            |-> views
                |-> css
            |-> assets
                |-> _css
                |-> _js
            |-> public
                |-> _css
                |-> _img
                |-> _js
                    |-> libs
            |-> lib
                |-> urls
                |-> users
                |-> auth
                |-> errors
        |-> lib
            |-> web-templates

### Installing node-express ###

Files in the `node-express` directory go into their corresponding directories
under your Express site's directory (the `app` directory).

Upgradable library files should be symlinked so that you can update the
`node-express` directory to upgrade them. You should keep your copy of the
whole web-templates repository in a `lib` directory next to your `app` directory
and symlink files from there.

Upgradable libraries include the following files:

* `errors`
* `public/_js/libs`
* everything in `views/css` except `style.styl`

If it's too much trouble keeping node-express in a separate directory and
symlinking certain files, you can just copy all of node-express into your Node
app's main directory. You will have to overwrite things when you upgrade
node-express, but that's not such a big deal.

Templates should be copied into your app directory because you are going to
modify them. Templates include the following files:

* `app.js`
* `package.json`
* `public/js/plugins.js`
* `public/js/script.js`
* everything in `views` except `views/css`
* `views/css/style.styl`
* everything in `routes`

After that, `cd` into your `app` directory and install the everything specified
in `packages.json` by running:

    npm install

Create a config file for your current site. You can start it by copying
`config/site.coffee.ex` to `config/site.coffee`. Modify this new config file to
match your current site's settings. You can also symlink this file into the
`config` directory form somewhere outside of `app`. This lets you keep the same
codebase and configure it for each development, test and live site you deploy
it to.

### Running node-express ###

This project layout requires that the environment variable `$NODE_PATH` be set
to the `lib` directory. For some reason, this must be done as a part of the
command that runs `coffee`. To run the site in development mode, ensure both
`node` and `coffee` are in your path, then run the following from the `app`
directory:

    NODE_PATH=lib coffee server.coffee

### urls package ###

The `url` helper method works just like Django's. Call it in a template with a URL pattern name and a dictionary of parameters, if required.

For example, in a Jade template:

    - var userUrl = url('users.view', { uid: user.username })
    li
      a(href='#{userUrl}') #{user.fullName}

To make the URLs for a route accessible to the `url` function, add them to the
`app.locals.urls` dictionary like so:

    urls = require 'urls'

    parentPath = "/users" unless parentPath
    if ! app.locals.urls
      urls.addHelpers app
    app.locals.urls['users.index'] = parentPath + "/"
    app.locals.urls['users.view'] = parentPath + "/:uid"

### Upgrading node-express ###

For most upgradable files, all you have to do is update your `web-templates`
directory.

For files in `public/js/libs`, you also have to update your `layout.jade` to
match any JavaScript file names that have changed.

For template files, update your `web-templates` directory and examine each of
these files one at a time. You will most likely not want to overwrite your
version with the new one. Instead, you want to see what has changed and why and
apply all appropriate changes manually to your version.

You can use the repository's log to help with this. You can also compare the
new version with your original using some version of diff (like `vimdiff`).


## Maintaining node-express ##

This section deals with maintaining and updating the node-express library
itself, not the copy you have in your individual projects.

Most of the files here are straight copied from their original sources. All you
need to do is get the latest version and overwrite the copy here. Some are
based on their original sources with some modifications.

### Node Packages ###

For each package in `package.json`, find the latest stable version in the [npm
registry](https://npmjs.org/) and change the version number to that. In a test
site, run `npm install` to upgrade the packages. Test the features of each
package using the default node-express site to ensure everything still works.
Fix any problems you find and commit the changes.

### Front End ###

We won't list the versions of vendor-supplied front end assets here. The files
themselves should contain their versions —even the ones that don't have a full
package in `src`. groundfloor is based on a specific version of the
Foundation's SCSS, but it lists that version in its main `index.styl`.

What we do list here are dependencies, which sometimes dictate the version
numbers we're using.

#### JavaScript ####

Other than Modernizr, all of our JavaScript is concatenated and minimized by
snockets. The file we use to put everything together with `require` statements
is `assets/_js/include.coffee`

We get `plugins.js`, `application.coffee` (based on `script.js`) and Modernizr from
[Initializr](http://www.initializr.com/).

We get jQuery from [jquery.com](http://jquery.com/). See the “Software
Versions” section for the current version.

JQuery is used by:

* foundation
* JQuery UI - needs Jquery 1.6+

We get JQuery UI from [the custom download
page](http://download.jqueryui.com/download). We keep our current build in
`src/jquery-ui`. We try to limit the build to only the widgets we need.

JQuery UI is used by:

* articles
    * [jquery-ui-sliderAccess](http://trentrichardson.com/examples/jQuery-SliderAccess/)
        * slider
        * button
    * [jquery-ui-timepicker-addon](http://trentrichardson.com/examples/timepicker/)
        * datepicker
        * slider

We get `public/js/libs/foundation` from [Foundation's
JavaScripts](https://github.com/zurb/foundation/tree/master/vendor/assets/javascripts/foundation).
We keep our current Foundation release in `src/foundation`. We try to only
include the foundation JavaScript components that we are currently using. See
`assets/_js/include.coffee` to add or remove components.

Foundation JavaScript components are used by:

* header dropdown menus
* demo effects on sample home page

Our Stylus framework, groundfloor, is based on the Foundation SCSS. See the
“Software Versions” section for the Foundation version.

We get AngularJS from [the main website](http://angularjs.org/). We keep only
the .js files in `assets/_js/libs/angular`.

AngularJS is used by:

* articles -for editing by logged-in users

#### `assets/_css/` ####

Along with the main `assets/_css/style.styl`, we also supplied a few extra
stylsheets in `assets/_css` to fill in some of the things that the current
version of Foundation is missing. These extra stylesheets can be symlinked, so
they will be updated when you update your `web-templates` directory.

### Jade templates ###

`layout.jade` is based on the "Responsive Bootstrap" `index.html` from
[Initializr](http://www.initializr.com/).

To update this, compare them with the latest version from Initializr and update
accordingly.

`home.jade` is some sample markup meant to show some features of ground-floor.
ground-floor itself doesn't have any sample markup, but it is based on
[Foundation](http://foundation.zurb.com/), so we grabbed most of the markup
from their [sample
index.html](https://github.com/zurb/foundation/blob/master/index.html). There's
not much point in updating this one. You will probably clean all of it out to
make your own homepage layout.


## URLs Use No Trailing Slashes ##

I made the decision to have no trailing slashes in the site's URLs. Regular
users have no idea what a trailing slash signifies, so it just makes the URL
look cluttered.

This is why in `config/index.coffee` I have `app.enable 'strict routing'` and
app.use errMw.removeSlash`. If you want a site that uses trailing slashes, do
not enable strict routing and instead of `removeSlash` use `app.use
errMw.addSlash`.

This causes a problem for Angular.js apps that use the `base` element to limit
them to a set of subpaths, as the Angular app for the articles section does. It
will still work in browsers that support the HTML5 history API, but older
browsers will immediately have problems. They will probably go into a redirect
loop.

The articles section's Angular app is disabled until a user logs in. This means
visitors can use the site with no problems, but logged-in users cannot use
older browsers (IE8, old Android and iPhone browsers, etc.). Angular has no
major issues supporting older browsers under base paths when the URLs have
trailing slashes, so use them if you need to. A site with public content could
also have a separate admin site for editing.

See the `lib/articles/README` for details on how to switch that app over to
using trailing slashes.
