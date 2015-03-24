_ = require 'lodash'

# paths���̈�v���镔����Ԃ�
# usage)
#   # return "src/scripts"
#   samePath([
#     "src/scripts/a.txt"
#     "src/scripts/b.txt"
#     "src/scripts/components/c.txt"
#   ])
module.exports = (files) ->
  if (files.length == 0)
    return ""
  
  # �t�@�C��������菜��
  paths = files.map((x) -> x.split("/")[0...-1])

  hit = 0
  min_path = _.min(paths.map((x) -> x.length))
  for i in [0...min_path]
    word = paths[0][i]
    # �s��v���������甲����
    wrong_index = _.findIndex(paths, (x) -> x[i] != word)
    if (wrong_index >= 0)
      break
    
    hit = i

  paths[0][0..hit].join('/')
