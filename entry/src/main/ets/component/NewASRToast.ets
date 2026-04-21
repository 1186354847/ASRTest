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
      Row() {
        Column() {
          Text(this.isLocked ? '取消' : '左滑取消')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('35%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.currentArea === NewASRPressArea.CANCEL ? '#B91C1C' : '#EF4444')
        .opacity(this.currentArea === NewASRPressArea.CANCEL ? 1 : 0.55)
        .onClick(() => {
          if (this.isLocked) {
            this.toastManager.handleLockedAction(NewASRPressArea.CANCEL)
          }
        })

        Column() {
          Text(this.isLocked ? '发送' : '上滑锁定')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('30%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.currentArea === NewASRPressArea.LOCK ? '#B45309' : '#F59E0B')
        .opacity(this.currentArea === NewASRPressArea.LOCK ? 1 : 0.55)
        .onClick(() => {
          if (this.isLocked) {
            this.toastManager.handleLockedAction(NewASRPressArea.LOCK)
          }
        })

        Column() {
          Text(this.isLocked ? '转文字' : '右滑转文字')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('35%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.currentArea === NewASRPressArea.TEXT ? '#1D4ED8' : '#3B82F6')
        .opacity(this.currentArea === NewASRPressArea.TEXT ? 1 : 0.55)
        .onClick(() => {
          if (this.isLocked) {
            this.toastManager.handleLockedAction(NewASRPressArea.TEXT)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)

      Column() {
        Text(this.isLocked ? '' : '松手发送')
          .fontSize(18)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(150)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.currentArea === NewASRPressArea.VOICE ? '#047857' : '#10B981')
      .opacity(this.currentArea === NewASRPressArea.VOICE ? 1 : 0.55)
    }
    .width('100%')
    .height(800)
    .backgroundColor('#FFFFFF')
    .borderRadius({
      topLeft: 24,
      topRight: 24
    })
  }
}
