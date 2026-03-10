import audio from '@ohos.multimedia.audio';
import { AudioRecorderStatusListener } from './AudioRecorderStatusListener';
import { SpeechError } from '../utils/exception/SpeechError';
import { SpeechException } from '../utils/exception/SpeechException';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';


/**
 * @Desc: pcm音频播放器
 * @author: leon
 * @datetime: 2024/3/6
 */
export class AudioRecorder {
  TAG = 'AudioRecorder';
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  //实时音频读取while循环
  audioLoop = false
  audioCapturer: audio.AudioCapturer | undefined = undefined;
  audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
    channels: audio.AudioChannel.CHANNEL_1,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  }
  audioCapturerInfo: audio.AudioCapturerInfo = {
    source: audio.SourceType.SOURCE_TYPE_MIC, // 音源类型
    capturerFlags: 0 // 音频采集器标志
  }
  audioCapturerOptions: audio.AudioCapturerOptions = {
    streamInfo: this.audioStreamInfo,
    capturerInfo: this.audioCapturerInfo
  }
  // audioManager = audio.getAudioManager();

  audioStatusCallback?: AudioRecorderStatusListener
  eventTag = "AudioRecorder_"

  constructor() {
    // let groupId: number = audio.DEFAULT_VOLUME_GROUP_ID;
    // let audioVolumeManager: audio.AudioVolumeManager = this.audioManager.getVolumeManager();
    // audioVolumeManager.on('volumeChange', (volumeEvent: audio.VolumeEvent) => {
    //   console.info(`VolumeType of stream: ${volumeEvent.volumeType} `);
    //   console.info(`Volume level: ${volumeEvent.volume} `);
    //   console.info(`Whether to updateUI: ${volumeEvent.updateUi} `);
    // });
  }


  public setAudioRecorderChange(listener: AudioRecorderStatusListener | undefined) {
    this.audioStatusCallback = listener
  }


  formatEvent(event: string) {
    return this.eventTag + event;
  }


  async startRecording() {
    audio.createAudioCapturer(this.audioCapturerOptions, (err, capturer) => { // 创建AudioCapturer实例
      if (err) {
        console.error(`Invoke createAudioCapturer failed, code is ${err.code}, message is ${err.message}`);
        this.audioStatusCallback?.onRecordError(new SpeechException(SpeechError.AUDIO_RECORDER_INIT_ERROR_CODE, "麦克风初始化失败"))
        return;
      }
      console.info(`${this.TAG}: create AudioCapturer success`);
      this.audioCapturer = capturer;
      if (this.audioCapturer !== undefined) {
        this.onStart();
        // (this.audioCapturer as audio.AudioCapturer).on('markReach', 1000, (position: number) => { // 订阅markReach事件，当采集的帧数达到1000时触发回调
        //   if (position === 1000) {
        //     console.info('ON Triggered successfully');
        //   }
        // });
        // (this.audioCapturer as audio.AudioCapturer).on('periodReach', 2000, (position: number) => { // 订阅periodReach事件，当采集的帧数达到2000时触发回调
        //   if (position === 2000) {
        //     console.info('ON Triggered successfully');
        //   }
        // });
      }
    });
  }

  /**
   * 开始音频采集
   */
  private async onStart() {
    if (this.audioCapturer !== undefined) {
      let stateGroup = [audio.AudioState.STATE_PREPARED, audio.AudioState.STATE_PAUSED, audio.AudioState.STATE_STOPPED];
      // 当且仅当状态为STATE_PREPARED、STATE_PAUSED和STATE_STOPPED之一时才能启动采集
      if (stateGroup.indexOf((this.audioCapturer as audio.AudioCapturer).state.valueOf()) === -1) {
        console.error(`${this.TAG}: start failed`);
        return;
      }

      // 启动采集
      // await (this.audioCapturer as audio.AudioCapturer).start();
      let audioRecorder = (this.audioCapturer as audio.AudioCapturer);
      audioRecorder.start()
        .then(async () => {
          this.audioLoop = true
          this.audioStatusCallback?.onRecordStart();
          while (this.audioLoop) {
            // let bufferSize = await audioRecorder.getBufferSize();
            let bufferSize = 1280;
            if (bufferSize > 0) {
              let buffer = await audioRecorder.read(bufferSize, true);
              const volume = this.volumeFrom16bit(buffer);
              this.audioStatusCallback?.onRecordProgress(buffer, volume)
            }
          }
        }).catch((error: Object) => {
        this.audioStatusCallback?.onRecordError(new SpeechException(SpeechError.AUDIO_RECORDER_START_ERROR_CODE, "麦克风音频采集失败"))
      });
      // let count = 0;
      // const filePath = this.context.filesDir + '/test.wav'; // 采集到的音频文件存储路径
      // let file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE); // 如果文件不存在则创建文件
      // let fd = file.fd;

      // class Options {
      //   offset: number = 0;
      //   length: number = 0
      // }

      // while (this.audioLoop) {
      //   let bufferSize = await (this.audioCapturer as audio.AudioCapturer).getBufferSize();
      //   if (bufferSize > 0) {
      //     let buffer = await (this.audioCapturer as audio.AudioCapturer).read(bufferSize, true);
      //     this.audioStatusCallback?.onRecordProgress(buffer, 1)
      //   }
      //
      //   // let options: Options = {
      //   //   offset: count * bufferSize,
      //   //   length: bufferSize
      //   // };
      //   // if (buffer === undefined) {
      //   //   console.error(`${this.TAG}: read buffer failed`);
      //   // } else {
      //   //   let number = fs.writeSync(fd, buffer, options);
      //   //   console.info(`${this.TAG}: write date: ${number}`);
      //   // }
      //   // count++;
      // }
    }
  }


  /**
   * 音量分贝大小计算
   * @param data 音频流
   * @returns 取值返回0-80
   */
  private volumeFrom16bit(data: ArrayBuffer): number {
    const int16Array = new Int16Array(data);
    const allZeros = int16Array.every(value => value === 0);
    if (allZeros) {
      return 0;
    }
    let maxVal = 0;
    for (let i = 0; i < int16Array.length; i++) {
      maxVal = Math.max(maxVal, Math.abs(int16Array[i]));
    }
    let vol = 20 * Math.log10(maxVal / 32767);
    vol = Math.abs(vol);
    if (vol >= 80) {
      vol = 80;
    }
    return vol;
  }


  /**
   * 停止采集
   */
  onStopRecord() {
    this.audioLoop = false
    if (this.audioCapturer !== undefined) {
      // 只有采集器状态为STATE_RUNNING或STATE_PAUSED的时候才可以停止
      if ((this.audioCapturer as audio.AudioCapturer).state.valueOf() !== audio.AudioState.STATE_RUNNING &&
        (this.audioCapturer as audio.AudioCapturer).state.valueOf() !== audio.AudioState.STATE_PAUSED) {
        console.info('Capturer is not running or paused');
        this.audioStatusCallback?.onRecordStop()
        return;
      }
      (this.audioCapturer as audio.AudioCapturer).stop()
        .then(() => {
          if ((this.audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_STOPPED) {
            console.info('Capturer stopped');
            this.audioStatusCallback?.onRecordStop()
          } else {
            console.error('Capturer stop failed');
          }
        })
        .catch(() => {
          console.error('Capturer stop failed');
        })
      // await (this.audioCapturer as audio.AudioCapturer).stop(); // 停止采集
      // if ((this.audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_STOPPED) {
      //   console.info('Capturer stopped');
      //   this.audioStatusCallback?.onRecordStop()
      // } else {
      //   console.error('Capturer stop failed');
      // }
    }
  }

  /**
   * 销毁实例，释放资源
   */
  async release() {
    this.audioLoop = false
    if (this.audioCapturer !== undefined) {
      // 采集器状态不是STATE_RELEASED或STATE_NEW状态，才能release
      if ((this.audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_RELEASED ||
        (this.audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_NEW) {
        console.info('Capturer already released');
        return;
      }
      await (this.audioCapturer as audio.AudioCapturer).release(); // 释放资源
      if ((this.audioCapturer as audio.AudioCapturer).state.valueOf() === audio.AudioState.STATE_RELEASED) {
        console.info('Capturer released');
      } else {
        console.error('Capturer release failed');
      }
    }
  }
}
