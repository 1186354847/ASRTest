import { buffer } from '@kit.ArkTS'
import { SpeechError } from '../utils/exception/SpeechError'
import { SpeechException } from '../utils/exception/SpeechException'
import { VolcFullClientRequestPayload, VolcResponseFrame, VolcResponsePayload } from './VolcModels'

const PROTOCOL_VERSION = 0b0001
const DEFAULT_HEADER_SIZE = 0b0001

const CLIENT_FULL_REQUEST = 0b0001
const CLIENT_AUDIO_ONLY_REQUEST = 0b0010
const SERVER_FULL_RESPONSE = 0b1001
const SERVER_ERROR_RESPONSE = 0b1111

const POS_SEQUENCE = 0b0001
const NEG_WITH_SEQUENCE = 0b0011

const NO_SERIALIZATION = 0b0000
const JSON_SERIALIZATION = 0b0001

const NO_COMPRESSION = 0b0000
const GZIP_COMPRESSION = 0b0001

export class VolcWsProtocol {
  static async buildFullRequestPacket(payload: VolcFullClientRequestPayload, sequence: number): Promise<ArrayBuffer> {
    const payloadBuffer = VolcWsProtocol.stringToArrayBuffer(JSON.stringify(payload))
    const header = VolcWsProtocol.buildHeader(CLIENT_FULL_REQUEST, POS_SEQUENCE, JSON_SERIALIZATION, NO_COMPRESSION)
    return VolcWsProtocol.concatBuffers([header, VolcWsProtocol.intToBytes(sequence),
      VolcWsProtocol.intToBytes(payloadBuffer.byteLength), payloadBuffer])
  }

  static async buildAudioPacket(audio: ArrayBuffer, sequence: number, isLast: boolean): Promise<ArrayBuffer> {
    const flag = isLast ? NEG_WITH_SEQUENCE : POS_SEQUENCE
    const header = VolcWsProtocol.buildHeader(CLIENT_AUDIO_ONLY_REQUEST, flag, NO_SERIALIZATION, NO_COMPRESSION)
    return VolcWsProtocol.concatBuffers([header, VolcWsProtocol.intToBytes(sequence), VolcWsProtocol.intToBytes(audio.byteLength),
      audio])
  }

  static async parseResponsePacket(packet: ArrayBuffer): Promise<VolcResponseFrame> {
    const bytes = new Uint8Array(packet)
    if (bytes.length < 4) {
      throw new SpeechException(SpeechError.ASR_RESULT_ERROR_CODE, '火山返回数据长度不合法')
    }

    const frame = new VolcResponseFrame()
    const headerSize = bytes[0] & 0x0f
    const messageType = (bytes[1] >> 4) & 0x0f
    const messageFlags = bytes[1] & 0x0f
    const serialization = (bytes[2] >> 4) & 0x0f
    const compression = bytes[2] & 0x0f

    let payload = bytes.slice(headerSize * 4).buffer as ArrayBuffer

    if ((messageFlags & 0x01) !== 0 && payload.byteLength >= 4) {
      frame.payloadSequence = VolcWsProtocol.bytesToInt(payload.slice(0, 4))
      payload = payload.slice(4)
    }
    if ((messageFlags & 0x02) !== 0) {
      frame.isLastPackage = true
    }
    if ((messageFlags & 0x04) !== 0 && payload.byteLength >= 4) {
      frame.event = VolcWsProtocol.bytesToInt(payload.slice(0, 4))
      payload = payload.slice(4)
    }

    if (messageType == SERVER_FULL_RESPONSE) {
      if (payload.byteLength >= 4) {
        frame.payloadSize = VolcWsProtocol.bytesToInt(payload.slice(0, 4))
        payload = payload.slice(4)
      }
      if (compression == GZIP_COMPRESSION) {
        // payload = await VolcWsProtocol.gunzip(payload)
      }
      if (serialization == JSON_SERIALIZATION && payload.byteLength > 0) {
        frame.payloadText = VolcWsProtocol.arrayBufferToString(payload)
        frame.payload = JSON.parse(frame.payloadText) as VolcResponsePayload
      }
      return frame
    }

    if (messageType == SERVER_ERROR_RESPONSE) {
      if (payload.byteLength >= 8) {
        frame.code = VolcWsProtocol.bytesToInt(payload.slice(0, 4))
        frame.payloadSize = VolcWsProtocol.bytesToInt(payload.slice(4, 8))
        payload = payload.slice(8)
      }
      if (serialization == JSON_SERIALIZATION && payload.byteLength > 0) {
        frame.payloadText = VolcWsProtocol.arrayBufferToString(payload)
      }
      return frame
    }

    throw new SpeechException(SpeechError.ASR_RESULT_ERROR_CODE, `火山返回了未知消息类型: ${messageType}`)
  }

  private static buildHeader(messageType: number, flags: number, serialization: number, compression: number): ArrayBuffer {
    return new Uint8Array([
      (PROTOCOL_VERSION << 4) | DEFAULT_HEADER_SIZE,
      (messageType << 4) | flags,
      (serialization << 4) | compression,
      0
    ]).buffer
  }

  private static intToBytes(value: number): ArrayBuffer {
    return new Uint8Array([
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff
    ]).buffer
  }

  private static bytesToInt(value: ArrayBuffer): number {
    const data = new Uint8Array(value)
    if (data.length !== 4) {
      throw new SpeechException(SpeechError.ASR_RESULT_ERROR_CODE, '整数字段长度不合法')
    }
    return ((data[0] & 0xff) << 24) | ((data[1] & 0xff) << 16) | ((data[2] & 0xff) << 8) | (data[3] & 0xff)
  }

  private static concatBuffers(parts: ArrayBuffer[]): ArrayBuffer {
    let total = 0
    for (let part of parts) {
      total += part.byteLength
    }
    const merged = new Uint8Array(total)
    let offset = 0
    for (let part of parts) {
      merged.set(new Uint8Array(part), offset)
      offset += part.byteLength
    }
    return merged.buffer
  }

  private static stringToArrayBuffer(value: string): ArrayBuffer {
    const data = buffer.from(value, 'utf-8')
    const bytes = new Uint8Array(data.length)
    bytes.set(new Uint8Array(data.buffer, data.byteOffset, data.length))
    return bytes.buffer
  }

  private static arrayBufferToString(value: ArrayBuffer): string {
    return buffer.from(new Uint8Array(value)).toString('utf-8')
  }
}
