# stream�̗���̒��ŃR�[���o�b�N���Ăׂ�悤�ɂ���

through = require 'through2'

module.exports = (cb) ->
  transform = (file, encoding, callback) ->
    this.push(file)
    callback()

  flush = (callback) ->
    cb()
    callback()

  through.obj(transform, flush)
