import { AsrHelper } from '../asr/AsrHelper'
import { SpeechAsrCallback } from '../asr/SpeechAsrCallback'
import EntryAbility from '../entryability/EntryAbility'
import { abilityAccessCtrl } from '@kit.AbilityKit'

function getAppContext() {
  return EntryAbility.ability?.context
}
@Entry
@Component
struct SpeechToTextPage {
  @State isRecording: boolean = false
  @State recognizedText: string = ''
  @State recordingStatus: string = '准备录音'
  @State volumeLevel: number = 0
  private asrHelper: AsrHelper | null = null

  aboutToAppear() {
    // 初始化 ASR 辅助类
    this.asrHelper = AsrHelper.getInstance()
    this.asrHelper.initialize()


    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(getAppContext(), ['ohos.permission.MICROPHONE']).then((data) => {

    }).catch(() => {
    })
  }

  build() {
    Column() {
      // 标题
      Row() {
        Image($r('app.media.startIcon'))
          .width(40)
          .height(40)
          .margin({ right: 16 })
        Text('语音转文字')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007DFF')
      }
      .width('100%')
      .margin({ bottom: 24 })

      // 状态显示
      Row() {
        Text(this.getStatusIcon())
          .fontSize(24)
          .margin({ right: 8 })
        Text(this.recordingStatus)
          .fontSize(16)
          .fontColor(this.getStatusColor())
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F7FA')
      .borderRadius(8)
      .margin({ bottom: 20 })

      // 音量指示器
      if (this.isRecording) {
        Column() {
          Text('音量大小')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          Row() {
            Progress({
              value: this.volumeLevel,
              total: 60,
              type: ProgressType.Linear,
              style: ProgressStyle.Linear
            })
            .width('70%')
            .height(6)
            .backgroundColor('#E8E8E8')
            .color('#007DFF')
            .margin({ right: 12 })

            Text(`${this.volumeLevel}%`)
              .fontSize(12)
              .fontColor('#666666')
          }
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: 24 })
      }

      // 识别结果显示区域
      Column() {
        Text('识别结果')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })

        Scroll() {
          Text(this.recognizedText || '点击"开始录音"按钮开始语音识别...')
            .fontSize(16)
            .lineHeight(24)
            .textAlign(TextAlign.Start)
            .padding(16)
            .backgroundColor('#F9F9F9')
            .borderRadius(8)
            .width('100%')
            .height(300)
        }
        .scrollBar(BarState.Off)
        .scrollable(ScrollDirection.Vertical)
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 32 })
      .layoutWeight(1)

      // 控制按钮
      Button() {
        Row() {
          if (this.isRecording) {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .margin({ right: 8 })
            Text('停止录音')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
          } else {
            Image($r('app.media.foreground'))
              .width(20)
              .height(20)
              .margin({ right: 8 })
            Text('开始录音')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
          }
        }
      }
      .width('100%')
      .height(56)
      .backgroundColor(this.isRecording ? '#FF4444' : '#007DFF')
      .borderRadius(28)
      .onClick(() => {
        if (this.isRecording) {
          this.stopRecording()
        } else {
          this.startRecording()
        }
      })
      .enabled(!this.isRecording)
      .margin({ bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor(Color.White)
  }

  private getStatusIcon(): string {
    if (this.isRecording) {
      return '🔴'
    } else if (this.recordingStatus === '录音完成') {
      return '✅'
    } else {
      return '🔵'
    }
  }

  private getStatusColor(): string {
    if (this.isRecording) {
      return '#FF4444'
    } else if (this.recordingStatus === '录音完成') {
      return '#00C851'
    } else {
      return '#007DFF'
    }
  }

  private startRecording() {
    if (!this.asrHelper) {
      this.recordingStatus = '初始化失败'
      return
    }

    this.isRecording = true
    this.recordingStatus = '正在录音...'
    this.recognizedText = ''
    this.volumeLevel = 0

    // 设置识别参数
    this.asrHelper.setParams(3000, 1000)





    let lastText: string = ""
    let isLast: boolean = false

    // 开始监听
    this.asrHelper.startListening({
      onBegin() {
        console.log("开始语音听写")
        // 此回调表示：sdk内部录音机已经准备好了，用户可以开始语音输入
        // context.callbackSuccess(new Object({ status: true, eventType: "start" }), false);
      },
      onError(code: number, message: string) {
        console.log("听写报错： code:" + code + "，message:" + message)
      },
      onVolumeChanged(v: number) {
        console.log("音量大小===>" + v)
        // context.callbackSuccess(new Object({ status: true, eventType: "recognizerVolume", volume: v }), false);
      },
      onListeningResult(text: string, last: boolean) {
        console.log("startListening onListeningResult 听写结果：" + text, 'last:' + last)
        isLast = last
        lastText = text

        if (last) {
          // context.callbackSuccess(new Object({ status: true, eventType: "recognizerSuccess", resultText: text }),
          //   false);
        } else { //识别过程中返回：
          // context.callbackSuccess(new Object({ status: true, eventType: "recognizerProgress", resultText: text }),
          //   false);
        }
      },
      onComplete() { //按住说话松手之后会调用stop直接走这里不会走onListeningResult;正常结束之后也会走这里
        if (!isLast && lastText.length > 0) {
          // context.callbackSuccess(new Object({ status: true, eventType: "recognizerSuccess", resultText: lastText }),
          //   false)
        }
        lastText = ''
        console.log("startListening onComplete 结束语音听写" + 'last:' + isLast)
      }
    });
  }

  private stopRecording() {
    this.isRecording = false
    this.recordingStatus = '正在停止...'
    this.volumeLevel = 0

    if (this.asrHelper) {
      this.asrHelper.stopListening()
    }
  }

  // 更新音量
  public updateVolume(volume: number) {
    this.volumeLevel = volume
  }

  // 更新识别结果
  public updateResult(text: string, isLast: boolean) {
    if (isLast) {
      this.recognizedText += text
    } else {
      this.recognizedText = text
    }
  }

  // 更新状态
  public updateStatus(status: string) {
    this.recordingStatus = status
  }
}
