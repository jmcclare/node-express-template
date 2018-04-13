# Filters 

angular.module("articles.filters", [])
.filter(
  "interpolate"
  [
    "version"
    (version) ->
      (text) ->
        String(text).replace /\%VERSION\%/g, version
  ]
)
