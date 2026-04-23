
import { NewASRToastManager } from '../component/NewASRToastManager'

@Entry
@Component
struct Index3 {
  @State resultText: string = ''
  private toastManager: NewASRToastManager = NewASRToastManager.getInstance()

  build() {
    Column({ space: 20 }) {
      Text('录音')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Scroll() {
        Text(this.resultText.length > 0 ? this.resultText : '长按下面按钮后，先弹出底部弹窗。当前这一步只验证按下弹出、松手关闭。')
          .width('100%')
          .fontSize(16)
          .lineHeight(24)
          .fontColor(this.resultText.length > 0 ? '#1E293B' : '#94A3B8')
          .padding(16)
      }
      .width('100%')
      .height(260)
      .backgroundColor('#F8FAFC')
      .borderRadius(16)
      .scrollBar(BarState.Off)

      Button('长按收音')
        .width('100%')
        .height(52)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor('#2563EB')
        .borderRadius(26)
        .hitTestBehavior(HitTestMode.Block)
        .onTouch((event: TouchEvent) => {
          this.toastManager.handleTouchEvent(event, {
            onVoiceSend: (audioPath: string, duration: number) => {
              this.resultText = audioPath + '，duration=' + duration
            },
            onTextSend: (text: string) => {
              this.resultText = text
            },
            onCancel: () => {
            }
          })
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor('#FFFFFF')
  }
}
