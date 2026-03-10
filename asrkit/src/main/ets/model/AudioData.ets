/**
 * @Desc: 音频流数据
 * @author: leon
 * @datetime: 2024/3/8
 */
export class AudioData {
  status: number = 0
  audio: ArrayBuffer

  constructor(status: number, audio: ArrayBuffer) {
    this.status = status
    this.audio = audio
  }
}
