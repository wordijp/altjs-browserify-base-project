/// <reference path="../../typings/tsd.d.ts" />
/// <reference path="../../src_typings/tsd.d.ts" />

//var _: _.LoDashStatic = require('lodash');
//var React = require('react');

var a = [8, 3, 2];


console.log(a);
//console.log(_.min(a));

console.log("foo.ts");
console.log("foo.ts");

console.log("-----");
import Hoge = require('./sub/hoge');
var hoge = new Hoge.Hoge();
hoge.foo();
hoge.foo();

console.log("-----");

import Hoge2 = require('hoge');
var hoge2 = new Hoge2.Hoge();
hoge2.foo();

console.log("-----");

var CC2 = require('./sub/cc2');
CC2();

console.log("-----");

var CC22 = require('cc2');
CC22();
