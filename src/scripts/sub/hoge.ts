/// <reference path="../../../typings/tsd.d.ts" />
/// <ambient-external-module alias="{filename}" />

export class Hoge {
  constructor() {
    console.log("Hoge()");
  }

  foo() {
    console.log("Hoge.foo");
  }
}
