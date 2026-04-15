import { SpeechAsrCallback } from './SpeechAsrCallback'
import { VolcAsrRequestOptions, VolcRecognizerListener, VolcResponsePayload, VolcSpeechRecognizer, VolcSpeechUtility } from 'asrkit'
import { SpeechException } from 'asrkit'

export class VolcAsrHelper implements VolcRecognizerListener {
  private constructor() {
  }

  private static instance: VolcAsrHelper

  public static getInstance(): VolcAsrHelper {
    if (!VolcAsrHelper.instance) {
      VolcAsrHelper.instance = new VolcAsrHelper()
    }
    return VolcAsrHelper.instance
  }

  volcAsr?: VolcSpeechRecognizer = undefined
  listener?: SpeechAsrCallback = undefined
  options: VolcAsrRequestOptions = new VolcAsrRequestOptions()

  initialize(param: object) {

    let appId: string = param["appKey"]
    let accessToken: string = param["accessKey"]
    let resourceId: string = param["resourceId"]
    let connectId: string = param["connectId"]
    let hostUrl: string = param["url"]
    // const appId = '7452939681'
    // const accessToken = '-oIAiPanKFvyN9_1oo228glyCRfeJZEC'
    // const resourceId = 'volc.seedasr.sauc.duration'
    // const hostUrl = 'wss://openspeech.bytedance.com/api/v3/sauc/bigmodel'
    VolcSpeechUtility.createUtility(
      `appId=${appId},accessToken=${accessToken},resourceId=${resourceId},hostUrl=${hostUrl},connectId=${connectId}`
    )
  }

  setParams(eosTime?: number, bosTime?: number) {
    this.options = new VolcAsrRequestOptions()
    this.options.endWindowSize = eosTime || 1000
  }

  startListening(listener: SpeechAsrCallback) {
    this.listener = listener
    this.volcAsr = new VolcSpeechRecognizer()
    void this.volcAsr.startListening(this.options, this)
  }

  stopListening() {
    this.volcAsr?.stopListening()
  }

  cancel() {
    this.volcAsr?.cancel()
    this.volcAsr = undefined
  }

  onBeginOfSpeech() {
    this.listener?.onBegin()
  }

  onEndOfSpeech() {
    this.listener?.onComplete()
  }

  onVolumeChange(volume: number) {
    this.listener?.onVolumeChanged(Math.floor(volume))
  }

  onResult(payload: VolcResponsePayload, isLast: boolean) {
    this.listener?.onListeningResult(payload.result?.text ?? '', isLast)
  }

  onError(error: SpeechException) {
    this.listener?.onError(error.code, error.message)
  }
}
