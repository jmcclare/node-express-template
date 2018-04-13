# Extended Date formatting library.
# See: http://momentjs.com/docs/
moment = require 'moment'


#
# We export only one function. This is meant to be used as an addHelpers
# function in the main config. The articles library will export it as
# addHelpers.
#
module.exports = (app) ->

  #
  # lDateFmt - Long Date Format
  #
  # Formats a Date for a long display of the date only.
  #
  # Params:
  #   * date - Date object
  #
  app.locals.lDateFmt = (date) ->
    if typeof date == 'undefined' || ! date
      return ''
    mmt = moment(date)
    return mmt.format 'ddd, MMM Do YYYY'

  #
  # sDateFmt - Short Date Format
  #
  # Formats a Date for a short display of the date only.
  #
  # Params:
  #   * date - Date object
  #
  app.locals.sDateFmt = (date) ->
    if typeof date == 'undefined' || ! date
      return ''
    mmt = moment(date)
    return mmt.format 'D MMM YYYY'

  #
  # lTimeFmt - Long Time Format
  #
  # Formats a Date for a long display of time only.
  #
  # Params:
  #   * date - Date object
  #
  app.locals.lTimeFmt = (date) ->
    if typeof date == 'undefined' || ! date
      return ''
    mmt = moment(date)
    return mmt.format 'HH:mm:ss Z'

  #
  # sTimeFmt - Short Time Format
  #
  # Formats a Date for a short display of time only.
  #
  # Params:
  #   * date - Date object
  #
  app.locals.sTimeFmt = (date) ->
    if typeof date == 'undefined' || ! date
      return ''
    mmt = moment(date)
    return mmt.format 'h:mma'
