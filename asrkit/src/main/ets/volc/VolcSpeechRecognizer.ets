import { Queue } from '@kit.ArkTS'
import { BusinessError } from '@kit.BasicServicesKit'
import { webSocket } from '@kit.NetworkKit'
import { AudioData } from '../model/AudioData'
import { AudioStatus } from '../model/AudioStatus'
import { AudioRecorder } from '../media/AudioRecorder'
import { AudioRecorderStatusListener } from '../media/AudioRecorderStatusListener'
import { Logger } from '../utils/Logger'
import { SpeechError } from '../utils/exception/SpeechError'
import { SpeechException } from '../utils/exception/SpeechException'
import { AudioDrainResult, VolcAsrRequestOptions, VolcFullClientRequestPayload } from './VolcModels'
import { VolcRecognizerListener } from './VolcRecognizerListener'
import { VolcSpeechUtility } from './VolcSpeechUtility'
import { VolcWsProtocol } from './VolcWsProtocol'

export class VolcSpeechRecognizer implements AudioRecorderStatusListener {
  private ws?: webSocket.WebSocket
  private audioRecorder: AudioRecorder = new AudioRecorder()
  private speechCallback?: VolcRecognizerListener
  private queueInterval: number = 0
  private audioMessageQueue?: Queue<AudioData> | null = null
  private audioStatus: AudioStatus = AudioStatus.START
  private sequence: number = 1
  private options: VolcAsrRequestOptions = new VolcAsrRequestOptions()
  private hostUrl: string = 'wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async'
  private appId: string = ''
  private accessToken: string = ''
  private resourceId: string = 'volc.seedasr.sauc.duration'
  private connectId: string = ''

  async startListening(options: VolcAsrRequestOptions, listener: VolcRecognizerListener) {
    this.options = options
    this.speechCallback = listener
    this.audioStatus = AudioStatus.START
    this.audioMessageQueue = new Queue()
    this.sequence = 1

    try {
      this.initialize()
      await this.connectWebSocket()
    } catch (error) {
      this.speechCallback?.onError(error as SpeechException)
    }
  }

  stopListening() {
    this.audioRecorder.onStopRecord()
  }

  cancel() {
    this.audioStatus = AudioStatus.CANCEL
    this.reset(true)
  }

  onRecordStart() {
    this.audioStatus = AudioStatus.START
    this.speechCallback?.onBeginOfSpeech()
    void this.sendFullClientRequest()
    this.handleAudioQueue()
  }

  onRecordProgress(data: ArrayBuffer, volume: number) {
    this.audioStatus = AudioStatus.CONTINUE
    this.audioMessageQueue?.add(new AudioData(AudioStatus.CONTINUE, data))
    this.speechCallback?.onVolumeChange(volume)
  }

  onRecordStop() {
    this.audioStatus = AudioStatus.END
    this.audioMessageQueue?.add(new AudioData(AudioStatus.END, new ArrayBuffer(0)))
  }

  onRecordError(error: SpeechException) {
    this.audioStatus = AudioStatus.CANCEL
    this.speechCallback?.onError(error)
    this.reset(true)
  }

  private initialize() {
    const utility = VolcSpeechUtility.getUtility()
    if (!utility) {
      throw new SpeechException(SpeechError.SPEECHUTILITY_ERROR_CODE, '火山SDK配置类未初始化')
    }
    this.appId = utility.getParameter('appId')
    this.accessToken = utility.getParameter('accessToken')
    this.resourceId = utility.getParameter('resourceId') || this.resourceId
    this.hostUrl = utility.getParameter('hostUrl') || this.hostUrl
    this.connectId = utility.getParameter('connectId') || this.randomId()

    if (!this.appId || !this.accessToken) {
      throw new SpeechException(SpeechError.AUTH_ERROR_CODE, '火山鉴权参数缺失')
    }
  }

  private async connectWebSocket() {
    this.ws = webSocket.createWebSocket()
    this.registerSocketEvents()
    await this.ws.connect(this.hostUrl, {
      header: {
        'X-Api-App-Key': this.appId,
        'X-Api-Access-Key': this.accessToken,
        'X-Api-Resource-Id': this.resourceId,
        'X-Api-Connect-Id': this.connectId
      }
    })
  }

  private registerSocketEvents() {
    this.ws?.on('open', (_err: BusinessError, _value: Object) => {
      this.audioRecorder.setAudioRecorderChange(this)
      void this.audioRecorder.startRecording()
    })

    this.ws?.on('message', (_err: BusinessError, value: string | ArrayBuffer) => {
      if (value instanceof ArrayBuffer) {
        void this.handleBinaryMessage(value)
      }
    })

    this.ws?.on('error', (err: BusinessError) => {
      this.speechCallback?.onError(new SpeechException(err.code, err.message))
    })

    this.ws?.on('close', (_err: BusinessError, _value: webSocket.CloseResult) => {
      if (this.audioStatus !== AudioStatus.CANCEL) {
        this.speechCallback?.onEndOfSpeech()
      }
      this.reset(false)
    })
  }

