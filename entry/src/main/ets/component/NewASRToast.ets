import {
  NEW_ASR_AREA_STORAGE_KEY,
  NEW_ASR_COUNTDOWN_STORAGE_KEY,
  NEW_ASR_EDITING_STORAGE_KEY,
  NEW_ASR_EDIT_TEXT_STORAGE_KEY,
  NEW_ASR_LOCKED_STORAGE_KEY,
  NEW_ASR_TEXT_STORAGE_KEY,
  NEW_ASR_VOLUME_STORAGE_KEY,
  NewASRPressArea,
  NewASRToastManager
} from './NewASRToastManager'
import { SoundComponent } from './SoundComponent'

export interface NewASRToastParam {
  path?: string
  onVoiceSend?: (audioPath: string, duration: number) => void
  onTextSend?: (text: string) => void
  onCancel?: () => void
}

@Builder
export function NewASRToastBuilder(param: NewASRToastParam) {
  Column() {
    NewASRToast({
      actionParam: param
    })
  }
  .width('100%')
  .height('100%')
  .justifyContent(FlexAlign.End)
  .backgroundColor('rgba(15, 23, 42, 0.32)')
  .backdropBlur(18)
}

@Component
struct NewASRToast {
  @Prop actionParam: NewASRToastParam
  @StorageLink(NEW_ASR_AREA_STORAGE_KEY) currentArea: NewASRPressArea = NewASRPressArea.VOICE
  @StorageLink(NEW_ASR_LOCKED_STORAGE_KEY) isLocked: boolean = false
  @StorageLink(NEW_ASR_TEXT_STORAGE_KEY) @Watch('onTextChange') recognizedText: string = ''
  @StorageLink(NEW_ASR_VOLUME_STORAGE_KEY) volumeLevel: number = 0
  @StorageLink(NEW_ASR_COUNTDOWN_STORAGE_KEY) countdownSeconds: number = 0
  @StorageLink(NEW_ASR_EDITING_STORAGE_KEY) isEditing: boolean = false
  @StorageLink(NEW_ASR_EDIT_TEXT_STORAGE_KEY) editText: string = ''
  private toastManager: NewASRToastManager = NewASRToastManager.getInstance()
  private textScroller: Scroller = new Scroller()
  private needAtEnd: boolean = false
  @State stableDisplayText: string = ''
  @State tailChar0: string = ''
  @State tailChar1: string = ''
  @State tailChar2: string = ''
  @State tailOpacity0: number = 1
  @State tailOpacity1: number = 1
  @State tailOpacity2: number = 1
  private previousTextLength: number = 0
  private tailFadeTimer?: number = undefined

  aboutToAppear(): void {
    this.updateDisplayText(false)
  }

  aboutToDisappear(): void {
    this.clearTailFadeTimer()
  }

  onTextChange(): void {
    this.updateDisplayText(true)
    // 只有用户仍停留在底部时才自动跟随，用户手动上翻后不抢滚动位置。
    if (this.needAtEnd && !this.textScroller.isAtEnd()) {
      return
    }
    setTimeout(() => {
      this.textScroller.scrollEdge(Edge.Bottom)
    }, 0)
  }

  private getTextContent(): string {
    return this.recognizedText.length > 0 ? this.recognizedText : '请开始说话'
  }

  private updateDisplayText(shouldAnimate: boolean): void {
    const text = this.getTextContent()
    const stableText = text.length <= 3 ? '' : text.slice(0, text.length - 3)
    const tailText = text.length <= 3 ? text : text.slice(text.length - 3)
    const currentLength = this.recognizedText.length

    this.stableDisplayText = stableText
    this.tailChar0 = tailText[0] ?? ''
    this.tailChar1 = tailText[1] ?? ''
    this.tailChar2 = tailText[2] ?? ''

    if (!shouldAnimate || currentLength <= 0 || currentLength <= this.previousTextLength) {
      this.previousTextLength = currentLength
      this.setTailOpacity(1, 1, 1)
      return
    }

    this.previousTextLength = currentLength
    this.playTailFadeAnimation()
  }

  private playTailFadeAnimation(): void {
    this.clearTailFadeTimer()
    const startOpacity0 = 0.7
    const startOpacity1 = 0.4
    const startOpacity2 = 0.15
    const totalSteps = 10
    let currentStep = 0
    this.setTailOpacity(startOpacity0, startOpacity1, startOpacity2)

    this.tailFadeTimer = setInterval(() => {
      currentStep += 1
      const progress = currentStep / totalSteps
      this.setTailOpacity(
        startOpacity0 + (1 - startOpacity0) * progress,
        startOpacity1 + (1 - startOpacity1) * progress,
        startOpacity2 + (1 - startOpacity2) * progress
      )
      if (currentStep >= totalSteps) {
        this.clearTailFadeTimer()
        this.setTailOpacity(1, 1, 1)
      }
    }, 100)
  }

