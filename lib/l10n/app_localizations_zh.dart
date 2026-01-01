// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '机械图纸归档助手';

  @override
  String get scanTitle => '图纸归档';

  @override
  String get searchTitle => '搜索图纸';

  @override
  String get settingsTitle => '设置';

  @override
  String get drawingScanSystem => '图纸扫描入库系统';

  @override
  String get statusWaiting => '等待上传图纸...';

  @override
  String get statusAnalyzing => 'AI识别中...';

  @override
  String get statusReady => '就绪';

  @override
  String get statusStandby => '待机';

  @override
  String get tapToUpload => '点击下方按钮上传图纸';

  @override
  String get supportedFormats => '支持 JPG、PNG 格式';

  @override
  String get camera => '拍照';

  @override
  String get gallery => '相册';

  @override
  String get searchArchived => '搜索已归档图纸';

  @override
  String get drawingNumber => '图纸编号';

  @override
  String get aiRecognized => 'AI已识别';

  @override
  String get placeholderNumber => '例如: 1.0101-1100';

  @override
  String get save => '保存';

  @override
  String get saved => '归档成功';

  @override
  String get saving => '保存中...';

  @override
  String get analyzing => 'AI分析中';

  @override
  String get archiving => '保存中';

  @override
  String get analyzingHint => '正在识别图纸编号...';

  @override
  String get archivingHint => '正在归档...';

  @override
  String get searchPlaceholder => '输入图纸编号搜索...';

  @override
  String get dateRange => '日期范围';

  @override
  String get orderAscending => '正序';

  @override
  String get orderDescending => '倒序';

  @override
  String get status => '状态';

  @override
  String get statusArchived => '已归档';

  @override
  String get languageSetting => '界面语言';

  @override
  String get languageHint => '切换应用显示语言';

  @override
  String get themeSetting => '深色模式';

  @override
  String get themeEnabled => '已开启';

  @override
  String get themeDisabled => '已关闭';

  @override
  String get about => '关于';

  @override
  String get aboutApp => '机械图纸归档助手';

  @override
  String get version => '版本 1.0.0';

  @override
  String get cloudSync => '云端同步';

  @override
  String get cloudSyncHint => '同步图纸到云端';

  @override
  String get storage => '存储管理';

  @override
  String get storageHint => '管理本地缓存';

  @override
  String get help => '帮助与反馈';

  @override
  String get helpHint => '查看使用说明';

  @override
  String get aiApiConfig => 'AI API 配置';

  @override
  String get aiApiConfigHint => '配置第三方大模型 API';

  @override
  String get aiApiConfigDescription => '配置第三方大模型 API 用于图纸编号识别。建议使用 Gemini 3 Flash 或 Gemini 3 Pro，实测识别准确率更高。';

  @override
  String get apiKey => 'API Key';

  @override
  String get apiKeyHint => '请输入 API Key';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get baseUrlHint => '请输入 API 基础地址';

  @override
  String get modelName => '模型名称';

  @override
  String get modelNameHint => '请输入模型名称';

  @override
  String get errorApiKeyRequired => '请输入 API Key';

  @override
  String get errorBaseUrlRequired => '请输入 Base URL';

  @override
  String get errorModelNameRequired => '请输入模型名称';

  @override
  String get saveConfig => '保存配置';

  @override
  String get configSaved => '配置已保存';

  @override
  String get settingsFunction => '设置功能待实现';

  @override
  String get pickImageFailed => '选择图片失败';

  @override
  String get selectImageFirst => '请先选择图片';

  @override
  String get enterNumber => '请输入或确认图纸编号';

  @override
  String get recognizeFailed => 'AI识别失败';

  @override
  String get saveFailed => '保存失败';

  @override
  String saveSuccess(Object count) {
    return '已保存 $count 张图片';
  }

  @override
  String get searchCompleted => '搜索完成';
}
