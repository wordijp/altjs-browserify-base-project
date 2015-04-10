gulp        = require 'gulp'
gutil       = require 'gulp-util'
coffee      = require 'gulp-coffee'
ts          = require 'gulp-typescript'
plumber     = require 'gulp-plumber'
duration    = require 'gulp-duration'
sourcemaps  = require 'gulp-sourcemaps'
uglify      = require 'gulp-uglify'
changed     = require 'gulp-changed'
browserify  = require 'browserify'
watchify    = require 'watchify'
runSequence = require 'run-sequence'
source      = require 'vinyl-source-stream'
buffer      = require 'vinyl-buffer'
merge       = require 'merge2'
streamqueue = require 'streamqueue'

_           = require 'lodash'
del         = require 'del'
fs          = require 'fs'
globule     = require 'globule'
Enumerable  = require 'linq'

# 外部モジュール化用
dts = require 'dts-bundle'
aem = require './gulpscripts/ambient-external-module'

# 自作スクリプト
notifyError     = require './gulpscripts/notify-error'
callback        = require './gulpscripts/gulp-callback'
samePath        = require './gulpscripts/same-path'
mergeSourcemaps = require './gulpscripts/merge-multi-sourcemap'
toRelativePath  = require './gulpscripts/to-relative-path'

errorHandler = (err) -> notifyError(err.plugin || 'compile error', err.message, err.toString()) # plumber用

is_production = require('yargs').argv.env is "production"
console.log("--env production : " + is_production)

dbgCompress        = ()           -> if is_production then uglify() else gutil.noop()
dbgInitSourcemaps  = (prop)       -> if is_production then gutil.noop() else sourcemaps.init(prop)
dbgWriteSourcemaps = (path, prop) -> if is_production then gutil.noop() else sourcemaps.write(path, prop)

# ユーザ外部モジュールのモジュール名変更チェック
prev_aliases = []
gulp.task 'check:rename-module', () ->
  aliases = Enumerable.from(aem.collect {root: 'src', include_ext: ['.ts', '.coffee'], exclude_ext: ['.d.ts']})
    .where(aem.isAlias)
    .select((x) -> x.value)
    .toArray()
    
  if (prev_aliases.length > 0)
    equal = true
    equal = equal && prev_aliases.length is aliases.length
    equal = equal && _.difference(aliases, prev_aliases).length is 0
    equal = equal && _.difference(prev_aliases, aliases).length is 0
    if (!equal)
      notifyError('check:rename-module', 'please restart gulp') # browserifyの参照ファイルを設定しなおす必要がある

  prev_aliases = aliases
  
gulp.task 'mkdir', () ->
  if (!fs.existsSync('src_typings'))
      fs.mkdir('src_typings')
  if (!fs.existsSync('src_typings_tmp'))
      fs.mkdir('src_typings_tmp')

# build tasks ---
gulp.task 'build:lib', (cb) ->
  runSequence(
    'mkdir',
    ['build:ts', 'build:coffee', 'build:html']
    cb
  )

# ts build task
dtsBundleTsModule = (tag) ->
  main = tag.file.replace(/^src/, 'src_typings_tmp').replace(/.ts$/, '.d.ts')
  dts.bundle(
    name: tag.value
    main: main
    out: main.split('/')[-1..-1][0] # 元のファイル名を渡し、renameしないように
  )

createTsModuleRootFile = () ->
  root_file = 'src_typings_tmp/tsd.d.ts'
  files = globule.find(['src_typings_tmp/**/*.d.ts', '!' + root_file])
  str = ""
  for x in files
    x = x.replace('src_typings_tmp/', '') # root_fileからの相対パスへ
    str += "/// <reference path=\"#{x}\" />\n"
  
  fs.writeFileSync(root_file, str)

ts_module_proj = ts.createProject({
  target: "ES5"
  module: "commonjs"
  sortOutput: true
  declarationFiles: true
})
ts_main_proj = ts.createProject({
  target: "ES5"
  module: "commonjs"
  sortOutput: true
})

getTsModuleTags = () ->
  Enumerable.from(aem.collect {root: 'src', include_ext: ['.ts'], exclude_ext: ['.d.ts']})
    .where(aem.isTSFile)
    .where(aem.isAlias)
    .toArray()

createTsModuleStream = (tags) ->
  files = tags.map((x) -> x.file)

  stream = gulp.src(files, {base: 'src'}) # base指定で、階層構造の崩れを無くす
    .pipe(plumber(
      errorHandler: errorHandler
    ))
    .pipe(dbgInitSourcemaps())
    .pipe(ts ts_module_proj)
    
  same_path = samePath(files)

  merge [
    stream.dts
      .pipe(gulp.dest 'src_typings_tmp')
      .pipe(callback(() ->
        tags.forEach(dtsBundleTsModule) # 外部モジュール化
        createTsModuleRootFile()        # 外部モジュールのルート定義ファイル作成
      ))

    stream.js
      .pipe(dbgWriteSourcemaps '.', {
        sourceRoot: '../' + same_path # sourcesから同名のパスが省略されてしまうので、ここで補う
        includeContent: false
      })
      .pipe(gulp.dest 'lib_tmp')
  ]
    .pipe(duration 'ts module build time')

createTsMainStream = (tags) ->
  files = _.difference(
    globule.find(['src/**/*.ts', '!src/**/*.d.ts']),
    tags.map((x) -> x.file)
  )
  
  same_path = samePath(files)

  gulp.src(files, {base: 'src'}) # base指定で、階層構造の崩れを無くす
    .pipe(plumber(
      errorHandler: errorHandler
    ))
    .pipe(dbgInitSourcemaps())
    .pipe(ts ts_main_proj)
    .js
    .pipe(dbgWriteSourcemaps '.', {
      sourceRoot: '../' + same_path # sourcesから同名のパスが省略されてしまうので、ここで補う
      includeContent: false
    })
    .pipe(gulp.dest 'lib_tmp')
    .pipe(duration 'ts main build time')

