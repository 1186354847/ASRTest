import { BusinessError } from '@ohos.base';

/**
 * @Desc: 异常处理
 * @author: leon
 * @datetime: 2024/3/6
 */
export class SpeechException implements BusinessError<void> {
  code: number = -1;
  data?: void;
  name: string = "";
  message: string = "";
  stack?: string;

  constructor(code: number, message: string) {
    this.code = code;
    this.message = message;
  }
}
