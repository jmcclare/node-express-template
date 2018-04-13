'use strict'


if typeof articles == 'undefined'
  articles = {}
articles.bodyFormatOptions = [
    'markdown'
    'HTML5'
    'jade'
  ]


# Declare app level module which depends on filters, and services
angular.module(
  "articles"
  [
    'articles.controllers'
    'articles.filters'
    'articles.services'
    'articles.directives'
    'ngSanitize'
    'ngResource'
  ]
).config(
  [
    "$routeProvider"
    "$locationProvider"
    ($routeProvider, $locationProvider) ->

      # We tack on the trailing slash so that this will work with the base path
      # (which also needs a trailing slash).
      indexRoute = articles.basify(articles.urls.index) + '/'
      $routeProvider.when indexRoute,
        templateUrl: articles.urls.ngtpl.index
        controller: 'IndexCtrl'

      createRoute = articles.basify articles.urls.create
      $routeProvider.when createRoute,
        templateUrl: articles.urls.ngtpl.create
        controller: 'CreateCtrl'

      viewRoute = articles.basify articles.urls.view
      $routeProvider.when viewRoute,
        templateUrl: articles.urls.ngtpl.view
        controller: "ViewCtrl"

      editRoute = articles.basify articles.urls.edit
      $routeProvider.when editRoute,
        templateUrl: articles.urls.ngtpl.edit
        controller: "EditCtrl"

      deleteRoute = articles.basify articles.urls.delete
      $routeProvider.when deleteRoute,
        templateUrl: articles.urls.ngtpl.delete
        controller: "DeleteCtrl"

      #$routeProvider.otherwise redirectTo: articles.urls.index
      $locationProvider.html5Mode(true)
  ]
)
