/// 发音播放（TTS）使用的第三方平台；off 表示尚未配置服务。
enum TtsPlatform { off, xfyun, youdao }

extension TtsPlatformLabels on TtsPlatform {
  /// 配置页展示的短名称。
  String get label => switch (this) {
    TtsPlatform.off => '未配置',
    TtsPlatform.xfyun => '科大讯飞',
    TtsPlatform.youdao => '有道智云',
  };

  /// 配置页展示的补充说明。
  String get description => switch (this) {
    TtsPlatform.off => '需配置第三方服务后才能合成发音',
    TtsPlatform.xfyun => '讯飞在线语音合成（WebSocket），音色丰富',
    TtsPlatform.youdao => '有道在线语音合成（HTTP），支持美式英式音色',
  };
}