  private setTailOpacity(opacity0: number, opacity1: number, opacity2: number): void {
    this.tailOpacity0 = opacity0
    this.tailOpacity1 = opacity1
    this.tailOpacity2 = opacity2
  }

  private clearTailFadeTimer(): void {
    if (this.tailFadeTimer !== undefined) {
      clearInterval(this.tailFadeTimer)
      this.tailFadeTimer = undefined
    }
  }

  private getTailColor(opacity: number): string {
    return `rgba(59, 59, 69, ${opacity})`
  }

  build() {
    Column() {
      if (this.isEditing) {
        Blank()
          .layoutWeight(1)
        Column() {

          Row() {
            Text('×')
              .fontSize(24)
              .fontColor('#B5B8C1')
              .onClick(() => {
                this.toastManager.cancelEditing()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.End)

          TextArea({ text: this.editText, placeholder: '' })
            .id('ASREditText')
            .width('100%')
            .constraintSize({ maxHeight: 100, minHeight: 20 })
            .backgroundColor('#FFFFFF')
            .lineHeight(18)
            .fontSize(13)
            .fontColor('#22252E')
            .placeholderColor('#B5B8C1')
            .borderRadius(12)
            .padding({ left: 4, right: 4, top: 4, bottom: 4 })
            .onChange((value: string) => {
              this.editText = value
              this.toastManager.updateEditText(value)
            })
            .onAppear(() => {
              this.getUIContext().getFocusController().requestFocus("ASREditText");
            })

          Row() {
            Row() {
              Text('取消')
                .fontSize(14)
                .fontColor('#9EA3AE')
            }.width('50%')
            .height(30)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.toastManager.cancelEditing()
            })

            Row() {
              Row() {
                Text('发送')
                  .fontSize(14)
                  .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                  .fontWeight(500)
              }.linearGradient({
                angle: 90,
                colors: [['#602FC8', 0], ['#EE2233', 1]]
              })
              .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
            }.width('50%')
            .height(30)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.toastManager.sendEditedText(this.editText)
            })
          }
          .width('100%')
          .margin({ top: 18 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 14, bottom: 8 })
        .backgroundColor('#FFFFFF')
        .borderRadius({ topLeft: 12, topRight: 12 })
      } else {
      Blank()
        .layoutWeight(1)

      if (this.countdownSeconds > 0 && this.countdownSeconds <= 10) {
        Text(`${this.countdownSeconds}s 后停止录音`)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .margin({ bottom: 12 })
      }

      Scroll(this.textScroller) {
        Text() {
          Span(this.stableDisplayText)
            .fontSize(14)
            .fontColor('#3B3B45')

          Span(this.tailChar0)
            .fontSize(14)
            .fontColor(this.getTailColor(this.tailOpacity0))

          Span(this.tailChar1)
            .fontSize(14)
            .fontColor(this.getTailColor(this.tailOpacity1))

          Span(this.tailChar2)
            .fontSize(14)
            .fontColor(this.getTailColor(this.tailOpacity2))
        }
          .width('100%')
          .fontSize(14)
          .lineHeight(22)
          .fontColor('#3B3B45')
      }
      .width('86%')
      .constraintSize({ minHeight: 40, maxHeight: 134 })
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 12
      })
      .backgroundColor('#FFFFFF')
      .scrollBar(BarState.Off)
      .borderRadius(11)
      .margin({ bottom: 22 })
      .onWillScroll((xOffset: number, yOffset: number, scrollState: ScrollState, scrollSource: ScrollSource) => {
        if (scrollSource == ScrollSource.DRAG || scrollSource == ScrollSource.SCROLL_BAR) {
          this.needAtEnd = true
        }
      })