gulp.task 'pre-build:ts', () ->
  tags = getTsModuleTags()
  
  streamqueue({objectMode: true},
    createTsModuleStream(tags),
    # ファンクタを渡せるのを利用した遅延評価
    # NOTE : ユーザ外部モジュール作成後にする必要がある為
    () ->
      # IDE等の定義ファイル更新と被るといけないので変更分だけ差し替える
      gulp.src('src_typings_tmp/**/*.*')
        .pipe(changed 'src_typings', {hasChanged: changed.compareSha1Digest})
        .pipe(gulp.dest 'src_typings')
    ,
    # ファンクタを渡せるのを利用した遅延評価
    # NOTE : ユーザ外部モジュール作成後にする必要がある為
    () -> createTsMainStream(tags)
  )

gulp.task 'build:ts', ['pre-build:ts'], () ->
  gulp.src('lib_tmp/**/*.*')
    .pipe(gulp.dest 'lib') # watchifyへの通知も兼ねる

gulp.task 'build:coffee', () ->
  gulp.src('src/**/*.coffee')
    .pipe(plumber(
      errorHandler: errorHandler
    ))
    .pipe(dbgInitSourcemaps())
    .pipe(coffee())
    .pipe(dbgWriteSourcemaps '.', {
      sourceRoot: '../src'
      includeContent: false
    })
    .pipe(gulp.dest 'lib')
    
gulp.task 'build:html', () ->
  gulp.src('src/**/*.html')
    .pipe(gulp.dest 'public')
   
# browserify taks ---
watching = false
gulp.task 'enable-watch-mode', () -> watching = true
gulp.task 'disable-watch-mode', () -> watching = false
gulp.task 'browserify-core', () ->
  
  args = _.merge(watchify.args, {
    cache: {}
    packageCache: {}
    fullPaths: false
   
    debug: !is_production
  })
  b = browserify(args)
  
  # ソース一式を追加
  module_tags = Enumerable.from(aem.collect {root: './lib', include_ext: ['.js']})
    .where(aem.isAlias)
    .toArray()
  main_files = _.difference(
    globule.find('./lib/**/*.js'),
    module_tags.map((x) -> x.file)
  )
  for x in main_files
    b.add(x)
    b.require(x)
  for x in module_tags
    b.add(x.file)
    b.require(x.file, expose: x.value)
    
  bundle = () ->
    b
      .bundle()
      .on('error', errorHandler)
      .pipe(source 'bundle.js')
      .pipe(buffer())
      .pipe(dbgInitSourcemaps {loadMaps: true})
      .pipe(dbgCompress())
      .pipe(dbgWriteSourcemaps '.', {
        sourceRoot: '..'
        includeContent: false
      })
      .pipe(gulp.dest 'public')
      .pipe(duration 'browserify bundle time')
      .pipe(callback(() ->
        # 多段ソースマップの合成
        if !is_production
          second = fs.readFileSync('public/bundle.js.map').toString().trim()
          
          files = globule.find('./lib/**/*.js.map')
          second = mergeSourcemaps.merges(
            files.map((x) -> {
              value: fs.readFileSync(x).toString().trim()
              maproot: 'lib'
            }),
            {
              value: second
              maproot: 'public'
            }
          )
            
          fs.renameSync('public/bundle.js.map', 'public/bundle.js.map.old') # 保存前にオリジナルを退避
          fs.writeFileSync('public/bundle.js.map', second)
          
          gutil.log("merged sourcemap")
      ))
 
  if (watching)
    w = watchify(b, {delay: 100})
    w.on('update', bundle)
  
  bundle()
  
gulp.task 'watchify', (cb) -> runSequence('enable-watch-mode', 'browserify-core', cb)

gulp.task 'browserify', (cb) -> runSequence('disable-watch-mode', 'browserify-core', cb)

# public tasks ---
gulp.task 'pre-watch', (cb) -> runSequence('clean', 'build:lib', 'watchify', cb)
gulp.task 'watch', ['pre-watch'], () ->
  # changed watch
  changedWatch = (watch_files, task_name) ->
    watcher = gulp.watch(watch_files)
    watcher.on('change', (e) ->
      if (e.type is 'changed')
        runSequence(task_name)
    )
  changedWatch(['src/**/*.ts', '!src/**/*.d.ts'], ['check:rename-module' , 'build:ts'])
  changedWatch('src/**/*.coffee'                , ['check:rename-module' , 'build:coffee'])
  changedWatch('src/**/*.html'                  , ['build:html'])
 
  # (add | unlink) watch
  addOrUnlinkWatch = (watch_files, cb) ->
    watcher = gulp.watch(watch_files)
    watcher.on('change', (e) ->
      if (e.type is 'added' or e.type is 'deleted')
        cb(e)
    )
  addOrUnlinkWatch [
    'src/**/*.ts'
    'src/**/*.coffee'
  ], (e) ->
    notifyError('add or unlink', 'please restart gulp', toRelativePath(e.path) + " is " + e.type) # browserifyの参照ファイルを設定しなおす必要がある
  
gulp.task 'build', (cb) -> runSequence('clean', 'build:lib', 'browserify', cb)

gulp.task 'clean', (cb) -> del(['public', 'lib', 'src_typings', 'src_typings_tmp', 'tmp', 'lib_tmp'], cb)

gulp.task 'default', () ->
  console.log 'usage) gulp (watch | build | clean) [--env production]'
