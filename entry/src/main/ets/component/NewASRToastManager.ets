import { ComponentContent } from '@kit.ArkUI'
import EntryAbility from '../entryability/EntryAbility'
import { NewASRToastBuilder, NewASRToastParam } from './NewASRToast'
import { fileIo as fs } from '@kit.CoreFileKit'
import { PcmToWavUtil } from '../asr/PcmToWavUtil'
import { VolcAsrHelper } from '../asr/VolcAsrHelper'
import { SpeechAsrCallback } from '../asr/SpeechAsrCallback'
import { abilityAccessCtrl } from '@kit.AbilityKit'

export const NEW_ASR_AREA_STORAGE_KEY = 'newASRArea'
export const NEW_ASR_LOCKED_STORAGE_KEY = 'newASRLocked'
export const NEW_ASR_TEXT_STORAGE_KEY = 'newASRText'
export const NEW_ASR_VOLUME_STORAGE_KEY = 'newASRVolume'

export class NewASRTouchPoint {
  x: number = 0
  y: number = 0

  constructor(x: number, y: number) {
    this.x = x
    this.y = y
  }
}

export enum NewASRPressArea {
  VOICE = 'voice',
  CANCEL = 'cancel',
  LOCK = 'lock',
  TEXT = 'text'
}

const samplingRate = 16000
const channels = 1
const maxRecordDurationMs = 60000

export class NewASRToastManager implements SpeechAsrCallback {
  private static instance: NewASRToastManager
  private contentNode: ComponentContent<NewASRToastParam> | null = null
  private longPressTimer?: number = undefined
  private autoStopTimer?: number = undefined
  private actionParam: NewASRToastParam | null = null
  private asrHelper: VolcAsrHelper | null = null
  private isPressing: boolean = false
  private isLocked: boolean = false
  private isFinishing: boolean = false
  private recognizedText: string = ''
  private currentPoint: NewASRTouchPoint | null = null
  private currentArea: NewASRPressArea = NewASRPressArea.VOICE
  private readonly pageWidth: number
  private readonly pageHeight: number
  private readonly voiceAreaHeight: number = 150

  private constructor() {
    const rect = EntryAbility.ability.windowStage?.getMainWindowSync().getWindowProperties().windowRect
    const uiContext = EntryAbility.ability.windowStage?.getMainWindowSync().getUIContext()
    const width = rect?.width ?? 0
    const height = rect?.height ?? 0
    this.pageWidth = width > 0 ? (uiContext?.px2vp(width) ?? 350) : 350
    this.pageHeight = height > 0 ? (uiContext?.px2vp(height) ?? 800) : 800
  }

  public static getInstance(): NewASRToastManager {
    if (!NewASRToastManager.instance) {
      NewASRToastManager.instance = new NewASRToastManager()
    }
    return NewASRToastManager.instance
  }

