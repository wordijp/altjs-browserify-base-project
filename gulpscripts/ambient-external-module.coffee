# ambient external module script
#
# �\�[�X�ɐ�p�^�O��t�^���A���ꂼ��̃^�O���W���s���܂�
# 
# usage)
#   �f�B���N�g���\���ƁA�\�[�X�t�@�C�����̐�p�^�O�����L�̂悤�ɂȂ��Ă���Ƃ��܂�
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
#   �ƃ^�O�����W�����
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
#   �Ƃ������ʂ��Ԃ�܂�
#   ���Ƃ́A���̌��ʂ��Awebpack��dts-bundle�g�p���ɕK�v�Ȍ��ʂ����o���Ďg�p���܂�

gutil      = require 'gulp-util'
globule    = require 'globule'
Enumerable = require 'linq'
defaults   = require 'defaults'

errLog   = require './error-log'
grepSync = require './grep-sync'

tag_name = 'ambient-external-module'

# tag���̗v�f���A�����ƈ�v���邩
isKeyValue = (tag, key_key, key_value) -> tag[key_key].match(key_value)?
  
# �^�O����{}�v���p�e�B���̕ϊ�����
propertyParsers =
  {
    # �t�@�C���p�X����g���q�����̃t�@�C���������o��
    filename: (filepath) ->
      str = filepath.split('/')[-1..-1][0]
      str.split('.')[0] # �g���q������

    # �t�@�C���p�X����f�B���N�g���������o��
    dirname: (filepath) -> filepath.split('/')[-2..-2][0]
  }

# �^�O�����I�u�W�F�N�g�ŕԂ�
toTagObject = (file, type, value) ->
  {
    file: file
    type: type
    value: value
  }

# �v���p�e�B���܂�value_str��W�J����
parseValues = (value_str, file) ->
  value = ""
  # ��������A�v���p�e�B���A�v���p�e�B�łȂ����ɕ�������
  # ex) '{dirname].{filename}' -> ['{dirname}, '.', '{filename}]
  for x in value_str.match(/((\{[^\{\}]+\})|([^\{\}]+))/g)
    matched = x.match(/\{(.+)\}/)

    # �v���p�e�B�̏ꍇ
    if (matched)
      prop = matched[1]
      if (propertyParsers[prop]?)
        value += propertyParsers[prop](file)
      else
        errLog("unknown property:" + prop + " file:" + file)
    # �v���p�e�B�ȊO�̏ꍇ
    else
      value += x
  
  value

module.exports =
  # �v���W�F�N�g���̃\�[�X����^�O�����W���A�Ԃ�
  collect: (conf) ->
    # ����`�̎���Default�l
    config = defaults(conf, {
      root: 'src'
      include_ext: ['.ts', '.coffee']
      exclude_ext: ['.d.ts']
    })

    # �v���W�F�N�g���̃\�[�X�����W
    includes = config.include_ext.map((x) -> config.root + '/**/*' + x)
    excludes = config.exclude_ext.map((x) -> '!' + config.root + '/**/*' + x)
    files = globule.find(includes.concat(excludes))
    
    # �t�@�C������^�O�ꗗ�����W����
    tags = Enumerable.from(files)
      .select((file) ->
        ret = grepSync(['-w', tag_name, file])
        if (!ret)
          return {}
          
        type_value = ret.split(tag_name)[1].trim()
        split = type_value.split('=')
        type  = split[0]
        value = split[1]
        
        # value���̕���������o��
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

