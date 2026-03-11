/**
 * @Desc: 语音听写辅助类
 * @author: leon
 * @datetime: 2024/3/21
 */
import { AsrText } from './AsrText';
import { SpeechAsrCallback } from './SpeechAsrCallback';
import { ArrayList, HashMap } from '@kit.ArkTS';
import { AsrDetail, RecognizerListener, SpeechException, SpeechRecognizer, SpeechUtility } from 'asrkit';
// import { LogUtils } from '../utils/LogUtils';
import Pair from './Pair';

export class AsrHelper implements RecognizerListener {
  private constructor() {
  }

  private static instance: AsrHelper;

  public static getInstance(): AsrHelper {
    if (!AsrHelper.instance) {
      AsrHelper.instance = new AsrHelper();
    }
    return AsrHelper.instance;
  }

  asr?: SpeechRecognizer = undefined;
  listener?: SpeechAsrCallback = undefined;
  private mResult: ArrayList<Pair<number, string>> = new ArrayList();
  params = new HashMap<string, string | number>();

  /**
   * 初始化操作
   */
  initialize() {
    const APP_ID = "5e9eb0ae";
    const API_KEY = "f39d43874c1cc9f15b363e74f689e305";
    const API_SECRET = "e82d6643c7445f3801126700783696a2";
    SpeechUtility.createUtility(
      `appId=${APP_ID},apiKey=${API_KEY},apiSecret=${API_SECRET}`
    );
  }

  setParams(eos: number, bos: number, ppt?: number) {
    this.params.set("vad_eos", eos);
    this.params.set("vad_bos", bos);
    if (ppt !== undefined) {
      this.params.set("ptt", ppt);
    } else {
      this.params.set("ptt", 0);
    }
  }

  /**
   * 开始语音听写
   */
  startListening(listener: SpeechAsrCallback) {
    this.listener = listener;
    this.mResult.clear();

    this.params.set("language", "zh_cn");
    this.params.set("domain", "iat");
    this.params.set("accent", "mandarin");

    //this.params.set("ptt", 0);
    this.asr = new SpeechRecognizer();
    this.asr?.startListening(this.params, this);
  }


  onBeginOfSpeech() {
    //LogUtils.error("语音听写 start ===>");
    this.listener?.onBegin();
  };

  onVolumeChange(volume: number) {
    // Logger.debug("音量大小===>" + volume);
    let v = volume;
    if (volume > 55) {
      v = 55;
    }
    this.listener?.onVolumeChanged(Math.floor(v));
  }

  onEndOfSpeech() {
    // LogUtils.error("语音听写 end ====>");
    this.listener?.onComplete();
  };

  onResult(sid: string, data: AsrDetail) {
    let asrText = this.getText(data);
    //LogUtils.info(`语音听写 result ====${JSON.stringify(asrText)}`);
    let text = this.printProgressiveText(asrText);
    this.listener?.onListeningResult(text, asrText.ls ?? false);
  }

  /**
   * 解析数据
   * @param data
   * @returns
   */
  private printProgressiveText(data: AsrText): string {
    let stringBuilder = "";
    if ("rpl" == data.pgs) {
      let begin = data.rg?.[0] ?? -1;
      let end = data.rg?.[1] ?? -1;
      for (let index = begin; index <= end; index++) {
        let tempPair: Pair<number, string> | undefined = undefined;
        for (let pair of this.mResult) {
          if (pair.first == index) {
            tempPair = pair
            break;
          }
        }
        if (tempPair != undefined) {
          this.mResult.remove(tempPair);
        }
      }
    }
    this.mResult.add(new Pair(data.sn ?? -1, data.text ?? ""));
    //LogUtils.info(`语音听写 printProgressiveText ====${JSON.stringify(this.mResult)}`);
    for (let pair of this.mResult) {
      stringBuilder += pair.second
    }
    return stringBuilder;
  }

  private getText(data: AsrDetail): AsrText {
    let text = new AsrText();
    let sb = "";
    let tempWs = data?.ws ?? [];
    for (let ws of tempWs) {
      sb += ws.cw?.[0]?.w ?? ""
    }
    text.sn = data.sn;
    text.text = sb;
    text.rg = data.rg;
    text.pgs = data.pgs;
    text.bg = data.bg;
    text.ed = data.ed;
    text.ls = data.ls;
    return text;
  }

  onError(error: SpeechException) {
    //LogUtils.error(`语音听写 error ====> code=${error.code}, message=${error.message}`);
    this.listener?.onError(error.code, error.message);
  }


  /**
   * 停止听写
   */
  stopListening() {
    this.asr?.stopListening();
  }

  /**
   * 取消听写
   */
  cancel() {
    this.asr?.cancel();
    this.asr = undefined;
  }
}
