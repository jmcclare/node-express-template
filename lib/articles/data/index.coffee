Article = require './article'


# Local Packages
User = require('users').data.User

# Use this to create some sample data.
# TODO: Update this to fit new data formats.
createSampleData = ->
  new User(
    username: 'seth'
    password: 'supersecret'
    fullName: 'Seth Goden'
    administrator: false
  ).save (err, seth) ->
    if err
      console.log 'Error saving user seth: ' + err
    console.log 'Saved user ' + seth.username
    new Article(
      title: 'Article One'
      description: "Article one's description"
      summary: "Article one's summary"
      body: 'Body of article one.'
      pubTime: new Date(2013,2,10,5,17)
      author: seth
    ).save (err, a1) ->
      if err
        console.log 'Error saving article: ' + err
      console.log 'Saved article ' + a1.title
    new Article(
      title: 'Article Two'
      description: "Article two's description"
      summary: "Article two's summary"
      body: 'Body of article two.'
      pubTime: new Date(2013,2,13,6,10)
      author: seth
    ).save (err, a2) ->
      if err
        console.log 'Error saving article: ' + err
      console.log 'Saved article ' + a2.title

# Uncomment this to create the sample data when the server is started.
#createSampleData()


module.exports =
  Article: Article
  createSampleData: createSampleData
