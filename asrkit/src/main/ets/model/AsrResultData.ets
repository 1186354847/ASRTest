/**
 * @Desc: 语音识别结果返回
 * @author: leon
 * @datetime: 2024/3/14
 */
export class AsrResult {
  code?: number
  message?: string
  sid?: string
  data?: AsrData
}

export class AsrData {
  result?: AsrDetail
  status?: number
}

export class AsrDetail {
  bg?: number
  ed?: number
  pgs?: string
  rg?: number[]
  sn?: number
  ws?: AsrWsData[]
  ls?: boolean
  vad?: Record<string, Object>
}

export class AsrWsData {
  cw?: AsrCwData[]
  bg?: number
  ed?: number
}

export class AsrCwData {
  sc?: number
  w?: string
}