# DeskBuddy 项目文档

## 一、项目背景

**DeskBuddy** 是一款 macOS 桌面宠物应用，为用户提供一个可爱的桌面伴侣，陪伴用户工作。

**开发动机**：
- 类似于桌面宠物软件（如 Shimeji），为桌面增添趣味
- 结合 AI 能力，让宠物可以与用户对话互动
- 程序员专属桌面伴侣，缓解工作压力

**版本历程**：
- v0.1.0 - 基础像素宠物
- v0.2.0 - 添加 AI 对话、情感系统
- v0.3.0 - 鼠标互动优化、颜色配置
- v0.3.4 - 颜色设置修复
- v0.4.0 - 新增 3D 小狗渲染

---

## 二、项目现状

**当前状态**：开发中
- ✅ 2D 像素宠物完整功能
- ✅ 3D 小狗基础渲染
- ✅ 2D/3D 模式切换
- 🔧 3D 动画系统优化

**配置文件位置**：`~/.deskbuddy/config.json`

---

## 三、代码结构

```
DeskBuddy/
├── App/                      # 应用入口
│   ├── AppDelegate.swift     # 单例检查、窗口初始化
│   └── DeskBuddyApp.swift    # @main 入口
│
├── Pet/                      # 宠物渲染模块
│   ├── PetRenderEngine.swift # 渲染引擎协议
│   ├── SpriteKitEngine.swift # 2D 像素引擎
│   ├── SceneKitEngine.swift  # 3D 小狗引擎
│   ├── Dog3DModel.swift      # 低多边形小狗模型
│   ├── Dog3DAnimations.swift # 3D 动画系统
│   ├── PetState.swift        # 状态枚举
│   ├── AnimationRhythm.swift # 动画节奏配置
│   └── SpriteLoader.swift    # 精灵帧加载
│
├── Window/                   # 窗口管理
│   ├── PetWindowController.swift # NSPanel 管理、鼠标事件
│   └── PetWindowView.swift       # SwiftUI 视图、引擎切换
│
├── Emotion/                  # 情感系统
│   ├── EmotionEngine.swift   # 状态计算引擎
│   ├── TimeSignal.swift      # 时间因素
│   ├── IntimacySignal.swift  # 亲密度因素
│   └── SystemSignal.swift    # 系统状态因素
│
├── AI/                       # AI 对话
│   ├── AIBridge.swift        # OpenAI API 调用
│   ├── ConversationStore.swift # 对话记录
│   └── SystemPromptBuilder.swift # 提示词构建
│
├── Voice/                    # 语音功能
│   ├── SpeechRecognizer.swift # 语音识别
│   └── TextToSpeech.swift     # 语音合成
│
├── Config/                   # 配置存储
│   └── ConfigStore.swift     # ~/.deskbuddy/config.json
│
├── UI/                       # 设置界面
│   ├── SettingsView.swift    # 设置面板
│   └── ChatBubbleView.swift  # 聊天框
│
└── Assets.xcassets/          # 资源文件
    ├── cat-sheet.imageset    # 猫咪精灵图
    ├── ghost-sheet.imageset  # 幽灵精灵图
    ├── robot-sheet.imageset  # 机器人精灵图
    └── AppIcon.appiconset    # 应用图标
```

---

## 四、项目目标

| 优先级 | 目标 | 状态 |
|--------|------|------|
| P0 | 3D 小狗渲染 | ✅ 已完成 |
| P0 | 2D/3D 模式切换 | ✅ 已完成 |
| P1 | 小狗颜色自定义 | ✅ 已完成 |
| P1 | 完善动画效果 | 🔧 进行中 |
| P2 | 更多 3D 宠物皮肤 | 待开发 |
| P2 | GLTF 模型支持 | 待开发 |
| P3 | 小红书推广 | 待发布 |

---

## 五、技术栈

