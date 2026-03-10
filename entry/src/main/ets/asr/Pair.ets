/**
 * @Desc: Pair类
 * @author: leon
 * @datetime: 2023/12/26
 */
export default class Pair<K, V> {

  private _first: K
  private _second: V

  constructor(key: K, value: V) {
    this._first = key
    this._second = value
  }

  public set first(value: K) {
    this._first = value
  }

  public get first(): K {
    return this._first
  }

  public set second(value: V) {
    this._second = value
  }

  public get second(): V {
    return this._second
  }
}
