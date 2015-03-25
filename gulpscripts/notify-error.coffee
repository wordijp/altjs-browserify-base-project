notifier = require 'node-notifier'
errLog   = require './error-log'
stripAnsi = require 'strip-ansi'

module.exports = (title, message, detail) ->
  notifier.notify({
    title: title
    message: stripAnsi(message.trim()) # �F�^�O������ƒʒm����Ȃ��Ȃ�̂Ŏ�菜��
    sound: 'Glass'
    icon: __dirname + '/error.png'
  }, () ->
    errLog(detail)
  )

