# Services 

# The first one it is a simple value service.
angular.module("articles.services", ['ngResource'])
  .value("version", "0.1")
  # We have to declare the $resource dependency this way to avoid problems when
  # the JS minifier changes the callback function's recieved variable name.
  # See: http://docs.angularjs.org/guide/di starting at "DI in controllers"
  .factory('Article', ['$resource', ($resource) ->
    # Until I know how to properly return errors and error data for resources,
    # I will only use this for retrieving articles.
    return $resource(articles.urls.api.item, {slug: '@slug'},
      update:
        method: 'PUT'
    )
  ])
  .factory('dataUrl', () ->
    return (slug) ->
      return articles.urls.api.item.replace(new RegExp(':slug', 'gm'), slug)
  )
  .factory('artHtmlUrl', () ->
    return (slug) ->
      return articles.urls.partials.view.replace(new RegExp(':slug', 'gm'), slug)
  )
