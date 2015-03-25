notifier = require 'node-notifier'
errLog   = require './error-log'
stripAnsi = require 'strip-ansi'

module.exports = (title, message, detail) ->
  notifier.notify({
    title: title
    message: stripAnsi(message.trim()) # 色タグがあると通知されなくなるので取り除く
    sound: 'Glass'
    icon: __dirname + '/error.png'
  }, () ->
    errLog(detail)
  )

