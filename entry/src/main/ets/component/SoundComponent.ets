@Component
export struct SoundComponent {
  @Prop volumeNumber: number = 0
  maxVolume: number = 100 // 最大音量
  noise: number = 20 // 噪音阈值
  @Prop lineColor: ResourceStr = '#ee2233'
  lineSpace: number = 10 // 间距
  lineWidth: number = 5 // 宽
  minHeight?: number // 最小高度，不传时默认与 lineWidth 一致
  maxHeight: number = 100
  maxWidth: number = 200
  @State lineHeightList: number[] = []
  timer?: number

  aboutToAppear(): void {
    console.info('SoundComponent aboutToAppear started');
    this.lineHeightList = this.createMinHeightList()
    // 清除可能存在的旧定时器
    if (this.timer) {
      clearInterval(this.timer);
    }
    setTimeout(() => {
      this.timer = setInterval(() => {
        this.volumeChange()
      }, 200)
    })

  }

  aboutToDisappear(): void {
    clearInterval(this.timer)
    this.timer = undefined
  }

  volumeChange() {
    const minHeight = this.getMinHeight()
    const count = this.getLineCount()
    const safeVolume = this.volumeNumber ?? 0

    if (safeVolume <= this.noise || this.maxVolume <= 0) {
      this.lineHeightList = this.createMinHeightList()
      return
    }

    const ratio = Math.min(Math.max((safeVolume - this.noise) / (this.maxVolume - this.noise), 0), 1.0)
    const newList: number[] = []

    for (let i = 0; i < count; i++) {
      const randomFactor = 0.8 + Math.random() * 0.4
      let height = ratio * this.maxHeight * randomFactor
      console.log('aaaaaaaa safeVolume: ' + safeVolume + ' ratio: ' + ratio + ' height: ' + height)

      height = Math.floor(height)
      if (height > this.maxHeight) {
        height = this.maxHeight
      }
      if (height < minHeight) {
        height = minHeight
      }

      newList.push(height)
    }

    this.lineHeightList = newList
  }

  private getLineCount(): number {
    const unitWidth = this.lineWidth + this.lineSpace
    if (unitWidth <= 0 || this.maxWidth <= 0) {
      return 1
    }
    return Math.max(1, Math.floor((this.maxWidth + this.lineSpace) / unitWidth))
  }

  private createMinHeightList(): number[] {
    const list: number[] = []
    const minHeight = this.getMinHeight()
    const count = this.getLineCount()
    for (let i = 0; i < count; i++) {
      list.push(minHeight)
    }
    return list
  }

  private getMinHeight(): number {
    return this.minHeight ?? this.lineWidth
  }

  build() {
    Row({ space: this.lineSpace }) {
      ForEach(this.lineHeightList, (item: number, index) => {
        Column() {

        }.backgroundColor(this.lineColor)
        .width(this.lineWidth)
        .height(item)
        .borderRadius(this.lineWidth / 2)
      })
    }.width('100%')
    .height(this.maxHeight)
    .width(this.maxWidth)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}