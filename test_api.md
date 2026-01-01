# API 配置测试指南

## 问题排查步骤

### 1. 测试 SharedPreferences 是否工作

在 AI API 配置页面：

1. 填写配置：
   - Base URL: `https://api.302.ai/v1`
   - API Key: 你的真实 API Key
   - Model Name: `gemini-2.5-flash`（推荐使用这个模型）

2. 点击"保存"按钮

3. **查看日志**，应该看到：
```
💾 保存按钮点击
  输入框的值:
    Base URL: https://api.302.ai/v1
    API Key: 已填写 (XX 字符)
    Model Name: gemini-2.5-flash
  ViewModel 的值:
    Base URL: https://api.302.ai/v1
    API Key: 已填写 (XX 字符)
    Model Name: gemini-2.5-flash
✅ 表单验证通过
🔧 开始保存配置...
  Base URL: https://api.302.ai/v1
  API Key: 已填写 (XX 字符)
  Model Name: gemini-2.5-flash
✅ 配置保存成功
```

4. **返回上级页面**
5. **再次进入 AI API 配置页面**
6. **检查输入框是否显示之前保存的值**

如果 ✅ 能正确加载，说明 SharedPreferences 工作正常！
如果 ❌ 输入框是空的，说明配置没有保存成功！

### 2. 测试 API 连接

如果配置保存成功，点击"测试连接"按钮：

**成功时的日志：**
```
正在调用 AI API 识别图纸编号...
✓ AI 识别结果: [返回的内容]
```

**失败时的日志：**
```
✗ AI 识别失败 (401): Unauthorized
或
✗ AI 识别失败: 网络错误
```

## 常见问题

### 问题 1：配置保存失败

**症状**：保存后再进入，输入框是空的

**原因**：应用没有完全重启，SharedPreferences Channel 断开

**解决**：
1. 在 IDE 中点击 **Stop 按钮**（❌）
2. 重新运行应用
3. 不要使用 Hot Restart（🔄）

### 问题 2：测试连接失败

**症状**：提示"连接失败"或"Unauthorized"

**原因**：
1. API Key 错误
2. Base URL 错误
3. 网络问题

**解决**：
1. 检查 API Key 是否正确
2. 检查 Base URL 是否是 `https://api.302.ai/v1`
3. 确保网络连接正常

## 推荐的模型名称

根据 API 文档，支持的模型包括：
- `gemini-2.5-flash` ⭐ 推荐（快速）
- `gemini-2.5-pro`（高质量）
- `gemini-2.0-flash-exp`
- `gemini-1.5-pro`
- `gemini-1.5-flash-exp`
