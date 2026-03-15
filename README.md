# 图纸归档助手 / DrawingArchive

一款基于 Flutter 开发的机械图纸扫描归档移动应用，利用 AI 技术自动识别图纸编号，实现图纸的智能化管理。

> 适用于小规模的图纸归档需求

## 工作原理

1. **上传图片** - 选择或拍摄机械图纸
2. **AI 识别** - 调用多模态大模型 API 识别图纸编号
3. **重命名归档** - 将图片以图纸编号命名，存储到本地文件夹
4. **快速检索** - 通过搜索文件名快速定位图纸

## ✨ 功能特性

- 📷 **图纸扫描** - 支持拍照或从相册选择图纸图片
- 🤖 **AI 识别** - 自动识别机械图纸编号（如 `1.0101-1100` 格式）
- 📁 **归档管理** - 将图纸按编号重命名并归档存储
- 🔍 **快速搜索** - 按图纸编号搜索已归档图纸
- 🌙 **深色模式** - 支持浅色/深色主题切换
- 🌐 **多语言** - 支持中文/英文界面

## 📱 平台支持

- Android

## 📂 存储位置

归档的图纸存储在设备公共存储目录：

```
/storage/emulated/0/Pictures/DrawingScanner/
```

每张图纸以识别出的编号命名，例如：
- `1.0101-1100.jpg`
- `1.0201-2200.png`

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android Studio

### 安装运行

```bash
# 克隆项目
git clone https://github.com/你的用户名/drawarchive.git
cd drawarchive

# 安装依赖
flutter pub get

# 运行项目
flutter run
```

### 配置 AI API

1. 进入应用后，点击「设置」→「AI API 配置」
2. 填写你的大模型 API 配置：
   - **Base URL**: API 服务地址（如 `https://api.openai.com/v1`）
   - **API Key**: 你的 API 密钥
   - **模型名称**: 支持图片识别的多模态模型（如 `gpt-4o`、`gemini-2.0-flash`）
3. 保存配置后即可使用 AI 识别功能

> ⚠️ 模型必须支持图片识别（多模态）功能

## 🛠️ 技术栈

- **框架**: Flutter / Dart
- **状态管理**: Provider
- **架构模式**: MVVM
- **本地存储**: SharedPreferences + 文件系统
- **国际化**: flutter_localizations / ARB

## 📂 项目结构

```
lib/
├── main.dart                 # 应用入口
├── l10n/                     # 国际化文件
│   ├── app_zh.arb           # 中文翻译
│   └── app_en.arb           # 英文翻译
└── comp_src/                 # 源代码
    ├── pages/               # 页面组件
    ├── widgets/             # UI 组件
    ├── view_models/         # 视图模型
    └── services/            # 服务层
```

## 📄 许可证

MIT License
