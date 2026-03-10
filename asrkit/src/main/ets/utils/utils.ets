/**
 * @Desc:
 * @author: leon
 * @datetime: 2024/3/6
 */

/**
 * 判断变量类型，构造函数名称
 * @param arg
 * @returns 
 */
export function typeOf(arg: ESObject): string {
  if (arg === null) {
    return "Null";
  } else if (arg === undefined) {
    return "Undefined";
  } else {
    return arg.constructor?.name ?? "";
  }
}

/**
 * 字符串是否为空
 * @param str
 * @returns
 */
export function isNullOrEmpty(str: string | null | undefined): boolean {
  return!str || str.length === 0;
}

/**
 * 判断变量是否为空
 * @param arg
 * @returns 
 */
export function isEmpty(arg: ESObject): boolean {
  switch (typeOf(arg)) {
    case "Null":
    case "Undefined":
      return true;
    case "Number":
    case "Boolean":
      return false;
    case "String":
      return (arg as string).length === 0;
    case "Array":
      return (arg as ESObject[]).length === 0;
    case "Object":
      return Object.keys(arg as Object).length === 0;
    default:
      return false;
  }
}

/**
 * 判断变量是否不为空
 * @param arg
 * @returns
 */
export function isNotEmpty(arg: ESObject): boolean {
  console.log(String(arg),'===>', isEmpty(arg))
  return !isEmpty(arg);
}