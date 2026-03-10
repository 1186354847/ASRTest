/**
 * @Desc: 错误码
 * @author: leon
 * @datetime: 2024/3/6
 */

export class SpeechError {


  /**
   * 初始化配置参数错误
   */
  public static readonly INIT_ERROR_CODE = 900000


   /**
   * 鉴权失败错误码
   */
  public static readonly AUTH_ERROR_CODE = 900001


  /**
   * 麦克风初始化失败
   */
  public static readonly AUDIO_RECORDER_INIT_ERROR_CODE = 900002

  /**
   * 麦克风音频采集失败
   */
  public static readonly AUDIO_RECORDER_START_ERROR_CODE = 900003


  /**
   * asr在线听写返回失败
   */
  public static readonly ASR_CONTINUE_ERROR_CODE = 900004

  /**
   * asr在线听写数据解析失败
   */
  public static readonly ASR_RESULT_ERROR_CODE = 900005


  /**
   * SDK配置类未初始化
   */
  public static readonly SPEECHUTILITY_ERROR_CODE = 900006

}
