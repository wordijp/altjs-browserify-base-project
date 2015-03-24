_ = require 'lodash'

# paths“à‚Ìˆê’v‚·‚é•”•ª‚ð•Ô‚·
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
  
  # ƒtƒ@ƒCƒ‹–¼‚ðŽæ‚èœ‚­
  paths = files.map((x) -> x.split("/")[0...-1])

  hit = 0
  min_path = _.min(paths.map((x) -> x.length))
  for i in [0...min_path]
    word = paths[0][i]
    # •sˆê’v‚ª‚ ‚Á‚½‚ç”²‚¯‚é
    wrong_index = _.findIndex(paths, (x) -> x[i] != word)
    if (wrong_index >= 0)
      break
    
    hit = i

  paths[0][0..hit].join('/')
