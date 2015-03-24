# 概要

このプロジェクトは、AltJS(TypeScript & CoffeeScript) & Browserify構成の雛形プロジェクトです。

独自拡張として以下の対応をしています。
- require時にaliasを指定出来る
- TypeScriptにて、ユーザ外部モジュール及び型定義ファイルの自動生成(import hoge = require(alias名);と書ける)
	- [ソースへのrequire用のalias、ユーザ外部モジュール化について](#alias)
- 多段ソースマップの問題を解決し、Browserify生成のjsファイルからでもAltJSのソースにbreakpointを貼れる
	- [多段ソースマップの解決について](#multi_source_map)


また、gulpのbuildやwatch中にエラーが発生するとエラー通知がされるようにしています。

## Usage

1. npm install
2. tsd update -s
3. gulp (watch | build | clean) [--env production]

--env productionオプションを付けると公開用として、無しだと開発用としてbundleファイルを生成します。
生成の際、開発用(オプションなし)だとソースマップ生成を、
公開用(オプションあり)だとbundleファイルの圧縮を行います。
		
## ファイル構成

- root
	- src
		- ソースルート
	- gulpscripts
		- gulpで使用する自作プラグイン
	---
	ここから自動生成
	---
	- node_modules
		- node.jsモジュール
	- typings
		- TypeScriptのDefinitelyTyped用定義ファイル置き場
	- src_typings
		- TypeScriptのsrc用定義ファイル置き場、**gulpにより自動生成される**
	- public
		- 成果物置き場、**gulpにより自動生成される**
	- lib
		- 一時ファイル置き場、**gulp内でのみ使用**
	- lib_tmp
		- lib生成前の作業用、**gulp内でのみ使用**


## <a name="alias"></a> ソースへのrequire用のalias、ユーザ外部モジュール化について

ソース中に独自タグである
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
を埋め込むことにより、
gulpscripts/ambient-external-module.coffee
がソース中のタグを収集し、browserifyにソースを追加する際にrequireメソッドによりaliasが定義されます
```coffee
b.require('lib/path/to/hoge.js', expose: 'hoge')
```

また、TypeScriptの場合はdts-bundleにより外部モジュール化されsrc_typingsディレクトリ内にユーザ型定義ファイルが作成されるため、
```ts
/// <reference path="root/src_typings/tsd.d.ts" />

import Hoge = require('hoge');
Hoge.foo();
```
という書き方をする事が出来ます。

## <a name="multi_source_map"></a> 多段ソースマップの解決について

AltJSからbrowserifyによるbundleファイル生成までの流れは、以下のようになっています。

- 1.AltJSのトランスパイル
	- hoge.ts -> tsc -> hoge.js & hoge.js.map
	- foo.coffee -> coffee -c -> foo.js & foo.js.map
- 2.browserifyによるbundle
	- (hoge.js & hoge.js.map) & (foo.js & foo.js.map) -> browserify -> bundle.js & bundle.js.map
		
中間ファイルであるhoge.jsやfoo.jsのそれぞれのソースマップファイルはAltJSとの紐づけ、
生成物であるbundle.jsのソースマップファイルは中間ファイルとの紐づけがされた状態であり、
bundle.jsのソースマップファイルから、AltJSへと直接紐づける必要があります。

紐づけ方法ですが、[mozilla/source-map](https://github.com/mozilla/source-map/)によりソースマップ内の対応した位置情報をプロットしてみると、
中間ファイルのソースマップファイルであるhoge.js.mapやfoo.js.mapのgeneratedの位置情報と、
生成物のソースマップファイルであるbundle.js.mapのoriginalの位置情報が対になっていると読み取れます。

![ソースマップのプロット画像](https://raw.github.com/wiki/wordijp/altjs-browserify-base-project/multi_source_map_prot.png)

この対になっている位置情報を基に、AltJSのoriginalの位置情報と、生成物のbundle.jsのgeneratedの位置情報を取り出せれば、多段ソースマップの問題が解決出来る事になります。

この問題を解決するスクリプトgulpscripts/merge-multi-sourcemap.coffeeを作成し、browserify実行後に走らせることでこの問題を解決しています。
- ※スクリプト内では、さらに細かく紐づけをしています。
- **※browserifyでuglifyによる圧縮後のソースマップに試しましたが、列の位置が微妙にずれる結果となってしまった為、uglifyと併用した場合は上手く動かない可能性があります。**

- 参考)
	- [Source Mapを扱う関連ライブラリのまとめ](http://efcl.info/2014/0622/res3933/)
	- https://github.com/azu/multi-stage-sourcemap


		

## TypeScriptの定義ファイルについて

定義ファイルは、DefinitelyTypedにより公開されているモジュール用とsrcディレクトリ用の2種類があり、
srcディレクトリ用の定義ファイルはgulpで自動生成され、また、TypeScriptを編集した際にも自動更新されます、
また、DefinitelyTypedと同様にルート用の定義ファイル(tsd.d.ts)を用意している為、
定義ファイルのreferenceパスはDefinitelyTyped用、srcディレクトリ用それぞれのtsd.d.tsファイルを参照するだけで良いです

- DefinitelyTyped用の定義ファイル
	- typings/tsd.d.ts
		
- srcディレクトリ用の定義ファイル
	- src_typings/tsd.d.ts

## Licence

MIT
