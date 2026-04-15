import EntryAbility from "../entryability/EntryAbility"
import { ComponentContent } from "@kit.ArkUI"


export interface ActionBuilderParam {
  onTextChange?: (text: string) => void
  cancelClick?: () => void
}

export function openASRToast(onTextChange: (text: string) => void) {
  const uiContext = EntryAbility.ability.windowStage?.getMainWindowSync().getUIContext()!
  const promptAction = uiContext.getPromptAction()
  let newParam = {
    onTextChange: (text: string) => {
      onTextChange(text)
    },
    cancelClick: () => {
      promptAction.closeCustomDialog(contentNode)
    },
  } as ActionBuilderParam

  let contentNode = new ComponentContent(uiContext, wrapBuilder(ASRListenerBuilder), newParam)

  promptAction.openCustomDialog(contentNode, {
    autoCancel: false,
    alignment: DialogAlignment.Center,
    onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
      newParam.cancelClick && newParam.cancelClick()
      console.log('sssss')
    }
  })
}

@Builder
export function ASRListenerBuilder(param: ActionBuilderParam) {
  Column() {
    ASRListener({
      onTextChange: param.onTextChange
    })
  }.width('100%')
  .height('100%')
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
  .backgroundColor("rgba(0, 0, 0, 0.5)")
}

@Component
struct ASRListener {
  onTextChange?: (text: string) => void

  aboutToAppear(): void {
    console.log('aboutToAppear')
  }

  aboutToDisappear(): void {
    console.log('aboutToDisappear')
  }

  build() {
    Column()
      .width(100)
      .height(100)
      .backgroundColor(Color.Red)
      .onClick(() => {
        console.log('click')
        this.onTextChange && this.onTextChange('123')
      })
  }
}