  public handleTouchEvent(event: TouchEvent, param: NewASRToastParam): void {
    const point = this.getTouchPoint(event)
    if (point !== null) {
      this.currentPoint = point
    }
    this.currentArea = this.resolveArea(this.currentPoint)
    this.syncAreaToView()

    if (event.type === TouchType.Down) {
      if (this.isLocked) {
        return
      }

      this.isPressing = true
      this.actionParam = param
      this.clearLongPressTimer()

      // 长按超过阈值才打开弹窗，短按抬起时只清理定时器。
      this.longPressTimer = setTimeout(() => {
        this.longPressTimer = undefined
        if (this.isPressing) {
          this.openToast()
        }
      }, 100)
      return
    }

    if (event.type === TouchType.Move) {
      return
    }

    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.handleRelease()
      this.isPressing = false
      this.clearLongPressTimer()
      this.currentPoint = null
      this.currentArea = NewASRPressArea.VOICE
      this.syncAreaToView()
    }
  }

  public handleLockedAction(area: NewASRPressArea): void {
    if (!this.isLocked) {
      return
    }

    // 锁定态下中间按钮文案是“发送”，仍复用 LOCK 这个区域枚举。
    if (area === NewASRPressArea.LOCK) {
      void this.finishByArea(NewASRPressArea.VOICE)
      return
    }

    void this.finishByArea(area)
  }

  private openToast(): void {
    if (this.contentNode !== null || this.actionParam === null) {
      return
    }

    const uiContext = EntryAbility.ability.windowStage?.getMainWindowSync().getUIContext()
    if (!uiContext) {
      return
    }

    const promptAction = uiContext.getPromptAction()
    this.contentNode = new ComponentContent(uiContext, wrapBuilder(NewASRToastBuilder), this.actionParam)

    promptAction.openCustomDialog(this.contentNode, {
      autoCancel: false,
      alignment: DialogAlignment.Bottom,
      transition: TransitionEffect.IDENTITY,
      onWillDismiss: (_dismissDialogAction: DismissDialogAction) => {
        this.handleLockedAction(NewASRPressArea.CANCEL)
      }
    })
    this.startAsr()
  }

  private closeToast(): void {
    if (this.contentNode === null) {
      return
    }

    const uiContext = EntryAbility.ability.windowStage?.getMainWindowSync().getUIContext()
    if (!uiContext) {
      this.contentNode = null
      return
    }

    const promptAction = uiContext.getPromptAction()
    const contentNode = this.contentNode
    this.contentNode = null
    promptAction.closeCustomDialog(contentNode)
  }

  private handleRelease(): void {
    if (this.isLocked) {
      return
    }

    // 未锁定时松手在锁定区域，只切换状态，不关闭弹窗。
    if (this.currentArea === NewASRPressArea.LOCK) {
      this.isLocked = true
      this.syncLockedToView()
      return
    }

    void this.finishByArea(this.currentArea)
  }

  private async finishByArea(area: NewASRPressArea): Promise<void> {
    if (this.isFinishing) {
      return
    }
    this.isFinishing = true

    if (area === NewASRPressArea.CANCEL) {
      this.cancelAsr()
      this.actionParam?.onCancel?.()
      this.resetState()
      return
    }

    if (area === NewASRPressArea.TEXT) {
      this.stopAsr()
      this.actionParam?.onTextSend?.(this.recognizedText)
      this.resetState()
      return
    }

    if (area === NewASRPressArea.VOICE) {
      try {
        this.stopAsr()
        const result = await this.convertDefaultPcmToWav()
        this.actionParam?.onVoiceSend?.(result.path, result.duration)
      } catch (error) {
        console.error('convert default pcm to wav failed')
        this.actionParam?.onVoiceSend?.(this.getAudioSavePath(), 0)
      } finally {
        this.resetState()
      }
      return
    }

    this.resetState()
  }

  private resetState(): void {
    this.clearAutoStopTimer()
    this.asrHelper = null
    this.actionParam = null
    this.isFinishing = false
    this.isLocked = false
    this.syncLockedToView()
    this.closeToast()
  }

  private clearLongPressTimer(): void {
    if (this.longPressTimer !== undefined) {
      clearTimeout(this.longPressTimer)
      this.longPressTimer = undefined
    }
  }

  private getTouchPoint(event: TouchEvent): NewASRTouchPoint | null {
    if (!event.touches || event.touches.length === 0) {
      return null
    }

    const touch = event.touches[0]
    return new NewASRTouchPoint(touch.windowX, touch.windowY)
  }

  private resolveArea(point: NewASRTouchPoint | null): NewASRPressArea {
    if (point === null) {
      return NewASRPressArea.VOICE
    }

    // 底部 150 高度整块作为“松手发送语音”区域，对齐 UI 中的大按钮区域。
    if (point.y >= this.pageHeight - this.voiceAreaHeight) {
      return NewASRPressArea.VOICE
    }

    // 上方区域不保留空白态，按 35% / 30% / 35% 分配给三个小按钮。
    const cancelRight = this.pageWidth * 0.35
    const lockRight = this.pageWidth * 0.65

    if (point.x < cancelRight) {
      return NewASRPressArea.CANCEL
    }

    if (point.x < lockRight) {
      return NewASRPressArea.LOCK
    }

    return NewASRPressArea.TEXT
  }

  private syncAreaToView(): void {
    AppStorage.setOrCreate(NEW_ASR_AREA_STORAGE_KEY, this.currentArea)
  }

  private syncLockedToView(): void {
    AppStorage.setOrCreate(NEW_ASR_LOCKED_STORAGE_KEY, this.isLocked)
  }

  private syncTextToView(): void {
    AppStorage.setOrCreate(NEW_ASR_TEXT_STORAGE_KEY, this.recognizedText)
  }

  private syncVolumeToView(volume: number): void {
    AppStorage.setOrCreate(NEW_ASR_VOLUME_STORAGE_KEY, volume)
  }

  private startAsr(): void {
    this.recognizedText = ''
    this.syncTextToView()
    this.syncVolumeToView(0)
    this.clearAutoStopTimer()

    const atManager = abilityAccessCtrl.createAtManager()
    atManager.requestPermissionsFromUser(EntryAbility.ability.context, ['ohos.permission.MICROPHONE'])
      .then(() => {
        this.startAsrAfterPermission()
      })
      .catch(() => {
        console.error('request microphone permission failed')
        void this.finishByArea(NewASRPressArea.CANCEL)
      })
  }

  private startAsrAfterPermission(): void {
    if (this.contentNode === null || this.actionParam === null) {
      return
    }

    this.asrHelper = VolcAsrHelper.getInstance()
    this.asrHelper.initialize(new Object({
      appKey: '7452939681',
      accessKey: '-oIAiPanKFvyN9_1oo228glyCRfeJZEC',
      resourceId: 'volc.seedasr.sauc.duration',
      url: 'wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async'
    }))
    this.asrHelper.setParams(maxRecordDurationMs)
    // 这个长按弹窗由手势/60s 定时器控制结束，避免火山 definite 中间结果提前停止录音。
    this.asrHelper.setAutoStopOnDefinite(false)
    this.asrHelper.startListening(this)

    this.autoStopTimer = setTimeout(() => {
      void this.finishByArea(NewASRPressArea.VOICE)
    }, maxRecordDurationMs)
  }

  private stopAsr(): void {
    this.clearAutoStopTimer()
    if (!this.asrHelper) {
      return
    }
    this.asrHelper.stopListening()
  }

  private cancelAsr(): void {
    this.clearAutoStopTimer()
    this.syncVolumeToView(0)
    this.asrHelper?.cancel()
    this.asrHelper = null
  }

  private clearAutoStopTimer(): void {
    if (this.autoStopTimer !== undefined) {
      clearTimeout(this.autoStopTimer)
      this.autoStopTimer = undefined
    }
  }

  private getAudioSavePath(): string {
    return this.actionParam?.path || EntryAbility.ability.context.cacheDir + '/StarWars10s-2C-48000-4SW.wav'
  }

  private async convertDefaultPcmToWav(): Promise<NewASRAudioResult> {
    const pcmPath = EntryAbility.ability.context.cacheDir + '/StarWars10s-2C-48000-4SW.pcm'
    const wavPath = this.getAudioSavePath()
    const mode = fs.OpenMode.TRUNC | fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE
    // 录音模块固定写入默认 PCM，这里只在语音返回时转换成调用方需要的 WAV 路径。
    const inFile = fs.openSync(pcmPath, fs.OpenMode.READ_ONLY)
    const outFile = fs.openSync(wavPath, mode)
    const util = new PcmToWavUtil(samplingRate, channels)
    const duration = await util.pcmToWav(inFile, outFile)
    return new NewASRAudioResult(wavPath, duration)
  }

  onBegin(): void {
  }

  onError(code: number, message: string): void {
    console.error(`new asr error code=${code}, message=${message}`)
    this.syncVolumeToView(0)
    if (this.isFinishing) {
      return
    }
    void this.finishByArea(NewASRPressArea.CANCEL)
  }

  onVolumeChanged(volume: number): void {
    this.syncVolumeToView(volume)
  }

  onListeningResult(text: string, _last: boolean): void {
    this.recognizedText = text
    this.syncTextToView()
  }

  onComplete(): void {
    this.syncVolumeToView(0)
  }
}

class NewASRAudioResult {
  path: string
  duration: number

  constructor(path: string, duration: number) {
    this.path = path
    this.duration = duration
  }
}
