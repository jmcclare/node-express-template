# Directives 

angular.module("articles.directives", [])
.directive(
  "appVersion"
  [
    "version"
    (version) ->
      (scope, elm, attrs) ->
        elm.text version
  ]
)