| 类别 | 技术 |
|------|------|
| 语言 | Swift 5.9 |
| UI | SwiftUI |
| 2D渲染 | SpriteKit (SKScene, SKSpriteNode, SKAction) |
| 3D渲染 | SceneKit (SCNScene, SCNNode, SCNAction) |
| 窗口 | NSPanel (非激活、无边框、浮动层) |
| 网络 | URLSession + SSE 流式响应 |
| 存储 | ~/.deskbuddy/config.json (JSONSerialization) |
| 语音 | Speech Framework |
| 系统监控 | ProcessInfo (CPU/内存) |
| 鼠标监控 | NSEvent.addLocalMonitor/GlobalMonitor |

**最低支持**：macOS 13.0+

---

## 六、已有功能

### 1. 宠物显示
- ✅ 2D 像素风（猫咪/幽灵/机器人）
- ✅ 3D 低多边形小狗
- ✅ 自定义颜色
- ✅ 大小缩放（2x-8x）

### 2. 动画系统
- ✅ 状态动画：idle/happy/sleepy/anxious/bored/excited/clingy/lying
- ✅ 动画节奏：播放→停顿循环
- ✅ 呼吸效果（idle/sleepy）
- ✅ 尾巴摇摆（happy/clingy）
- ✅ 跳跃动画（excited）

### 3. 情感系统
- ✅ 基于时间自动变化状态
- ✅ CPU 使用率 → 活力
- ✅ 内存压力 → 紧张度
- ✅ 系统空闲时间 → 趴下休息（>3分钟）
- ✅ 亲密度追踪（聊天/点击增加）

### 4. 鼠标互动
- ✅ 鼠标靠近 → 宠物兴奋
- ✅ 拖拽松手 → 翻滚
- ✅ 双击 → 跳跃
- ✅ 眼睛追踪鼠标（2D）
- ✅ 朝向跟随鼠标

### 5. AI 对话
- ✅ OpenAI API 支持
- ✅ SSE 流式响应
- ✅ 对话历史记录
- ✅ 自定义 API 地址/模型
- ✅ 语音输入/输出

### 6. 配置管理
- ✅ JSON 配置文件
- ✅ 实时保存（0.5s 防抖）
- ✅ UserDefaults 迁移

### 7. 应用管理
- ✅ 单例运行（激活现有实例）
- ✅ 菜单栏图标
- ✅ 右键菜单

---

## 七、已知 Bug 与修复

| Bug | 状态 | 描述 |
|-----|------|------|
| 控制台日志过多 | ✅ 已修复 | 移除调试日志 |
| 鼠标互动不触发 | ✅ 已修复 | 距离阈值从150改为250 |
| 颜色设置不生效 | ✅ 已修复 | 使用 ConfigStore.shared |
| 小狗一直摇晃 | ✅ 已修复 | 调整呼吸动画节奏 |
| JSON 斜杠转义 | ✅ 已修复 | 替换 `\/` → `/` |
| 3D模式空白 | ✅ 已修复 | 引擎初始化时机问题 |

---

## 八、关键配置项

配置文件：`~/.deskbuddy/config.json`

```json
{
    "aiBaseURL": "https://api.openai.com/v1",
    "aiModel": "gpt-4o-mini",
    "apiKey": "",
    "petColorHex": "#FFFFFF",
    "petScale": 4,
    "renderMode": "3d",        // "2d" 或 "3d"
    "selectedSkin": "cat-sheet",
    "voiceEnabled": false
}
```

---

## 九、最近开发内容

**2026-04-10 更新**：
- 新增 `PetRenderEngine.swift` - 渲染引擎协议
- 新增 `SceneKitEngine.swift` - 3D 渲染引擎
- 新增 `Dog3DModel.swift` - 低多边形小狗程序生成
- 新增 `Dog3DAnimations.swift` - 3D 动画系统
- 重构 `PetEngine.swift` → `SpriteKitEngine.swift`
- 更新 `PetWindowView.swift` - 支持 2D/3D 切换
- 更新 `ConfigStore.swift` - 新增 renderMode 配置
- 更新 `SettingsView.swift` - 新增渲染模式切换 UI

---

## 十、待解决问题

1. **3D动画优化**
   - 当前呼吸动画可能过于明显
   - 需要更自然的尾巴摇摆

2. **内存优化**
   - 3D模式下内存占用需验证（目标 <50MB）

3. **发布推广**
   - 小红书笔记待发布
   - GitHub Release 待更新