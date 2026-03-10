import { AudioRecorder } from './media/AudioRecorder'
import { AudioRecorderStatusListener } from './media/AudioRecorderStatusListener'
import { RecognizerListener } from './impl/RecognizerListener'
import { SpeechError } from './utils/exception/SpeechError'
import { SpeechException } from './utils/exception/SpeechException'
import { Logger } from './utils/Logger'
import { HashMap, Queue } from '@kit.ArkTS'
import { AudioStatus } from './model/AudioStatus'
import { AudioData } from './model/AudioData'
import { AsrDetail, AsrResult } from './model/AsrResultData'
import { SpeechUtility } from './SpeechUtility'
import { SpeechConstants } from './utils/SpeechConstants'
import { webSocket } from '@kit.NetworkKit'
import { AuthUtils } from './utils/AuthUtils'
import { isNotEmpty } from './utils/utils'
import { BusinessError } from '@kit.BasicServicesKit'
import { AsrBusinessParams, AsrParams } from './model/AsrParams'
import { util } from '@kit.ArkTS';


/**
 * @Desc: 语音听写对象
 * @author: leon
 * @datetime: 2024/3/6
 */
export class SpeechRecognizer implements AudioRecorderStatusListener {
  audioRecorder: AudioRecorder = new AudioRecorder();
  speechCallback?: RecognizerListener
  queueInterval: number = 0
  audioMessageQueue?: Queue<AudioData> | null = null
  audioStatus: AudioStatus = AudioStatus.START
  ws?: webSocket.WebSocket
  hostApi: string = "https://iat-api.xfyun.cn/v2/iat";
  appId: string = "";
  params: HashMap<string, string | number | boolean> = new HashMap();
  audioLoop: boolean = false;

  /**
   * 初始化
   * @returns
   */
  private async initialize(): Promise<string> {
    return new Promise<string>(async (resolve, reject) => {
      let utility = SpeechUtility.getUtility();
      if (utility == undefined) {
        throw new SpeechException(SpeechError.SPEECHUTILITY_ERROR_CODE, "SDK配置类未初始化");
      }
      this.appId = utility.getParameter(SpeechConstants.APP_ID);
      const apiKey = utility.getParameter(SpeechConstants.API_KEY);
      const apiSecret = utility.getParameter(SpeechConstants.API_SECRET);
      let url = await AuthUtils.assembleRequestUrl(this.hostApi, apiKey, apiSecret);
      url = url?.replace("https://", "wss://") ?? ""
      this.ws = webSocket.createWebSocket();
      resolve(url);
    });
  }

  /**
   * 添加入参
   * @param params
   */
  private paramsFormatString(params: Map<string, string | number | boolean>): string {
    let query = ""
    let index = 0
    for (let entry of params.entries()) {
      let key = entry[0];
      let value = entry[1];
      query += `${key}=${value}`
      if (index != params.size - 1) {
        query += "&"
      }
      index++;
    }
    return query;
  }

  async startListening(params: HashMap<string, string | number | boolean>, listener: RecognizerListener) {
    this.speechCallback = listener;
    this.params = params;
    try {
      let result = await this.initialize();
      Logger.debug("鉴权结果 result==>" + result);
      if (isNotEmpty(result)) {
        this.startAudioRecording(result);
      } else {
        this.speechCallback?.onError(new SpeechException(SpeechError.AUTH_ERROR_CODE, "听写鉴权失败"));
      }
    } catch (error) {
      this.speechCallback?.onError(error);
    }
  }

