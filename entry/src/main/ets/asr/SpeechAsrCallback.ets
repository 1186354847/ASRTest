/**
 * @Desc: 听写结果回调
 * @author: leon
 * @datetime: 2024/3/21
 */
export interface SpeechAsrCallback {

  onBegin: ()=> void

  onError: (code: number, message: string)=> void

  onVolumeChanged: (volume: number)=> void

  onListeningResult: (text: string, last: boolean)=> void

  onComplete: ()=> void

}
