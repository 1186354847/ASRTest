# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个基于 HarmonyOS 6.0.0 的 ASR（自动语音识别）测试项目，使用 ArkTS 语言开发。项目包含两个主要模块：entry（应用入口）和 asrkit（语音识别工具包）。

## 常用命令

### 构建
```bash
# 构建项目（debug模式）
hvigorw assembleHap

# 构建项目（release模式）
hvigorw assembleHap -p mode=release

# 清理构建缓存
hvigorw clean
```

### 测试
```bash
# 运行单元测试
hvigorw test

# 运行OHOS测试
hvigorw ohosTest

# 运行特定测试文件
hvigorw test -- --test-pattern="*SpeechRecognizerTest*"
```

### 安装和运行
```bash
# 安装应用到设备
hdc install entry/build/outputs/default/entry-unsigned.hap

# 启动应用
hdc shell aa start -b com.example.asrtest
```

## 项目架构

### 模块结构

1. **entry 模块** - 应用入口模块
   - 类型：entry
   - 功能：提供 UI 界面和业务逻辑封装
   - 主要组件：
     - `Index.ets` - 主页面
     - `EntryAbility.ets` - 应用入口能力
     - `AsrHelper.ets` - 语音听写辅助类（单例）
     - `AsrText.ets` - 识别结果数据模型
     - `SpeechAsrCallback.ets` - 识别结果回调接口

2. **asrkit 模块** - 语音识别工具包模块
   - 类型：har（共享资源包）
   - 功能：提供核心语音识别 SDK 功能
   - 主要组件：
     - `SpeechRecognizer.ets` - 核心语音识别器
     - `SpeechUtility.ets` - SDK 配置管理（单例）
     - `AudioRecorder.ets` - 音频录制器
     - 数据模型：`AsrParams`, `AsrResultData`, `AudioData`
     - 工具类：`Logger`, `AuthUtils`, `SpeechConstants`

### 核心架构

```
UI层 (entry)
├── Index页面 (显示识别结果)
└── AsrHelper (业务逻辑封装)
    ├── 初始化配置
    ├── 管理识别参数
    └── 处理渐进文本

SDK层 (asrkit)
├── SpeechRecognizer (核心识别器)
│   ├── WebSocket管理
│   ├── 音频流控制
│   └── 结果回调处理
├── AudioRecorder
│   ├── 麦克风采集
│   └── 音量计算
└── 配置和工具类
```

### 数据流向

```
麦克风 → AudioRecorder → SpeechRecognizer → WebSocket → 语音服务器
                               ↓
                            结果回调 → AsrHelper → UI显示
```

### 重要设计模式

1. **单例模式**：
   - `SpeechUtility` - 管理全局配置
   - `AsrHelper` - 提供统一的语音识别接口

2. **观察者模式**：
   - `RecognizerListener` - 监听识别状态变化
   - `AudioRecorderStatusListener` - 监听录制状态

3. **工厂模式**：
   - `SpeechRecognizer.create()` - 创建识别器实例

## 关键配置

### 权限配置
项目需要以下权限（在 asrkit 模块中配置）：
- `ohos.permission.INTERNET` - 网络访问
- `ohos.permission.GET_NETWORK_INFO` - 获取网络信息
- `ohos.permission.GET_WIFI_INFO` - 获取WiFi信息
- `ohos.permission.MICROPHONE` - 麦克风访问

### 构建配置
- 目标版本：HarmonyOS 6.0.0(20)
- 支持模式：debug, release
- 签名配置：使用本地开发证书

## 开发注意事项

1. **WebSocket 连接**：
   - 使用 `SpeechRecognizer` 管理 WebSocket 连接
   - 支持 `start/stop/destroy` 生命周期
   - 自动处理重连机制

2. **音频处理**：
   - 使用系统 `AudioCapturer` API 采集音频
   - 实时计算音量大小
   - 支持音频数据的编码和发送

3. **错误处理**：
   - 使用 `SpeechError` 和 `SpeechException` 进行错误管理
   - 提供详细的错误码和错误信息

4. **测试框架**：
   - 使用 Hypium 进行单元测试
   - 使用 Hamock 进行模拟测试
   - 测试文件位于 `src/test/` 和 `src/ohosTest/` 目录

## 依赖管理

项目依赖：
- `@ohos/hypium: 1.0.24` - 测试框架
- `@ohos/hamock: 1.0.0` - 模拟测试工具
- `asrkit: file:./asrkit` - 本地 ASR 工具包