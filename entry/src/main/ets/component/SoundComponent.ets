@Component
export struct SoundComponent {
  @Prop volumeNumber: number
  maxVolume: number = 100 // 最大音量
  @Prop lineColor: ResourceStr = '#ee2233'
  lineSpace: number = 10 // 间距
  lineWidth: number = 5 // 宽
  maxHeight: number = 100
  @State lineHeightList: number[] = []
  timer?: number

  aboutToAppear(): void {
    console.info('SoundComponent aboutToAppear started');
    // 清除可能存在的旧定时器
    if (this.timer) {
      clearInterval(this.timer);
    }
    setTimeout(() => {
      this.timer = setInterval(() => {
        console.log('aaaaaaaaaaa')
        this.volumeChange()
        console.log('lllllllllllllllllllllllllllllllllllll')
      }, 200)
    })

  }

  aboutToDisappear(): void {
    clearInterval(this.timer)
    this.timer = undefined
  }

  volumeChange() {

    // 1. 计算当前音量对应的基准比例 (0.0 - 1.0)
    const ratio = Math.min(this.volumeNumber / this.maxVolume, 1.0);

    // 2. 确定生成波纹的数量 (如果列表为空则默认生成 20 个，保持数量稳定)
    const count = this.lineHeightList.length > 0 ? this.lineHeightList.length : 20;
    const newList: number[] = [];

    for (let i = 0; i < count; i++) {
      // 3. 计算随机高度：基准高度 * 随机因子
      // 随机因子范围建议在 0.5 ~ 1.5 之间，让波形有起伏但不过于夸张
      const randomFactor = 0.5 + Math.random();
      let height = ratio * this.maxHeight * randomFactor;

      // 4. 取整并再次确保不超过 maxHeight (防止随机因子过大导致溢出)
      height = Math.floor(height);
      if (height > this.maxHeight) {
        height = this.maxHeight;
      }

      // 如果计算结果为 0，可以选择保留 0 或者给一个极小值避免完全消失，这里按需求允许为 0
      newList.push(height);
    }

    // 5. 更新状态触发 UI 刷新
    this.lineHeightList = newList;
  }

  build() {
    Row({ space: this.lineSpace }) {
      ForEach(this.lineHeightList, (item: number, index) => {
        Column() {

        }.backgroundColor(this.lineColor)
        .width(this.lineWidth)
        .height(item)
      })
    }.width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}