/**
 * @Desc: ASR语音识别入参
 * @author: leon
 * @datetime: 2024/11/1
 */
export class AsrParams {
  business: AsrBusinessParams = new AsrBusinessParams();
  common: AsrCommonParams = new AsrCommonParams();
  data: AsrDataParams = new AsrDataParams();
}

export class AsrBusinessParams {
  language: string = "zh_cn";
  domain: string = "iat";
  accent: string = "mandarin";
  vad_eos: number = 2000;
  dwa: string = "wpgs";
  pd: string = "";
  ptt: number = 1;
  rlang: string = "zh-cn";
  vinfo: number = 1;
  nunum: number = 1;
  nbest: number = 3;
  wbest: number = 5;
}

export class AsrCommonParams {
  app_id: string = "";
}

export class AsrDataParams {
  audio: string | undefined;
  encoding: string = "raw";
  format: string = "audio/L16;rate=16000";
  status: number | undefined;
}
