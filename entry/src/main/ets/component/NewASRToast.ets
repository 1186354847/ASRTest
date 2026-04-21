import {
  NEW_ASR_AREA_STORAGE_KEY,
  NEW_ASR_LOCKED_STORAGE_KEY,
  NewASRPressArea,
  NewASRToastManager
} from './NewASRToastManager'

export interface NewASRToastParam {
  onVoiceSend?: (audioPath: string) => void
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
  private toastManager: NewASRToastManager = NewASRToastManager.getInstance()

  build() {
    Column() {
      Blank()
        .layoutWeight(1)

      Text('北京明天天气怎么样')
        .width(325)
        .height(43)
        .padding({ left: 18, right: 18 })
        .fontSize(15)
        .fontColor('#3B3B45')
        .backgroundColor('#FFFFFF')
        .borderRadius(11)
        .margin({ bottom: 30 })

      Row() {
        Column() {
          Column() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .margin({ bottom: 6 })

            Text(this.isLocked ? '取消' : '左滑取消')
              .fontSize(14)
              .fontColor('#4F4C5D')
          }
          .width(112)
          .height(58)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.currentArea === NewASRPressArea.CANCEL ? '#FFFFFF' : 'rgba(255, 255, 255, 0.72)')
          .borderRadius(24)
          .shadow({
            radius: this.currentArea === NewASRPressArea.CANCEL ? 18 : 8,
            color: 'rgba(91, 86, 116, 0.18)',
            offsetX: 0,
            offsetY: 4
          })
          .scale({
            x: this.currentArea === NewASRPressArea.CANCEL ? 1.04 : 1,
            y: this.currentArea === NewASRPressArea.CANCEL ? 1.04 : 1
          })
          .rotate({ angle: -6 })
        }
        .width('35%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          if (this.isLocked) {
            this.toastManager.handleLockedAction(NewASRPressArea.CANCEL)
          }
        })

        Column() {
          Column() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .margin({ bottom: 6 })

            Text(this.isLocked ? '发送' : '上滑锁定')
              .fontSize(14)
              .fontColor('#4F4C5D')
          }
          .width(100)
          .height(58)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.currentArea === NewASRPressArea.LOCK ? '#FFFFFF' : 'rgba(255, 255, 255, 0.72)')
          .borderRadius(24)
          .shadow({
            radius: this.currentArea === NewASRPressArea.LOCK ? 18 : 8,
            color: 'rgba(91, 86, 116, 0.18)',
            offsetX: 0,
            offsetY: 4
          })
          .scale({
            x: this.currentArea === NewASRPressArea.LOCK ? 1.04 : 1,
            y: this.currentArea === NewASRPressArea.LOCK ? 1.04 : 1
          })
        }
        .width('30%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          if (this.isLocked) {
            this.toastManager.handleLockedAction(NewASRPressArea.LOCK)
          }
        })

        Column() {
          Column() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .margin({ bottom: 6 })

            Text(this.isLocked ? '转文字' : '右滑转文字')
              .fontSize(14)
              .fontColor('#4F4C5D')
          }
          .width(112)
          .height(58)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.currentArea === NewASRPressArea.TEXT ? '#FFFFFF' : 'rgba(255, 255, 255, 0.72)')
          .borderRadius(24)
          .shadow({
            radius: this.currentArea === NewASRPressArea.TEXT ? 18 : 8,
            color: 'rgba(91, 86, 116, 0.18)',
            offsetX: 0,
            offsetY: 4
          })
          .scale({
            x: this.currentArea === NewASRPressArea.TEXT ? 1.04 : 1,
            y: this.currentArea === NewASRPressArea.TEXT ? 1.04 : 1
          })
          .rotate({ angle: 6 })
        }
        .width('35%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          if (this.isLocked) {
            this.toastManager.handleLockedAction(NewASRPressArea.TEXT)
          }
        })
      }
      .width('100%')
      .height(100)
      .alignItems(VerticalAlign.Center)

      Stack({ alignContent: Alignment.Top }) {
        Column() {
          Text(this.isLocked ? '' : '松手 发送')
            .fontSize(15)
            .fontColor(this.currentArea === NewASRPressArea.VOICE ? '#5D4A9B' : '#6F6684')
            .fontWeight(FontWeight.Medium)
            .margin({ top: 18, bottom: 18 })

          Row({ space: 5 }) {
            ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21], (item: number) => {
              Column()
                .width(3)
                .height(item % 4 === 0 ? 22 : item % 3 === 0 ? 16 : 11)
                .backgroundColor(item < 10 ? '#FF4C79' : '#A844F4')
                .borderRadius(2)
            })
          }
          .height(34)
          .alignItems(VerticalAlign.Center)
        }
        .width('130%')
        .height(175)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.currentArea === NewASRPressArea.VOICE ? '#F4ECFF' : '#F8F2FF')
        .borderRadius({
          topLeft: 180,
          topRight: 180
        })
      }
      .width('100%')
      .height(150)
      .clip(true)
    }
    .width('100%')
    .height(800)
    .backgroundColor('rgba(255, 255, 255, 0.08)')
  }
}
