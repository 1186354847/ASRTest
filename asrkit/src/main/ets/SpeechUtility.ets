/**
 * @Desc: SDK配置类
 * @author: leon
 * @datetime: 2024/3/19
 */
import { HashMap } from '@kit.ArkTS'
import { isNullOrEmpty } from './utils/utils'
import { SpeechException } from './utils/exception/SpeechException'
import { SpeechError } from './utils/exception/SpeechError'

export class SpeechUtility {
  // 用户语音配置对象
  private static sUtility?: SpeechUtility = undefined;
  /**
   * 参数配置
   */
  private params = new HashMap<string, string>()

  /**
   * 创建配置单例
   * 启动参数，包含以下参数:
   * @param params appId,apiKey,apiSecret 各参数间，以英文逗号分隔，如"appId=12345678,apiKey=xxxxx"
   */
  public static createUtility(params: string) {
    if (isNullOrEmpty(params)) {
      throw new SpeechException(SpeechError.INIT_ERROR_CODE, "初始化配置参数错误");
    }
    if (!SpeechUtility.sUtility) {
      SpeechUtility.sUtility = new SpeechUtility(params);
    }
  }

  private constructor(params: string) {
    let array = params.split(",") ?? [];
    for (let entry of array) {
      let pair = entry.split("=") ?? [];
      if (pair.length > 1) {
        this.setParameter(pair[0], pair[1]);
      }
    }
  }

  /**
   * 获取配置单例
   * @returns
   */
  public static getUtility(): SpeechUtility | undefined {
    return SpeechUtility.sUtility;
  }


  /**
   * 设置识别参数
   */
  public setParameter(key: string, value: string) {
    this.params.set(key, value);
  }


  /**
   * 获取识别参数
   * @param key
   */
  public getParameter(key: string): string {
    try {
      let tempValue = this.params.get(key) ?? "";
      return isNullOrEmpty(tempValue) ? "" : tempValue;
    } catch (e) {
      return "";
    }
  }
}
