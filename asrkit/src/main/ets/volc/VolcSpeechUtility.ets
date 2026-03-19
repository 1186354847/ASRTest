import { HashMap } from '@kit.ArkTS'
import { isNullOrEmpty } from '../utils/utils'
import { SpeechError } from '../utils/exception/SpeechError'
import { SpeechException } from '../utils/exception/SpeechException'

export class VolcSpeechUtility {
  private static sUtility?: VolcSpeechUtility = undefined
  private params = new HashMap<string, string>()

  public static createUtility(params: string) {
    if (isNullOrEmpty(params)) {
      throw new SpeechException(SpeechError.INIT_ERROR_CODE, '初始化配置参数错误')
    }
    if (!VolcSpeechUtility.sUtility) {
      VolcSpeechUtility.sUtility = new VolcSpeechUtility(params)
    }
  }

  public static getUtility(): VolcSpeechUtility | undefined {
    return VolcSpeechUtility.sUtility
  }

  private constructor(params: string) {
    let array = params.split(',') ?? []
    for (let entry of array) {
      let pair = entry.split('=') ?? []
      if (pair.length > 1) {
        this.setParameter(pair[0], pair.slice(1).join('='))
      }
    }
  }

  public setParameter(key: string, value: string) {
    this.params.set(key, value)
  }

  public getParameter(key: string): string {
    try {
      let value = this.params.get(key) ?? ''
      return isNullOrEmpty(value) ? '' : value
    } catch (e) {
      return ''
    }
  }
}
