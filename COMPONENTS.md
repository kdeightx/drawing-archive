# 项目组件索引

本文档记录项目中所有需要维护文档的组件。`component-readme` skill 会读取此索引来检查组件文档的完整性。

## 页面组件

| 组件名称 | 文档路径 | 简要描述 |
|---------|---------|---------|
| DrawingScannerPage | lib/comp_src/pages/drawing_scanner_page_guide.md | 图纸扫描和归档页面，负责扫描、识别和存储工程图纸 |
| DrawingSearchPage | lib/comp_src/pages/drawing_search_page_guide.md | 图纸搜索页面，支持关键词搜索和日期筛选 |
| DrawingSettingsPage | lib/comp_src/pages/drawing_settings_page_guide.md | 设置页面，配置应用参数和选项 |
| AiApiConfigPage | lib/comp_src/pages/ai_api_config_page_guide.md | AI API 配置页面，设置 AI 服务接口和密钥 |

## 自定义组件

| 组件名称 | 文档路径 | 简要描述 |
|---------|---------|---------|
| SmartProcessStepper | lib/comp_src/widgets/smart_process_stepper_guide.md | 进度指示器组件，展示处理步骤和当前进度 |
| ImageDisplayCard | lib/comp_src/widgets/image_display_card_guide.md | 图片展示卡片，显示扫描的图纸图片 |
| ActionCard | lib/comp_src/widgets/action_card_guide.md | 操作卡片组件，提供图片选择、编号输入、分页等功能 |
| ActionButtons | lib/comp_src/widgets/action_buttons_guide.md | 操作按钮组件，显示清空、上传识别、保存三个按钮 |
| SearchInputCard | lib/comp_src/widgets/search_input_card_guide.md | 搜索输入框组件，支持关键词输入和搜索触发 |
| SearchResultsList | lib/comp_src/widgets/search_results_list_guide.md | 搜索结果列表组件，展示搜索结果和分页控制 |
| FullScreenImageViewer | lib/comp_src/widgets/full_screen_image_viewer_guide.md | 全屏图片预览组件（自定义手势系统，支持旋转、缩放、无限拖拽、差分算法和智能手势路由） |

## 服务组件

| 组件名称 | 文档路径 | 简要描述 |
|---------|---------|---------|
| DrawingService | lib/comp_src/services/README.md | 图纸业务逻辑服务，提供图纸的增删改查和搜索功能 |

## 视图模型

| 组件名称 | 文档路径 | 简要描述 |
|---------|---------|---------|
| DrawingScannerViewModel | lib/comp_src/view_models/drawing_scanner_view_model_guide.md | 图纸扫描页面的状态管理，管理图片选择、AI 识别、编号输入、旋转控制 |
| AiApiConfigViewModel | lib/comp_src/view_models/ai_api_config_view_model_guide.md | AI API 配置的状态管理，管理 API 配置的持久化、测试连接和验证 |

---

## 使用说明

### 添加新组件

当创建新组件时，请在此文件中添加对应的条目，包含组件名称、文档路径和简要描述。

### 移除组件

当删除组件时，请从此文件中移除对应条目。

### 文档命名规范

- **页面组件**: `{page_name}_guide.md`
- **自定义组件**: `{component_name}_guide.md`
- **服务组件**: `README.md` 或 `{service_name}_guide.md`
- **视图模型**: `{viewmodel_name}_guide.md`

### 简要描述规范

- 用一句话概括组件的主要职责
- 描述应该简洁明了，通常在 10-20 字之间
- 格式："{组件类型}，{主要功能}"

### 获取代码路径

每个组件的 README 文档中的"代码位置"章节记录了对应的代码文件路径。

---

## 维护说明

- 此文件由项目维护者和 AI skills 共同维护
- `component-readme` skill 会读取此文件来检查文档完整性
- `start-work` skill 会通过读取此文件来展示组件列表和描述
- 请确保此文件始终保持最新状态