  /**
   * 麦克风音频采集
   */
  private startAudioRecording(authUrl: string) {
    this.audioStatus = AudioStatus.START;
    this.audioMessageQueue = new Queue();
    this.ws?.on("open", (err: BusinessError, value: Object) => {
      //console.log("听写WSS打开, status:" + JSON.stringify(value));
      this.audioRecorder?.setAudioRecorderChange(this);
      this.audioRecorder?.startRecording();
    });
    this.ws?.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
      //console.log("听写WSS接收消息, message:" + value);
      if (value instanceof ArrayBuffer) {
        return
      }
      this.parseAsrResult(value);
    });
    this.ws?.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
      //console.log("听写WSS关闭, code is " + value.code + ", reason is " + value.reason);
    });
    this.ws?.on('error', (err: BusinessError) => {
      //console.log("听写WSS错误, error:" + JSON.stringify(err));

    });
    this.ws?.connect(authUrl, {}, (err: BusinessError, value: boolean) => {
      if (!err) {
        //console.log("听写WSS Connected successfully");
      } else {
        //console.log("听写WSS Connection failed. Err:" + JSON.stringify(err));
      }
    });
  }


  /**
   * 音频录制开始回调
   */
  onRecordStart() {
    this.audioLoop = true;
    //Logger.debug("麦克风==>onRecordStart");
    this.speechCallback?.onBeginOfSpeech();
    this.addAudioBuffer(new AudioData(AudioStatus.START, new ArrayBuffer(640)))
    this.handleAudioMessage();
  }

  onRecordProgress(data: ArrayBuffer, volume: number) {
    this.audioStatus = AudioStatus.CONTINUE;
    let audioData = new AudioData(AudioStatus.CONTINUE, data)
    this.addAudioBuffer(audioData);
    this.speechCallback?.onVolumeChange(volume);
  }

  onRecordStop() {
    this.audioLoop = false;
    //Logger.debug("麦克风==>onRecordStop");
    this.audioStatus = AudioStatus.END;
    this.speechCallback?.onEndOfSpeech();
  }

  onRecordError(error: SpeechException) {
    this.audioLoop = false;
    //Logger.debug("麦克风==>onRecordError");
    this.audioStatus = AudioStatus.END;
    this.speechCallback?.onEndOfSpeech();
  }


  /**
   * 将音频流添加到消息队列里面去
   * @param data pcm音频流
   */
  private addAudioBuffer(data: AudioData) {
    // Logger.debug("发送音频流数据==" + data.byteLength)
    this.audioMessageQueue?.add(data);
  }


  /**
   * 停止识别
   * 在调用本函数后，已录入的音频还在继续上传到服务器，结果不会马上就返回，当前会
   * 话还在继续，直到结果返回完毕，或出现错误。
   */
  stopListening() {
    this.audioRecorder?.onStopRecord();
  }


  /**
   * 取消会话
   * 通过此函数取消当前的会话
   * 在会话被取消后，当前会话结束，未返回的结果将不再返回。
   */
  cancel() {
    this.audioStatus = AudioStatus.CANCEL;
    this.reset();
  }

  /**
   * 重置相关资源
   */
  private reset() {
    this.audioLoop = false;
    try {
      this.audioRecorder?.onStopRecord();
      clearInterval(this.queueInterval);
    } catch (e) {
      Logger.debug("reset resource error!");
    }
  }

  /**
   * 从消息队列里面获取消息并发送
   */
  private handleAudioMessage() {
    clearInterval(this.queueInterval)
    this.queueInterval = setInterval(() => {
      let complete = (this.audioStatus == AudioStatus.END || this.audioStatus == AudioStatus.CANCEL) &&
        (this.audioMessageQueue?.length ?? 0) <= 0;
      if (complete) {
        clearInterval(this.queueInterval)
        return;
      }
      let audioData = this.audioMessageQueue?.pop()
      if (audioData && this.audioLoop) {
        this.sendMessage(audioData);
      }
    }, 40);
  }


  private sendMessage(data: AudioData) {
    if (this.ws == null) {
      return;
    }
    let params = new AsrParams();
    switch (data.status) {
      case AudioStatus.START:
        params.common.app_id = this.appId;
        break;
      case AudioStatus.CONTINUE:
        break;
      case AudioStatus.END:
        break;
      default:
        break;
    }
    let accent = this.params.get('accent') ?? "mandarin";
    let domain = this.params.get('domain') ?? "iat";
    let language = this.params.get('language') ?? "zh_cn";
    let dwa = this.params.get('dwa') ?? "wpgs";
    let vad_eos = this.params.get('vad_eos') ?? 2000;
    let business = new AsrBusinessParams();
    business.accent = accent.toString();
    business.domain = domain.toString();
    business.language = language.toString();
    business.dwa = dwa.toString();
    business.vad_eos = parseInt(vad_eos.toString());
    business.pd = (this.params.get('pd') ?? "").toString();
    business.ptt = parseInt((this.params.get('ptt') ?? 1).toString());
    business.rlang = (this.params.get('rlang') ?? "zh-cn").toString();
    business.vinfo = parseInt((this.params.get('vinfo') ?? 1).toString());
    business.nunum = parseInt((this.params.get('nunum') ?? 1).toString());
    business.nbest = parseInt((this.params.get('nbest') ?? 3).toString());
    business.wbest = parseInt((this.params.get('wbest') ?? 5).toString());
    params.business = business;

    params.data.status = data.status;
    let base64 = new util.Base64Helper();
    params.data.audio = base64.encodeToStringSync(new Uint8Array(data.audio))
    let message = JSON.stringify(params)
    //Logger.debug("听写message message==>" + message);
    this.ws?.send(message, (err: BusinessError, value: boolean) => {
      if (!err) {
        //console.log("听写WSS： 发送消息成功");
      } else {
        //console.log("听写WSS： 发送消息失败. Err:" + JSON.stringify(err));
      }
    });
  }

  /**
   * 参数解析
   * @param result
   */
  private parseAsrResult(result: string) {
    //如果是取消会话的情况则不在解析参数
    if (this.audioStatus == AudioStatus.CANCEL) {
      return;
    }
    let tmpStr: Record<string, Object> = JSON.parse(result)
    if (tmpStr != undefined) {
      try {
        let tempResult = tmpStr as AsrResult
        if (tempResult.code == 0) {
          let text = tempResult?.data?.result ?? undefined;
          if (text != undefined) {
            this.speechCallback?.onResult(tempResult.sid ?? "", text);
          }
          if (tempResult.data?.status == 2) {
            //结束了
            this.reset();
          }
        } else {
          this.reset();
          this.speechCallback?.onError(new SpeechException(tempResult.code ?? SpeechError.ASR_RESULT_ERROR_CODE,
            tempResult.message ?? '数据解析失败'));
        }
      } catch (e) {
        Logger.error("json解析报错" + JSON.stringify(e));
        this.reset();
        this.speechCallback?.onError(new SpeechException(SpeechError.ASR_RESULT_ERROR_CODE, "数据解析失败"));
      }
    } else {
      this.reset();
      this.speechCallback?.onError(new SpeechException(SpeechError.ASR_RESULT_ERROR_CODE, "数据解析失败"));
    }
  }
}


// let SpeechRecognizerHelper = new SpeechRecognizer()
//
// export default SpeechRecognizerHelper as SpeechRecognizer
