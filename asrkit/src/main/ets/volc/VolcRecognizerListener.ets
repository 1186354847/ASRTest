import { SpeechException } from '../utils/exception/SpeechException'
import { VolcResponsePayload } from './VolcModels'

export interface VolcRecognizerListener {
  onBeginOfSpeech: () => void

  onEndOfSpeech: () => void

  onVolumeChange: (volume: number) => void

  onResult: (payload: VolcResponsePayload, isLast: boolean) => void

  onError: (error: SpeechException) => void
}
