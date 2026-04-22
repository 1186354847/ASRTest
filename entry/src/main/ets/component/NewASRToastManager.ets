import { ComponentContent } from '@kit.ArkUI'
import EntryAbility from '../entryability/EntryAbility'
import { NewASRToastBuilder, NewASRToastParam } from './NewASRToast'

export const NEW_ASR_AREA_STORAGE_KEY = 'newASRArea'
export const NEW_ASR_LOCKED_STORAGE_KEY = 'newASRLocked'

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

export class NewASRToastManager {
  private static instance: NewASRToastManager
  private contentNode: ComponentContent<NewASRToastParam> | null = null
  private longPressTimer?: number = undefined
  private actionParam: NewASRToastParam | null = null
  private isPressing: boolean = false
  private isLocked: boolean = false
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
      }, 300)
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
      this.finishByArea(NewASRPressArea.VOICE)
      return
    }

    this.finishByArea(area)
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
      onWillDismiss: (_dismissDialogAction: DismissDialogAction) => {
        this.contentNode = null
      }
    })
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

    this.finishByArea(this.currentArea)
  }

  private finishByArea(area: NewASRPressArea): void {
    if (area === NewASRPressArea.CANCEL) {
      this.actionParam?.onCancel?.()
      this.resetState()
      return
    }

    if (area === NewASRPressArea.TEXT) {
      // 真实 ASR 接入前，先返回文字占位，保持回调链路完整。
      this.actionParam?.onTextSend?.('[文字结果占位]')
      this.resetState()
      return
    }

    if (area === NewASRPressArea.VOICE) {
      // 真实录音文件接入前，先返回音频地址占位。
      this.actionParam?.onVoiceSend?.('[语音文件地址占位]')
      this.resetState()
      return
    }

    this.resetState()
  }

  private resetState(): void {
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
}
