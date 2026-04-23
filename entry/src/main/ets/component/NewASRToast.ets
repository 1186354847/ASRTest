import {
  NEW_ASR_AREA_STORAGE_KEY,
  NEW_ASR_LOCKED_STORAGE_KEY,
  NewASRPressArea,
  NewASRToastManager
} from './NewASRToastManager'

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
  @State demoText: string = '北京明天天气怎么样'
  private toastManager: NewASRToastManager = NewASRToastManager.getInstance()
  private demoTextTimer?: number = undefined
  private textScroller: Scroller = new Scroller()
  private needAtEnd: boolean = false

  aboutToAppear(): void {
    this.demoTextTimer = setInterval(() => {
      this.demoText += '，自动增加几个字'
      if (this.needAtEnd) {
        const shouldFollowBottom = this.textScroller.isAtEnd()
        if (shouldFollowBottom) {
          setTimeout(() => {
            this.textScroller.scrollEdge(Edge.Bottom)
          }, 0)
        }
        return
      }
      setTimeout(() => {
        this.textScroller.scrollEdge(Edge.Bottom)
      }, 0)

    }, 500)
  }

  aboutToDisappear(): void {
    if (this.demoTextTimer !== undefined) {
      clearInterval(this.demoTextTimer)
      this.demoTextTimer = undefined
    }
  }

  build() {
    Column() {
      Blank()
        .layoutWeight(1)

      Scroll(this.textScroller) {
        Text(this.demoText)
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
            .margin({ top: 13, bottom: 15 })

          Row() {
            Row({ space: 5 }) {
              ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21],
                (item: number) => {
                  Column()
                    .width(2.5)
                    .height(item % 4 === 0 ? 18 : item % 3 === 0 ? 13 : 9)
                    .borderRadius(2)
                    .backgroundColor('#fff')
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
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(255, 255, 255, 0.08)')
  }
}
