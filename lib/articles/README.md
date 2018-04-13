# Articles #

This library implements a sample articles section for a website. It uses
Angular.js to implement the article editing forms.

Since Angular.js doesn't work perfectly for older browsers, I chose to disable
it when there is no user logged in. This keeps the experience consistent for
all visitors.


## Installation ##

### Dependencies ###

Short version:

* open `package.json`
* make sure `projectDependencies` are included in site's `package.json`
* make sure `localDependencies` are available in `NODE_PATH`

In `package.json`, we have 3 sets of dependencies.

`dependencies` is for regular Node.js package dependencies.

Since there is no automatic way to have npm go into each package in your
`NODE_PATH` and install these dependencies, we have already installed these and
included them with the package. They are in the articles app's `node_modules`
directory.

You can upgrade these by changing the version number in the articles
`package.json`, and then changing to the articles directory and running `npm
install -l`.

`projectDependencies` are dependencies that should be placed in the main
project's `packages.json`. We try to keep the version here completely open to
avoid conflicts. Currently, this is only mongoose. We could include an
installation of this package here, but you need to at least setup a MongoDB
connection for the site in the site's main config, and it's best if this
package uses the same version of mongoose the site is using.

`localDependencies` are other private packages like this one, included in this
site's `NODE_PATH` and not available from NPM.

### Routes ###

In the `addRoutes` function in `config/routes.coffee`, add:

  articles.routes.assign app
     
This will place all of the articles routes under the `/articles` path. If you
want to place them under a different path, pass that as the second parameter,
like this:

  articles.routes.assign app, '/blog'

### Views ###

For development, we have the articles `views` directory symlinked into the main
project's `views` directory. For indiviual sites, you will almost definitely
want to customize the views, so copy the contents of `lib/articles/views` into
`views/articles` (delete the `views/articles` symlink first).

### JavaScript ###

articles uses AngularJS for editing. It also makes switching between article
views and the articles index page faster, but we only enable for logged-in
users due to IE8 issues (see "trailing slashes" below).

To add the articles JavaScript, copy or symlink `lib/articles/assets/_js` to `assets/_js/articles`. In `assets/_js/include.coffee`, add the following:

  # The code for editing articles. Remove this if you are not using the articles
  # app.
  #= require articles/include.coffee

### CSS ###

Currently, the default articles views require no custom CSS outside of what the
main site template has.

### robots.txt ###

Add the following to the site's `robots.txt`:

    Disallow: /articles/create
    Disallow: /articles/edit/
    Disallow: /articles/delete/
    Disallow: /articles/_partials/
    Disallow: /articles/_ngtpl/
    Disallow: /articles/_api/

Replace `articles` with whatever you specified for `parentPath` when you added
the articles routes (see above). These are some of the article app's URLs
placed in `req.locals.urls`. If your `robots.txt` is rendered by a view, use
those variables.


## Trailing Slashes ##

To match the rest of the site template, this section has no trailing slashes on
the URLs. This means that logged-in users who login with IE8, older Android
browsers, or any that don't support the HTML5 history API will run into a
circular redirect loop when using this section because of the Angular.js app.
There is more about this in the site template's main `README.md`.

### Converting to No Trailing Slashes ###

To convert this section to one that uses trailing slashes, first follow the
instructions in the main `README.md`.

In `routes.coffee`, add a trailing slash to all public URLs. Skip the partials
and ngtpl URLs.

Remove the added trailing slash from every place where `baseURL` is assigned.

In `views/layout.jade`, in `articles.basify`, change `return url.replace(re, '');` to `return url.replace(re, '/');`.

In `assets/_js/app.coffee`, remove the trailing slash from `indexRoute`.

That's it. The articles section will now use trailing slashes everywhere.

To make this Angular app work when then URLs have no trailing slashes, we had
to add one to the `base` meta tag and the "root" path of the Angular app (in
`app.coffee`). Although the server will redirect you away from the trailing
slash, the Angular app will tack one on as soon as it activates.

Notice that you can still have routes with no trailing slash (like the partials
and ntgpl routes), but the user will not be automatically redirected if they
add a trailing slash on their own.
