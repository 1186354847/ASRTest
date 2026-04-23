export interface VolcAudioInfo {
  duration?: number
}

export interface VolcWord {
  text?: string
  start_time?: number
  end_time?: number
  blank_duration?: number
}

export interface VolcUtterance {
  text?: string
  start_time?: number
  end_time?: number
  definite?: boolean
  words?: VolcWord[]
}

export interface VolcResult {
  text?: string
  utterances?: VolcUtterance[]
}

export interface VolcResponsePayload {
  audio_info?: VolcAudioInfo
  result?: VolcResult
}

export interface VolcErrorPayload {
  code?: number
  message?: string
}

export interface VolcUserPayload {
  uid: string
}

export interface VolcAudioPayload {
  format: string
  codec: string
  rate: number
  bits: number
  channel: number
}

export interface VolcRequestPayload {
  model_name: string
  enable_itn: boolean
  enable_punc: boolean
  enable_ddc: boolean
  show_utterances: boolean
  enable_nonstream: boolean
  end_window_size: number
}

export interface VolcFullClientRequestPayload {
  user: VolcUserPayload
  audio: VolcAudioPayload
  request: VolcRequestPayload
}

export class VolcAsrRequestOptions {
  uid: string = 'demo_uid'
  audioFormat: string = 'pcm'
  audioCodec: string = 'raw'
  sampleRate: number = 16000
  bits: number = 16
  channel: number = 1
  modelName: string = 'bigmodel'
  enableItn: boolean = true
  enablePunc: boolean = true
  enableDdc: boolean = true
  showUtterances: boolean = true
  enableNonstream: boolean = false
  segmentDurationMs: number = 200
  endWindowSize: number = 1000
  autoStopOnDefinite: boolean = true
}

export class VolcResponseFrame {
  code: number = 0
  event: number = 0
  isLastPackage: boolean = false
  payloadSequence: number = 0
  payloadSize: number = 0
  payloadText: string = ''
  payload?: VolcResponsePayload
}

export interface AudioDrainResult {
  audio: ArrayBuffer
  isLast: boolean
}
