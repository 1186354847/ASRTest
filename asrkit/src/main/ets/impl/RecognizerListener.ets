/**
 * @Desc:听写监听
 * @author: leon
 * @datetime: 2024/3/6
 */
import { AsrDetail } from '../model/AsrResultData'
import { SpeechException } from '../utils/exception/SpeechException'

export interface RecognizerListener {

  /**
   * 听写开始
   */
  onBeginOfSpeech: () => void
  /**
   * 听写结束
   */
  onEndOfSpeech: () => void

  /**
   * 音频分贝大小
   * @param volume
   */
  onVolumeChange: (volume: number)=> void

  /**
   * 听写结果返回
   * @param sid sid
   * @param data 返回的听写结果
   */
  onResult: (sid: string, data: AsrDetail) => void
  /**
   * 错误回调
   * @param error { SpeechError }
   */
  onError: (error: SpeechException) => void
}
