import { ComponentContent } from '@kit.ArkUI'
import EntryAbility from '../entryability/EntryAbility'
import { VolcAsrHelper } from '../asr/VolcAsrHelper'
import { SoundComponent } from './SoundComponent'

export class ActionBuilderParam {
  onTextChange?: (text: string) => void
  cancelClick?: () => void
}

export function openASRToast(onTextChange: (text: string) => void) {
  const uiContext = EntryAbility.ability.windowStage?.getMainWindowSync().getUIContext()!
  const promptAction = uiContext.getPromptAction()
  const actionParam = new ActionBuilderParam()
  actionParam.onTextChange = (text: string) => {
    onTextChange(text)
  }
  actionParam.cancelClick = () => {
    VolcAsrHelper.getInstance().cancel()
    promptAction.closeCustomDialog(contentNode)
  }

  const contentNode = new ComponentContent(uiContext, wrapBuilder(ASRListenerBuilder), actionParam)

  promptAction.openCustomDialog(contentNode, {
    autoCancel: false,
    alignment: DialogAlignment.Center,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      actionParam.cancelClick && actionParam.cancelClick()
    }
  })
}

@Builder
export function ASRListenerBuilder(param: ActionBuilderParam) {
  Column() {
    ASRListener({
      actionParam: param
    })
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
  .backgroundColor('rgba(15, 23, 42, 0.30)')
}

@Component
struct ASRListener {
  @Prop actionParam: ActionBuilderParam
  @State volumeLevel: number = 0
  private asrHelper: VolcAsrHelper | null = null
  private autoStopTimer?: number = undefined

  aboutToAppear(): void {
    this.asrHelper = VolcAsrHelper.getInstance()
    this.asrHelper.initialize(new Object({
      appKey: '7452939681',
      accessKey: '-oIAiPanKFvyN9_1oo228glyCRfeJZEC',
      resourceId: 'volc.seedasr.sauc.duration',
      url: 'wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async'
    }))
    this.startRecording()
  }

  private startRecording() {
    if (!this.asrHelper) {
      return
    }

    this.volumeLevel = 0
    this.asrHelper.setParams(800)

    if (this.autoStopTimer) {
      clearTimeout(this.autoStopTimer)
    }
    this.autoStopTimer = setTimeout(() => {
      this.stopRecording()
    }, 10000)

    this.asrHelper.startListening({
      onBegin: () => {
      },
      onError: (_code: number, _message: string) => {
        this.volumeLevel = 0
        this.closeDialog()
      },
      onVolumeChanged: (volume: number) => {
        this.volumeLevel = volume
        console.log('sssssss' + volume)
      },
      onListeningResult: (text: string, _last: boolean) => {
        this.actionParam.onTextChange?.(text)
      },
      onComplete: () => {
        this.volumeLevel = 0
        this.closeDialog()
      }
    })
  }

  private stopRecording() {
    this.asrHelper?.stopListening()
  }

  private closeDialog() {
    if (this.autoStopTimer) {
      clearTimeout(this.autoStopTimer)
      this.autoStopTimer = undefined
    }
    this.actionParam.cancelClick?.()
  }

  build() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(22)
        .height(22)
        .margin({ right: 5 })
        .position({
          right: 0,
          top: 0
        })
        .onClick(() => {
          this.closeDialog()
        })

      Row() {
        Image($r('app.media.startIcon'))
          .width(22)
          .height(22)
          .margin({ right: 5 })

        Text('语音录入')
          .fontSize(17)
          .fontColor('#111')
          .fontWeight(500)
      }.margin({
        top: 10
      })

      Text('请开始说话')
        .fontSize(16)
        .fontColor('#888')
        .margin({ top: 10 })

      SoundComponent({
        volumeNumber: this.volumeLevel,
        maxVolume: 100,
        maxHeight: 50,
        maxWidth: 150,
        lineWidth: 4,
        noise: 30,
      })
        .margin({
          top: 20,
          bottom: 20
        })
    }
    .width(300)
    .padding({
      left: 8,
      right: 8,
      top: 12,
      bottom: 12
    })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}