# ambient external module script
#
# ソースに専用タグを付与し、それぞれのタグ収集を行います
# 
# usage)
#   ディレクトリ構成と、ソースファイル内の専用タグが下記のようになっているとします
#   - src
#     - moduleA.ts     : /// <ambient-external-module name='moduleA' />
#     - moduleB.coffee : /// <ambient-external-module name='{filename}' />
#     - hogedir
#       - moduleC.ts   : /// <ambient-external-module alias='moduleC' />
#
#   aem = require('./ambient-external-module')
#   config =
#      root: 'src'
#      include_ext: ['.ts', '.coffee']
#      exclude_ext: ['.d.ts']
#   tags = aem.collect config
#   とタグを収集すると
#
#   [
#     {
#       file: 'src/moduleA.ts'
#       type: 'name'
#       value: 'moduleA'
#     },
#     {
#       file: 'src/moduleB.coffee'
#       type: 'name'
#       value: 'moduleB'
#     },
#     {
#       file: 'src/hogedir/moduleC.ts'
#       type: 'alias'
#       value: 'moduleC'
#     }
#   ]
#   という結果が返ります
#   あとは、この結果を、webpackやdts-bundle使用時に必要な結果を取り出して使用します

gutil      = require 'gulp-util'
globule    = require 'globule'
Enumerable = require 'linq'
defaults   = require 'defaults'

errLog   = require './error-log'
grepSync = require './grep-sync'

tag_name = 'ambient-external-module'

# tag内の要素が、引数と一致するか
isKeyValue = (tag, key_key, key_value) -> tag[key_key].match(key_value)?
  
# タグ内の{}プロパティ内の変換処理
propertyParsers =
  {
    # ファイルパスから拡張子無しのファイル名を取り出す
    filename: (filepath) ->
      str = filepath.split('/')[-1..-1][0]
      str.split('.')[0] # 拡張子無しへ

    # ファイルパスからディレクトリ名を取り出す
    dirname: (filepath) -> filepath.split('/')[-2..-2][0]
  }

# タグ情報をオブジェクトで返す
toTagObject = (file, type, value) ->
  {
    file: file
    type: type
    value: value
  }

# プロパティを含むvalue_strを展開する
parseValues = (value_str, file) ->
  value = ""
  # 文字列を、プロパティか、プロパティでないかに分解する
  # ex) '{dirname].{filename}' -> ['{dirname}, '.', '{filename}]
  for x in value_str.match(/((\{[^\{\}]+\})|([^\{\}]+))/g)
    matched = x.match(/\{(.+)\}/)

    # プロパティの場合
    if (matched)
      prop = matched[1]
      if (propertyParsers[prop]?)
        value += propertyParsers[prop](file)
      else
        errLog("unknown property:" + prop + " file:" + file)
    # プロパティ以外の場合
    else
      value += x
  
  value

module.exports =
  # プロジェクト内のソースからタグを収集し、返す
  collect: (conf) ->
    # 未定義の時はDefault値
    config = defaults(conf, {
      root: 'src'
      include_ext: ['.ts', '.coffee']
      exclude_ext: ['.d.ts']
    })

    # プロジェクト内のソースを収集
    includes = config.include_ext.map((x) -> config.root + '/**/*' + x)
    excludes = config.exclude_ext.map((x) -> '!' + config.root + '/**/*' + x)
    files = globule.find(includes.concat(excludes))
    
    # ファイルからタグ一覧を収集する
    tags = Enumerable.from(files)
      .select((file) ->
        ret = grepSync(['-w', tag_name, file])
        if (!ret)
          return {}
          
        type_value = ret.split(tag_name)[1].trim()
        split = type_value.split('=')
        type  = split[0]
        value = split[1]
        
        # value内の文字列を取り出す
        matched = value.match(/[\"\'](.+)[\"\']/)
        if (!matched)
          errLog("failed to value.match file:" + file)
          return {}
        
        parsed_value = parseValues(matched[1], file)
        toTagObject(file, type, parsed_value)
      )
      .where((obj) -> Object.keys(obj).length > 0)
      .toArray()

    #console.log("-----------------------")
    #console.log("tags:")
    #console.log(tags)
    #console.log("-----------------------")

    tags

  # filtering methods ---

  isAlias:  (tag) -> isKeyValue(tag, 'type', 'alias')
  isName:   (tag) -> isKeyValue(tag, 'type', 'name')
  isTSFile: (tag) -> isKeyValue(tag, 'file', /.ts$/)

