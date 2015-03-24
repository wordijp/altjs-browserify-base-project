# 多段sourcemapの合成を行う
# browserifyで多段sourcemapを使えるのを目的としている
#
# 参考) http://efcl.info/2014/0622/res3933/
#       https://github.com/azu/multi-stage-sourcemap

sourceMap = require "source-map"
_ = require 'lodash'
Generator = sourceMap.SourceMapGenerator
Consumer  = sourceMap.SourceMapConsumer

# pathの冗長な登り降りを無くす
# usage) path   : src/sub1/../sub2/a.ts
#        return : src/sub2/a.ts
resolvePath = (path) ->
  new_path = []
  for x in path.split('/')
    if (x is '..')
      if (new_path.length > 0 && _.last(new_path) isnt '..')
        new_path = _.dropRight(new_path)
      else
        new_path.push(x)
    else if (x is '.')
      # no-op
    else
      new_path.push(x)
      
  new_path.join('/')

# 複数のpathを連結する
joinPaths = () ->
  paths = arguments

  f = (a, b) ->
    if (a.length > 0 && b.length > 0)
      return a + '/' + b
    if (a.length > 0)
      return a
    b

  path = ""
  for x in paths
    path = f(path, x)
    
  path

# original位置がa == bか
equalOriginal = (a, b) ->
  a.originalLine == b.originalLine && a.originalColumn == b.originalColumn
  
# original位置がa > bか
greaterThanOriginal = (a, b) ->
  a.originalLine > b.originalLine ||
    (a.originalLine == b.originalLine && a.originalColumn > b.originalColumn)

# 巻き戻っている位置情報等の不要なmappingを取り除く
filteredUseMapping = (consumer) ->
  uses = []
  for source in consumer.sources
    
    is_first = true
    prev = undefined
    consumer.eachMapping((x) ->
      if (source != x.source)
        return

      if (!prev?)
        prev = x
        return

      # 初回は次の位置情報の一つ前
      if (is_first)
        if (equalOriginal(x, prev))
          prev = x
          return

        uses.push(prev)
        is_first = false
        
      # 初回以降は最初の位置情報
      if (greaterThanOriginal(x, prev))
        uses.push(x)
        prev = x
    )

  uses
  
# firstとsecondのmappingを合成する
mergedGenerator = (first, firstUses, firstMapRoot, second, _, secondMapRoot) ->
  result = new Generator(
    file: second.file
    sourceRoot: second.sourceRoot
  )
  
  firstFile = joinPaths(firstMapRoot, first.file)
  firstFile = resolvePath(firstFile)
  
  # NOTE : eachMappingのsourceには、自動でSourceMapGeneratorのsourceRootが付与されている
  
  second.eachMapping (x) ->
    secondSource = joinPaths(secondMapRoot, x.source)
    secondSource = resolvePath(secondSource)

    if (firstFile != secondSource)
      # 合成と無関係ならそのまま追加
      result.addMapping(
        source: x.source.replace(new RegExp('^(' + second.sourceRoot + '/)?'), '')
        name: x.name
        generated:
          line: x.generatedLine
          column: x.generatedColumn
        original:
          line: x.originalLine
          column: x.originalColumn
      )
      return
    
    # 紐づいたfirstを検索
    relation_first = undefined
    for y in firstUses
      if (x.originalLine == y.generatedLine)
        relation_first = y
        break

    # 合成したmappingを追加する
    if (relation_first?)
      #firstSource = joinPaths(firstMapRoot, first.sourceRoot, relation_first.source)
      firstSource = joinPaths(firstMapRoot, relation_first.source)
      firstSource = resolvePath(firstSource)

      result.addMapping(
        source: firstSource
        name: relation_first.name
        generated:
          line: x.generatedLine
          column: x.generatedColumn
        original:
          line: relation_first.originalLine
          column: relation_first.originalColumn
      )

  result
  
# 二つのsourcemapを合成して返す
# firstObj   : 一段階目トランスパイル後のsourcemap object
# secondObj  : 二段階目(最終)トランスパイル後のsourcemap object
# NOTE : sourcemap object : { value: mapファイルの文字列, maproot: mapファイルのルートパス }
merge = (firstObj, secondObj) ->
  first = new Consumer(firstObj.value)
  second = new Consumer(secondObj.value)
  
  firstUses = filteredUseMapping(first)
  #secondUses = filteredUseMapping(second)

  result = mergedGenerator(
    first, firstUses, firstObj.maproot,
    second, undefined, secondObj.maproot
  )

  result.toString()

module.exports.merge = merge
