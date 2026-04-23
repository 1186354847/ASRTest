import { fileIo as fs, ReadOptions } from '@kit.CoreFileKit';

export class PcmToWavUtil {
  //采样率
  private mSampleRate: number = 0
  // 声道数
  private mChannel: number = 0;

  /**
   * @param sampleRate  sample rate、采样率
   * @param channel     channel、声道
   */
  constructor(sampleRate: number, channel: number) {
    this.mSampleRate = sampleRate;
    this.mChannel = channel;
  }

  /**
   * pcm文件转wav文件函数
   * @param src  源文件
   * @param dest 目标文件
   */
  public async pcmToWav(inFile: fs.File, outFile: fs.File): Promise<number> {
    // const inFile: fs.File = fs.openSync(src, fs.OpenMode.READ_ONLY);
    // const outFile: fs.File = fs.openSync(dest, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    let byteRate = 16 * this.mSampleRate * this.mChannel / 8;
    const inFileStat = fs.statSync(inFile.fd)
    // 音频文件
    let audioDataSize = inFileStat.size;
    let totalDataLen = audioDataSize + 36;
    // 1. wav 文件头编写
    this.writeWaveFileHeader(outFile, audioDataSize, totalDataLen, byteRate);
    // 2. 写入 pcm 数据
    this.writePcmData(inFile, outFile, audioDataSize)
    // 计算音频播放时长
    let duration = audioDataSize / byteRate
    return Math.round(duration)
  }

  // pcm 数据写入到 pcm 文件函数
  private writePcmData(inFile: fs.File, outFile: fs.File, audioDataSize: number) {
    // 写入 pcm 数据
    let readSize = 0
    let data = new ArrayBuffer(audioDataSize);
    let readOptions: ReadOptions = {
      offset: readSize,
      length: audioDataSize
    };
    let readLen = fs.readSync(inFile.fd, data, readOptions);
    while (readLen > 0) {
      readSize += readLen;
      fs.writeSync(outFile.fd, data, { length: readLen });
      readOptions.offset = readSize;
      readLen = fs.readSync(inFile.fd, data, readOptions);
    }
    fs.closeSync(inFile.fd)
    fs.closeSync(outFile.fd)
  }

  //写入wav文件头函数
  private writeWaveFileHeader(
    out: fs.File,
    audioDataSize: number,
    totalDataLen: number,
    byteRate: number
  ) {
    const header = new ArrayBuffer(44);
    const dv = new DataView(header);
    const bitsPerSample = 16; // 当前位深是16

    // 写入RIFF块
    this.writeString(dv, 0, 'RIFF');
    dv.setUint32(4, totalDataLen, true);
    this.writeString(dv, 8, 'WAVE');

    // 写入fmt块
    this.writeString(dv, 12, 'fmt ');
    dv.setUint32(16, 16, true); // fmt块大小
    dv.setUint16(20, 1, true); // 格式类别 (PCM)
    dv.setUint16(22, this.mChannel, true); // 通道数
    dv.setUint32(24, this.mSampleRate, true); // 采样率
    dv.setUint32(28, byteRate, true); // ByteRate 码率
    dv.setUint16(32, this.mChannel * bitsPerSample / 8, true); // BlockAlign
    dv.setUint16(34, bitsPerSample, true); // 位深

    // 写入data块
    this.writeString(dv, 36, 'data');
    dv.setUint32(40, audioDataSize, true); // 数据块大小
    // 写入
    fs.writeSync(out.fd, new Uint8Array(header).buffer, {
      length: 44
    })
  }

  private writeString(dv: DataView, offset: number, str: string) {
    for (let i = 0; i < str.length; i++) {
      dv.setUint8(offset + i, str.charCodeAt(i));
    }
  }
}


function pcm2Db(buffer: ArrayBuffer): number {
  // 获取一个 Int32Array 类型的视图，该视图将数组缓冲区解释为带符号 32 位整数数组
  const intArray = new Int32Array(buffer);
  let sum: number = 0;
  for (let i = 0; i < intArray.length; i++) {
    let sample: number = intArray[i] / 32768;
    sum += sample * sample;
  }
  let rms = Math.sqrt(sum / buffer.byteLength);
  return 20 * Math.log10(rms);
}