import { openASRToast } from '../component/ASRToast'

@Entry
@Component
struct Index2 {

  build() {
    RelativeContainer() {
      Text('录音')
        .id('Index2HelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          openASRToast((text: string) => {
            console.log('sss' + text)
          })
        })
    }
    .height('100%')
    .width('100%')
  }
}