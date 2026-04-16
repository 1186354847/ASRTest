import { openASRToast } from '../component/ASRToast'

@Entry
@Component
struct Index2 {
  @State resultText: string = ''

  build() {
    Column({ space: 20 }) {
      Text('录音')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#0F172A')

      Scroll() {
        Text(this.resultText.length > 0 ? this.resultText : '点击下面按钮后，弹窗会自动开始录音，识别文字会实时显示在这里。')
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

      Button('打开收音弹窗')
        .width('100%')
        .height(52)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor('#2563EB')
        .borderRadius(26)
        .onClick(() => {
          this.resultText = ''
          openASRToast((text: string) => {
            this.resultText = text
          })
        })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}