# �T�v

���̃v���W�F�N�g�́AAltJS(TypeScript & CoffeeScript) & Browserify�\���̐��`�v���W�F�N�g�ł��B

�Ǝ��g���Ƃ��Ĉȉ��̑Ή������Ă��܂��B
- require����alias���w��o����
- TypeScript�ɂāA���[�U�O�����W���[���y�ь^��`�t�@�C���̎�������(import hoge = require(alias��);�Ə�����)
	- [�\�[�X�ւ�require�p��alias�A���[�U�O�����W���[�����ɂ���](#alias)
- ���i�\�[�X�}�b�v�̖����������ABrowserify������js�t�@�C������ł�AltJS�̃\�[�X��breakpoint��\���
	- [���i�\�[�X�}�b�v�̉����ɂ���](#multi_source_map)


�܂��Agulp��build��watch���ɃG���[����������ƃG���[�ʒm�������悤�ɂ��Ă��܂��B

## Usage

1. npm install
2. tsd update -s
3. gulp (watch | build | clean) [--env production]

--env production�I�v�V������t����ƌ��J�p�Ƃ��āA�������ƊJ���p�Ƃ���bundle�t�@�C���𐶐����܂��B
�����̍ہA�J���p(�I�v�V�����Ȃ�)���ƃ\�[�X�}�b�v�������A
���J�p(�I�v�V��������)����bundle�t�@�C���̈��k���s���܂��B
		
## �t�@�C���\��

- root
	- src
		- �\�[�X���[�g
	- gulpscripts
		- gulp�Ŏg�p���鎩��v���O�C��
	---
	�������玩������
	---
	- node_modules
		- node.js���W���[��
	- typings
		- TypeScript��DefinitelyTyped�p��`�t�@�C���u����
	- src_typings
		- TypeScript��src�p��`�t�@�C���u����A**gulp�ɂ�莩�����������**
	- public
		- ���ʕ��u����A**gulp�ɂ�莩�����������**
	- lib
		- �ꎞ�t�@�C���u����A**gulp���ł̂ݎg�p**
	- lib_tmp
		- lib�����O�̍�Ɨp�A**gulp���ł̂ݎg�p**


## <a name="alias"></a> �\�[�X�ւ�require�p��alias�A���[�U�O�����W���[�����ɂ���

�\�[�X���ɓƎ��^�O�ł���
```ts
// TypeScript
/// <ambient-external-module alias="{filename}" />
```
```coffee
# CoffeeScript
###
<ambient-external-module alias="{filename}" />
###
```
�𖄂ߍ��ނ��Ƃɂ��A
gulpscripts/ambient-external-module.coffee
���\�[�X���̃^�O�����W���Abrowserify�Ƀ\�[�X��ǉ�����ۂ�require���\�b�h�ɂ��alias����`����܂�
```coffee
b.require('lib/path/to/hoge.js', expose: 'hoge')
```

�܂��ATypeScript�̏ꍇ��dts-bundle�ɂ��O�����W���[��������src_typings�f�B���N�g�����Ƀ��[�U�^��`�t�@�C�����쐬����邽�߁A
```ts
/// <reference path="root/src_typings/tsd.d.ts" />

import Hoge = require('hoge');
Hoge.foo();
```
�Ƃ��������������鎖���o���܂��B

## <a name="multi_source_map"></a> ���i�\�[�X�}�b�v�̉����ɂ���

AltJS����browserify�ɂ��bundle�t�@�C�������܂ł̗���́A�ȉ��̂悤�ɂȂ��Ă��܂��B

- 1.AltJS�̃g�����X�p�C��
	- hoge.ts -> tsc -> hoge.js & hoge.js.map
	- foo.coffee -> coffee -c -> foo.js & foo.js.map
- 2.browserify�ɂ��bundle
	- (hoge.js & hoge.js.map) & (foo.js & foo.js.map) -> browserify -> bundle.js & bundle.js.map
		
���ԃt�@�C���ł���hoge.js��foo.js�̂��ꂼ��̃\�[�X�}�b�v�t�@�C����AltJS�Ƃ̕R�Â��A
�������ł���bundle.js�̃\�[�X�}�b�v�t�@�C���͒��ԃt�@�C���Ƃ̕R�Â������ꂽ��Ԃł���A
bundle.js�̃\�[�X�}�b�v�t�@�C������AAltJS�ւƒ��ڕR�Â���K�v������܂��B

�R�Â����@�ł����A[mozilla/source-map](https://github.com/mozilla/source-map/)�ɂ��\�[�X�}�b�v���̑Ή������ʒu�����v���b�g���Ă݂�ƁA
���ԃt�@�C���̃\�[�X�}�b�v�t�@�C���ł���hoge.js.map��foo.js.map��generated�̈ʒu���ƁA
�������̃\�[�X�}�b�v�t�@�C���ł���bundle.js.map��original�̈ʒu��񂪑΂ɂȂ��Ă���Ɠǂݎ��܂��B

![�\�[�X�}�b�v�̃v���b�g�摜](https://raw.github.com/wiki/wordijp/altjs-browserify-base-project/multi_source_map_prot.png)

���̑΂ɂȂ��Ă���ʒu������ɁAAltJS��original�̈ʒu���ƁA��������bundle.js��generated�̈ʒu�������o����΁A���i�\�[�X�}�b�v�̖�肪�����o���鎖�ɂȂ�܂��B

���̖�����������X�N���v�ggulpscripts/merge-multi-sourcemap.coffee���쐬���Abrowserify���s��ɑ��点�邱�Ƃł��̖����������Ă��܂��B
- ���X�N���v�g���ł́A����ɍׂ����R�Â������Ă��܂��B
- **��browserify��uglify�ɂ�鈳�k��̃\�[�X�}�b�v�Ɏ����܂������A��̈ʒu�������ɂ���錋�ʂƂȂ��Ă��܂����ׁAuglify�ƕ��p�����ꍇ�͏�肭�����Ȃ��\��������܂��B**

- �Q�l)
	- [Source Map�������֘A���C�u�����̂܂Ƃ�](http://efcl.info/2014/0622/res3933/)
	- https://github.com/azu/multi-stage-sourcemap


		

## TypeScript�̒�`�t�@�C���ɂ���

��`�t�@�C���́ADefinitelyTyped�ɂ����J����Ă��郂�W���[���p��src�f�B���N�g���p��2��ނ�����A
src�f�B���N�g���p�̒�`�t�@�C����gulp�Ŏ�����������A�܂��ATypeScript��ҏW�����ۂɂ������X�V����܂��A
�܂��ADefinitelyTyped�Ɠ��l�Ƀ��[�g�p�̒�`�t�@�C��(tsd.d.ts)��p�ӂ��Ă���ׁA
��`�t�@�C����reference�p�X��DefinitelyTyped�p�Asrc�f�B���N�g���p���ꂼ���tsd.d.ts�t�@�C�����Q�Ƃ��邾���ŗǂ��ł�

- DefinitelyTyped�p�̒�`�t�@�C��
	- typings/tsd.d.ts
		
- src�f�B���N�g���p�̒�`�t�@�C��
	- src_typings/tsd.d.ts

## Licence

MIT
