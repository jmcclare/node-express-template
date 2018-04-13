# Controllers 

angular.module('articles.controllers', [])
  .controller('IndexCtrl', ['$scope', '$http', '$routeParams', ($scope, $http, $routeParams) ->
    $scope.form = {}
    $scope.errorAlert = ''

    pageParam = if $routeParams.page then $routeParams.page else ''
    $http.get(articles.urls.partials.index + '?page=' + pageParam)
      .success((data, status) ->
        $scope.renderedArticlePageContent = data
      ).error (data, status) ->
        # TODO: display a proper 404 page for 404 status.
        $scope.renderedArticlePageContent =
          '<header><h1>Error</h1></header><p>Articles could not be retrieved.</p>'
  ])
  .controller('CreateCtrl', ['$scope', '$http', '$location', '$templateCache', ($scope, $http, $location, $templateCache) ->
    $scope.form = {}
    $scope.errorAlert = false
    $scope.fieldErrors = false
    $scope.bodyFormatOptions = articles.bodyFormatOptions

    # datetimepicker docs:
    # http://trentrichardson.com/examples/timepicker/
    # datepicker docs:
    # http://api.jqueryui.com/datepicker/
    $scope.initDTP = () ->
      $('#pubTime').datetimepicker({
        # A nice, readable format for display.
        dateFormat: "D',' M dd yy','"
        timeFormat: "h:mmtt 'GMT'Z"
        addSliderAccess: true
        sliderAccessArgs: { touchonly: false }
      })
    $scope.initDTP()

    $scope.clearDTP = () ->
      $('#pubTime').datetimepicker 'destroy'
      $('#pubTime').val ''
      $scope.form.pubTime = null
      $scope.initDTP()

    $scope.submitArticle = ()->
      if $('#pubTime').val()
        pubTime = $('#pubTime').datetimepicker 'getDate'
        $scope.form.pubTime = pubTime
      $http.post(articles.urls.api.index, $scope.form)
        .success((data, status)->
          if data.fieldErrors
            $scope.errorAlert = 'You have input errors. See below.'
            $scope.fieldErrors = angular.copy data.fieldErrors
          else
            $scope.errorAlert = ''
            #$templateCache.remove articles.urls.partials.index
            #$location.path articles.basify articles.urls.index
            $location.path articles.basify data.path
        ).error (data, status) ->
          if status == 403
            $scope.errorAlert = 'You do not have permission to create articles.'
          else
            $scope.errorAlert = 'There was an internal server error. Your article was not saved. Try again in a few minutes.'

    $scope.cancel = () ->
      $scope.form = {}
      $location.path articles.basify articles.urls.index
      #$location.path ''
  ])
  .controller('ViewCtrl', ['$scope', '$routeParams', '$http', 'artHtmlUrl', ($scope, $routeParams, $http, artHtmlUrl) ->

    curAUrl = artHtmlUrl $routeParams.slug

    $http.get(curAUrl)
      .success((data, status) ->
        $scope.renderedArticlePageContent = data
      ).error (data, status) ->
        # TODO: display a proper 404 page for 404 status.
        $scope.renderedArticlePageContent =
          '<header><h1>Error</h1></header><p>Article could not be retrieved.</p>'
  ])
  .controller('EditCtrl', ['$scope', '$http', '$location', '$templateCache', '$routeParams', 'Article', 'dataUrl', ($scope, $http, $location, $templateCache, $routeParams, Article, dataUrl) ->
    $scope.form = {}
    $scope.errorAlert = false
    $scope.fieldErrors = false
    $scope.bodyFormatOptions = articles.bodyFormatOptions

    # datetimepicker docs:
    # http://trentrichardson.com/examples/timepicker/
    # datepicker docs:
    # http://api.jqueryui.com/datepicker/
    $scope.initDTP = () ->
      $('#pubTime').datetimepicker({
        # A nice, readable format for display.
        dateFormat: "D',' M dd yy','"
        timeFormat: "h:mmtt 'GMT'Z"
        addSliderAccess: true
        sliderAccessArgs: { touchonly: false }
      })
    $scope.initDTP()

    $scope.clearDTP = () ->
      $('#pubTime').datetimepicker 'destroy'
      $('#pubTime').val ''
      $scope.form.pubTime = null
      $scope.initDTP()

    curAUrl = dataUrl $routeParams.slug

    Article.get {slug: $routeParams.slug}
      , (article, resHd) ->
        $scope.form = angular.copy article
        if article.pubTime
          date = new Date article.pubTime
          $('#pubTime').datetimepicker 'setDate', date
        $scope.article = angular.copy article
      , () ->
        $scope.errorAlert =
          'Error: Article could not be retrieved.'

    $scope.submitArticle = ()->
      if $('#pubTime').val()
        pubTime = $('#pubTime').datetimepicker 'getDate'
        $scope.form.pubTime = pubTime
      $http.put(curAUrl, $scope.form)
        .success((data, status)->
          if data.fieldErrors
            $scope.errorAlert = 'You have input errors. See below.'
            $scope.fieldErrors = angular.copy data.fieldErrors
          else
            $scope.errorAlert = ''
            $location.path articles.basify data.path
        ).error (data, status) ->
          if status == 403
            $scope.errorAlert = 'You do not have permission to edit this article.'
          else
            $scope.errorAlert = 'There was an internal server error. Your changes were not saved. Try again in a few minutes.'

    $scope.cancel = () ->
      $scope.form = {}
      if $scope.article
        $location.path articles.basify $scope.article.path
        $scope.article = {}
      else
        $location.path articles.basify articles.urls.index
  ])
  .controller('DeleteCtrl', ['$scope', '$http', '$location', '$templateCache', '$routeParams', 'Article', 'dataUrl', ($scope, $http, $location, $templateCache, $routeParams, Article, dataUrl) ->
    $scope.form = {}
    $scope.errorAlert = false
    $scope.fieldErrors = false

    curAUrl = dataUrl $routeParams.slug

    Article.get {slug: $routeParams.slug}
      , (article, resHd) ->
        $scope.form = angular.copy article
        $scope.article = angular.copy article
      , () ->
        $scope.errorAlert =
          'Error: Article could not be retrieved.'

    $scope.deleteArticle = ()->
      $http.delete(curAUrl)
        .success((data, status)->
          $scope.errorAlert = ''
          $location.path articles.basify articles.urls.index
        ).error (data, status) ->
          if status == 403
            $scope.errorAlert = 'You do not have permission to delete this article.'
          else
            $scope.errorAlert = 'There was an internal server error. Your was not deleted. Try again in a few minutes.'

    $scope.cancel = () ->
      $scope.form = {}
      if $scope.article
        $location.path articles.basify $scope.article.path
        $scope.article = {}
      else
        $location.path articles.basify articles.urls.index
  ])