      Row() {
        Column() {
          Column() {
            Image($r('app.media.startIcon'))
              .width(16)
              .height(16)
              .margin({ bottom: 5 })

            Text(this.isLocked ? '取消' : '左滑取消')
              .fontSize(13)
              .fontColor('#4F4C5D')
          }
          .width('90%')
          .height(65)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .linearGradient({
            angle: 171,
            colors: this.currentArea === NewASRPressArea.CANCEL ?
              [['rgba(255, 255, 255, 0.95)', 0.14], ['rgba(252, 244, 255, 1)', 0.58]] :
              [['rgba(249, 237, 253, 0.67)', 0.14], ['rgba(252, 244, 255, 0.95)', 0.58]]
          })
          .borderRadius(24)
          .border({
            width: 0.5,
            color: 'rgba(252, 244, 255, 0.72)'
          })
          .shadow({
            radius: this.currentArea === NewASRPressArea.CANCEL ? 10 : 5,
            color: 'rgba(176, 104, 157, 0.10)',
            offsetX: 0,
            offsetY: 2
          })
          .scale({
            x: this.currentArea === NewASRPressArea.CANCEL ? 1.04 : 1,
            y: this.currentArea === NewASRPressArea.CANCEL ? 1.04 : 1
          })
          .rotate({ angle: -12 })
        }
        .width('35%')
        .constraintSize({ maxWidth: 150 })
        .height('100%')
        // 外层是命中矩形，内层按钮贴近底部，保证最低点贴近大按钮弧形最高处。
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 5 })
        .onClick(() => {
          if (this.isLocked) {
            this.toastManager.handleLockedAction(NewASRPressArea.CANCEL)
          }
        })

        Column() {
          Column() {
            Image($r('app.media.startIcon'))
              .width(16)
              .height(16)
              .margin({ bottom: 5 })

            Text(this.isLocked ? '发送' : '上滑锁定')
              .fontSize(13)
              .fontColor('#4F4C5D')
          }
          .width('90%')
          .height(65)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .linearGradient({
            angle: 171,
            colors: this.currentArea === NewASRPressArea.LOCK ?
              [['rgba(255, 255, 255, 0.95)', 0.14], ['rgba(252, 244, 255, 1)', 0.58]] :
              [['rgba(249, 237, 253, 0.67)', 0.14], ['rgba(252, 244, 255, 0.95)', 0.58]]
          })
          .borderRadius(24)
          .border({
            width: 0.5,
            color: 'rgba(252, 244, 255, 0.72)'
          })
          .shadow({
            radius: this.currentArea === NewASRPressArea.LOCK ? 10 : 5,
            color: 'rgba(176, 104, 157, 0.10)',
            offsetX: 0,
            offsetY: 2
          })
          .scale({
            x: this.currentArea === NewASRPressArea.LOCK ? 1.04 : 1,
            y: this.currentArea === NewASRPressArea.LOCK ? 1.04 : 1
          })
        }
        .width('30%')
        .constraintSize({ maxWidth: 130 })
        .height('100%')
        // 中间按钮底边对齐左右倾斜按钮底边的高点，而不是跟左右最低点对齐。
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 17 })
        .onClick(() => {
          if (this.isLocked) {
            this.toastManager.handleLockedAction(NewASRPressArea.LOCK)
          }
        })

        Column() {
          Column() {
            Image($r('app.media.startIcon'))
              .width(16)
              .height(16)
              .margin({ bottom: 5 })

            Text(this.isLocked ? '转文字' : '右滑转文字')
              .fontSize(13)
              .fontColor('#4F4C5D')
          }
          .width('90%')
          .height(65)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .linearGradient({
            angle: 171,
            colors: this.currentArea === NewASRPressArea.TEXT ?
              [['rgba(255, 255, 255, 0.95)', 0.14], ['rgba(252, 244, 255, 1)', 0.58]] :
              [['rgba(249, 237, 253, 0.67)', 0.14], ['rgba(252, 244, 255, 0.95)', 0.58]]
          })
          .borderRadius(24)
          .border({
            width: 0.5,
            color: 'rgba(252, 244, 255, 0.72)'
          })
          .shadow({
            radius: this.currentArea === NewASRPressArea.TEXT ? 10 : 5,
            color: 'rgba(176, 104, 157, 0.10)',
            offsetX: 0,
            offsetY: 2
          })
          .scale({
            x: this.currentArea === NewASRPressArea.TEXT ? 1.04 : 1,
            y: this.currentArea === NewASRPressArea.TEXT ? 1.04 : 1
          })
          .rotate({ angle: 12 })
        }
        .width('35%')
        .constraintSize({ maxWidth: 150 })
        .height('100%')
        // 外层是命中矩形，内层按钮贴近底部，保证最低点贴近大按钮弧形最高处。
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 5 })
        .onClick(() => {
          if (this.isLocked) {
            this.toastManager.handleLockedAction(NewASRPressArea.TEXT)
          }
        })
      }
      .width('100%')
      .height(100)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)

      Stack({ alignContent: Alignment.Top }) {
        Circle()
          .width(1200)
          .height(1200)
          .fill('#FFFFFF')

        Image($r('app.media.bg_asr_toast'))
          .width(470)
          .height(250)

        Column() {
          Text(this.isLocked ? ' ' : '松手 发送')
            .fontSize(13)
            .fontColor(this.currentArea === NewASRPressArea.VOICE ? '#5D4A9B' : '#6F6684')
            .fontWeight(FontWeight.Medium)
            .margin({ top: 20, bottom: 20 })

          Row() {
            Row({ space: 5 }) {
              SoundComponent({
                volumeNumber: this.volumeLevel,
                maxVolume: 100,
                maxHeight: 30,
                maxWidth: 250,
                lineWidth: 3,
                lineSpace: 5,
                noise: 20,
                minHeight: 10,
                lineColor: '#C04BF5'
              })
            }.blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
          }
          .linearGradient({
            angle: 270,
            colors: [['#B347F8', 0.05], ['#F14575', 1]]
          })
          .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(150)
      .clip(true)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(255, 255, 255, 0.08)')
  }
}