  private async sendFullClientRequest() {
    const payload: VolcFullClientRequestPayload = {
      user: {
        uid: this.options.uid
      },
      audio: {
        format: this.options.audioFormat,
        codec: this.options.audioCodec,
        rate: this.options.sampleRate,
        bits: this.options.bits,
        channel: this.options.channel
      },
      request: {
        model_name: this.options.modelName,
        enable_itn: this.options.enableItn,
        enable_punc: this.options.enablePunc,
        enable_ddc: this.options.enableDdc,
        show_utterances: this.options.showUtterances,
        enable_nonstream: this.options.enableNonstream
      }
    }
    const packet = await VolcWsProtocol.buildFullRequestPacket(payload, this.sequence)
    await this.ws?.send(packet)
  }

  private handleAudioQueue() {
    clearInterval(this.queueInterval)
    this.queueInterval = setInterval(() => {
      void this.flushOneAudioPacket()
    }, this.options.segmentDurationMs)
  }

  private async flushOneAudioPacket() {
    const drained = this.drainAudioQueue()
    if (!drained) {
      if (this.audioStatus == AudioStatus.END || this.audioStatus == AudioStatus.CANCEL) {
        clearInterval(this.queueInterval)
      }
      return
    }

    if (this.audioStatus == AudioStatus.CANCEL) {
      clearInterval(this.queueInterval)
      return
    }

    this.sequence += 1
    const isLast = drained.isLast
    const sequence = isLast ? -this.sequence : this.sequence
    const packet = await VolcWsProtocol.buildAudioPacket(drained.audio, sequence, isLast)
    await this.ws?.send(packet)

    if (isLast) {
      clearInterval(this.queueInterval)
    }
  }

  private drainAudioQueue(): AudioDrainResult | undefined {
    if (!this.audioMessageQueue || this.audioMessageQueue.length <= 0) {
      return undefined
    }

    const chunks: Uint8Array[] = []
    let totalLength = 0
    let isLast = false

    while ((this.audioMessageQueue?.length ?? 0) > 0) {
      const item = this.audioMessageQueue?.pop()
      if (!item) {
        break
      }

      if (item.status == AudioStatus.END) {
        isLast = true
        break
      }

      const chunk = new Uint8Array(item.audio)
      if (chunk.byteLength > 0) {
        chunks.push(chunk)
        totalLength += chunk.byteLength
      }
    }

    const merged = new Uint8Array(totalLength)
    let offset = 0
    for (let chunk of chunks) {
      merged.set(chunk, offset)
      offset += chunk.byteLength
    }

    if (totalLength <= 0 && !isLast) {
      return undefined
    }

    const audioData: AudioDrainResult = new Object({
      audio: merged.buffer,
      isLast: isLast
    }) as AudioDrainResult

    return audioData
  }

  private async handleBinaryMessage(value: ArrayBuffer) {
    try {
      const frame = await VolcWsProtocol.parseResponsePacket(value)
      if (frame.code !== 0) {
        this.speechCallback?.onError(new SpeechException(frame.code, frame.payloadText || '火山服务返回错误'))
        this.reset(true)
        return
      }

      if (frame.payload) {
        this.speechCallback?.onResult(frame.payload, frame.isLastPackage)
      }

      if (frame.isLastPackage) {
        this.speechCallback?.onEndOfSpeech()
        this.reset(true)
      }
    } catch (error) {
      const speechError = error instanceof SpeechException
        ? error
        : new SpeechException(SpeechError.ASR_RESULT_ERROR_CODE, `火山结果解析失败: ${JSON.stringify(error)}`)
      this.speechCallback?.onError(speechError)
      this.reset(true)
    }
  }

  private reset(closeWs: boolean) {
    clearInterval(this.queueInterval)
    this.audioMessageQueue = null
    try {
      this.audioRecorder.onStopRecord()
    } catch (e) {
      Logger.debug('volc reset stop recorder failed')
    }
    if (closeWs && this.ws) {
      try {
        void this.ws.close({ code: 1000, reason: 'normal close' })
      } catch (e) {
        Logger.debug('volc reset close websocket failed')
      }
    }
    this.ws = undefined
  }

  private randomId(): string {
    return `${Date.now()}-${Math.floor(Math.random() * 1000000)}`
  }
}
