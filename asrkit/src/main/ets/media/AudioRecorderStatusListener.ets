/**
 * @Desc: 麦克风状态回调
` * @author: leon
 * @datetime: 2024/3/6
 */
import { SpeechException } from '../utils/exception/SpeechException'

export interface AudioRecorderStatusListener {

  /**
   * 麦克风收音开始
   */
  onRecordStart: () => void;

  /**
   * 听写结束
   */
  onRecordStop: () => void;

  /**
   * 音频采集返回实时回调
   * @param data pcm音频流
   * @param volume 分贝
   */
  onRecordProgress: (data: ArrayBuffer, volume: number) => void;


  /**
   * 错误回调
   * @param error { SpeechException }
   */
  onRecordError: (error: SpeechException) => void;
}
