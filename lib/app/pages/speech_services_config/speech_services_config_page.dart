import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/domain/pronunciation_assessment_config.dart';
import '../../models/domain/pronunciation_assessment_platform.dart';
import '../../models/domain/speech_services_config_run_state.dart';
import '../../models/domain/tts_config.dart';
import '../../models/domain/tts_platform.dart';
import '../../theme/app_theme.dart';
import 'speech_services_config_logic.dart';

/// 集中配置第三方 TTS 与发音评测服务，凭据仅保存于本机私有目录。
class SpeechServicesConfigPage extends StatefulWidget {
  const SpeechServicesConfigPage({super.key});

  @override
  State<SpeechServicesConfigPage> createState() =>
      _SpeechServicesConfigPageState();
}

final class _SpeechServicesConfigPageState
    extends State<SpeechServicesConfigPage> {
  final _ttsXfyunAppId = TextEditingController();
  final _ttsXfyunApiKey = TextEditingController();
  final _ttsXfyunApiSecret = TextEditingController();
  final _ttsXfyunVoice = TextEditingController();
  final _ttsYoudaoAppKey = TextEditingController();
  final _ttsYoudaoAppSecret = TextEditingController();
  final _ttsYoudaoVoice = TextEditingController();
  final _assessmentXfyunAppId = TextEditingController();
  final _assessmentXfyunApiKey = TextEditingController();
  final _assessmentXfyunApiSecret = TextEditingController();
  final _assessmentYoudaoAppKey = TextEditingController();
  final _assessmentYoudaoAppSecret = TextEditingController();

  TtsPlatform _ttsPlatform = TtsPlatform.off;
  PronunciationAssessmentPlatform _assessmentPlatform =
      PronunciationAssessmentPlatform.off;
  int _speed = 50;
  int _volume = 50;
  int _pitch = 50;
  bool _ttsInitialized = false;
  bool _assessmentInitialized = false;
  bool _showTtsSecrets = false;
  bool _showAssessmentSecrets = false;

  @override
  void dispose() {
    _ttsXfyunAppId.dispose();
    _ttsXfyunApiKey.dispose();
    _ttsXfyunApiSecret.dispose();
    _ttsXfyunVoice.dispose();
    _ttsYoudaoAppKey.dispose();
    _ttsYoudaoAppSecret.dispose();
    _ttsYoudaoVoice.dispose();
    _assessmentXfyunAppId.dispose();
    _assessmentXfyunApiKey.dispose();
    _assessmentXfyunApiSecret.dispose();
    _assessmentYoudaoAppKey.dispose();
    _assessmentYoudaoAppSecret.dispose();
    super.dispose();
  }

  void _applyTtsConfig(TtsConfig config) {
    if (_ttsInitialized) {
      return;
    }
    _ttsInitialized = true;
    _ttsPlatform = config.platform;
    _ttsXfyunAppId.text = config.xfyunAppId;
    _ttsXfyunApiKey.text = config.xfyunApiKey;
    _ttsXfyunApiSecret.text = config.xfyunApiSecret;
    _ttsXfyunVoice.text = config.xfyunVoice;
    _ttsYoudaoAppKey.text = config.youdaoAppKey;
    _ttsYoudaoAppSecret.text = config.youdaoAppSecret;
    _ttsYoudaoVoice.text = config.youdaoVoice;
    _speed = config.speed;
    _volume = config.volume;
    _pitch = config.pitch;
  }

  void _applyAssessmentConfig(PronunciationAssessmentConfig config) {
    if (_assessmentInitialized) {
      return;
    }
    _assessmentInitialized = true;
    _assessmentPlatform = config.platform;
    _assessmentXfyunAppId.text = config.xfyunAppId;
    _assessmentXfyunApiKey.text = config.xfyunApiKey;
    _assessmentXfyunApiSecret.text = config.xfyunApiSecret;
    _assessmentYoudaoAppKey.text = config.youdaoAppKey;
    _assessmentYoudaoAppSecret.text = config.youdaoAppSecret;
  }

  TtsConfig _buildTtsConfig() {
    return TtsConfig(
      platform: _ttsPlatform,
      xfyunAppId: _ttsXfyunAppId.text.trim(),
      xfyunApiKey: _ttsXfyunApiKey.text.trim(),
      xfyunApiSecret: _ttsXfyunApiSecret.text.trim(),
      xfyunVoice: _ttsXfyunVoice.text.trim(),
      youdaoAppKey: _ttsYoudaoAppKey.text.trim(),
      youdaoAppSecret: _ttsYoudaoAppSecret.text.trim(),
      youdaoVoice: _ttsYoudaoVoice.text.trim(),
      speed: _speed,
      volume: _volume,
      pitch: _pitch,
    );
  }

  PronunciationAssessmentConfig _buildAssessmentConfig() {
    return PronunciationAssessmentConfig(
      platform: _assessmentPlatform,
      xfyunAppId: _assessmentXfyunAppId.text.trim(),
      xfyunApiKey: _assessmentXfyunApiKey.text.trim(),
      xfyunApiSecret: _assessmentXfyunApiSecret.text.trim(),
      youdaoAppKey: _assessmentYoudaoAppKey.text.trim(),
      youdaoAppSecret: _assessmentYoudaoAppSecret.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.appPageBackground,
        appBar: AppBar(title: const Text('语音服务配置')),
        body: SafeArea(
          top: false,
          child: GetBuilder<SpeechServicesConfigLogic>(
            id: SpeechServicesConfigLogic.updateId,
            builder: (logic) {
              final state = logic.state;
              if (state.phase == SpeechServicesConfigPhase.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.phase == SpeechServicesConfigPhase.error) {
                return _ConfigFailure(onRetry: logic.retry);
              }
              _applyTtsConfig(state.ttsConfig);
              _applyAssessmentConfig(state.assessmentConfig);
              return _SpeechServicesForm(
                ttsPlatform: _ttsPlatform,
                assessmentPlatform: _assessmentPlatform,
                showTtsSecrets: _showTtsSecrets,
                showAssessmentSecrets: _showAssessmentSecrets,
                isSavingTts: state.isSavingTts,
                isSavingAssessment: state.isSavingAssessment,
                ttsErrorCode: state.ttsErrorCode,
                assessmentErrorCode: state.assessmentErrorCode,
                speed: _speed,
                volume: _volume,
                pitch: _pitch,
                ttsXfyunAppId: _ttsXfyunAppId,
                ttsXfyunApiKey: _ttsXfyunApiKey,
                ttsXfyunApiSecret: _ttsXfyunApiSecret,
                ttsXfyunVoice: _ttsXfyunVoice,
                ttsYoudaoAppKey: _ttsYoudaoAppKey,
                ttsYoudaoAppSecret: _ttsYoudaoAppSecret,
                ttsYoudaoVoice: _ttsYoudaoVoice,
                assessmentXfyunAppId: _assessmentXfyunAppId,
                assessmentXfyunApiKey: _assessmentXfyunApiKey,
                assessmentXfyunApiSecret: _assessmentXfyunApiSecret,
                assessmentYoudaoAppKey: _assessmentYoudaoAppKey,
                assessmentYoudaoAppSecret: _assessmentYoudaoAppSecret,
                onTtsPlatformChanged: (value) {
                  setState(() => _ttsPlatform = value);
                },
                onAssessmentPlatformChanged: (value) {
                  setState(() => _assessmentPlatform = value);
                },
                onToggleTtsSecrets: () {
                  setState(() => _showTtsSecrets = !_showTtsSecrets);
                },
                onToggleAssessmentSecrets: () {
                  setState(
                    () => _showAssessmentSecrets = !_showAssessmentSecrets,
                  );
                },
                onSpeedChanged: (value) => setState(() => _speed = value),
                onVolumeChanged: (value) => setState(() => _volume = value),
                onPitchChanged: (value) => setState(() => _pitch = value),
                onSaveTts: () => logic.saveTts(_buildTtsConfig()),
                onSaveAssessment: () =>
                    logic.saveAssessment(_buildAssessmentConfig()),
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _SpeechServicesForm extends StatelessWidget {
  const _SpeechServicesForm({
    required this.ttsPlatform,
    required this.assessmentPlatform,
    required this.showTtsSecrets,
    required this.showAssessmentSecrets,
    required this.isSavingTts,
    required this.isSavingAssessment,
    required this.ttsErrorCode,
    required this.assessmentErrorCode,
    required this.speed,
    required this.volume,
    required this.pitch,
    required this.ttsXfyunAppId,
    required this.ttsXfyunApiKey,
    required this.ttsXfyunApiSecret,
    required this.ttsXfyunVoice,
    required this.ttsYoudaoAppKey,
    required this.ttsYoudaoAppSecret,
    required this.ttsYoudaoVoice,
    required this.assessmentXfyunAppId,
    required this.assessmentXfyunApiKey,
    required this.assessmentXfyunApiSecret,
    required this.assessmentYoudaoAppKey,
    required this.assessmentYoudaoAppSecret,
    required this.onTtsPlatformChanged,
    required this.onAssessmentPlatformChanged,
    required this.onToggleTtsSecrets,
    required this.onToggleAssessmentSecrets,
    required this.onSpeedChanged,
    required this.onVolumeChanged,
    required this.onPitchChanged,
    required this.onSaveTts,
    required this.onSaveAssessment,
  });

  final TtsPlatform ttsPlatform;
  final PronunciationAssessmentPlatform assessmentPlatform;
  final bool showTtsSecrets;
  final bool showAssessmentSecrets;
  final bool isSavingTts;
  final bool isSavingAssessment;
  final String? ttsErrorCode;
  final String? assessmentErrorCode;
  final int speed;
  final int volume;
  final int pitch;
  final TextEditingController ttsXfyunAppId;
  final TextEditingController ttsXfyunApiKey;
  final TextEditingController ttsXfyunApiSecret;
  final TextEditingController ttsXfyunVoice;
  final TextEditingController ttsYoudaoAppKey;
  final TextEditingController ttsYoudaoAppSecret;
  final TextEditingController ttsYoudaoVoice;
  final TextEditingController assessmentXfyunAppId;
  final TextEditingController assessmentXfyunApiKey;
  final TextEditingController assessmentXfyunApiSecret;
  final TextEditingController assessmentYoudaoAppKey;
  final TextEditingController assessmentYoudaoAppSecret;
  final ValueChanged<TtsPlatform> onTtsPlatformChanged;
  final ValueChanged<PronunciationAssessmentPlatform>
  onAssessmentPlatformChanged;
  final VoidCallback onToggleTtsSecrets;
  final VoidCallback onToggleAssessmentSecrets;
  final ValueChanged<int> onSpeedChanged;
  final ValueChanged<int> onVolumeChanged;
  final ValueChanged<int> onPitchChanged;
  final VoidCallback onSaveTts;
  final VoidCallback onSaveAssessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          '第三方服务',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '分别配置发音合成和发音评测；未配置的服务不会使用设备本地能力。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.appTextSecondary,
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          child: _TtsSection(
            platform: ttsPlatform,
            showSecrets: showTtsSecrets,
            isSaving: isSavingTts,
            errorCode: ttsErrorCode,
            speed: speed,
            volume: volume,
            pitch: pitch,
            xfyunAppId: ttsXfyunAppId,
            xfyunApiKey: ttsXfyunApiKey,
            xfyunApiSecret: ttsXfyunApiSecret,
            xfyunVoice: ttsXfyunVoice,
            youdaoAppKey: ttsYoudaoAppKey,
            youdaoAppSecret: ttsYoudaoAppSecret,
            youdaoVoice: ttsYoudaoVoice,
            onPlatformChanged: onTtsPlatformChanged,
            onToggleSecrets: onToggleTtsSecrets,
            onSpeedChanged: onSpeedChanged,
            onVolumeChanged: onVolumeChanged,
            onPitchChanged: onPitchChanged,
            onSave: onSaveTts,
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          child: _AssessmentSection(
            platform: assessmentPlatform,
            showSecrets: showAssessmentSecrets,
            isSaving: isSavingAssessment,
            errorCode: assessmentErrorCode,
            xfyunAppId: assessmentXfyunAppId,
            xfyunApiKey: assessmentXfyunApiKey,
            xfyunApiSecret: assessmentXfyunApiSecret,
            youdaoAppKey: assessmentYoudaoAppKey,
            youdaoAppSecret: assessmentYoudaoAppSecret,
            onPlatformChanged: onAssessmentPlatformChanged,
            onToggleSecrets: onToggleAssessmentSecrets,
            onSave: onSaveAssessment,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.appWarningSurface,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Text(
            '凭据仅保存在本机私有目录，不会随数据备份导出。TTS 会发送单词文本，评测会发送本次录音到所选平台。',
            style: TextStyle(color: theme.appWarning, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

final class _TtsSection extends StatelessWidget {
  const _TtsSection({
    required this.platform,
    required this.showSecrets,
    required this.isSaving,
    required this.errorCode,
    required this.speed,
    required this.volume,
    required this.pitch,
    required this.xfyunAppId,
    required this.xfyunApiKey,
    required this.xfyunApiSecret,
    required this.xfyunVoice,
    required this.youdaoAppKey,
    required this.youdaoAppSecret,
    required this.youdaoVoice,
    required this.onPlatformChanged,
    required this.onToggleSecrets,
    required this.onSpeedChanged,
    required this.onVolumeChanged,
    required this.onPitchChanged,
    required this.onSave,
  });

  final TtsPlatform platform;
  final bool showSecrets;
  final bool isSaving;
  final String? errorCode;
  final int speed;
  final int volume;
  final int pitch;
  final TextEditingController xfyunAppId;
  final TextEditingController xfyunApiKey;
  final TextEditingController xfyunApiSecret;
  final TextEditingController xfyunVoice;
  final TextEditingController youdaoAppKey;
  final TextEditingController youdaoAppSecret;
  final TextEditingController youdaoVoice;
  final ValueChanged<TtsPlatform> onPlatformChanged;
  final VoidCallback onToggleSecrets;
  final ValueChanged<int> onSpeedChanged;
  final ValueChanged<int> onVolumeChanged;
  final ValueChanged<int> onPitchChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '第三方 TTS',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '配置后用于缺少词库音频的发音播放。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.appTextSecondary,
          ),
        ),
        const SizedBox(height: 10),
        RadioGroup<TtsPlatform>(
          groupValue: platform,
          onChanged: (value) {
            if (!isSaving && value != null) {
              onPlatformChanged(value);
            }
          },
          child: Column(
            children: [
              for (final option in TtsPlatform.values)
                RadioListTile<TtsPlatform>(
                  value: option,
                  enabled: !isSaving,
                  title: Text(option.label),
                  subtitle: Text(option.description),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],
          ),
        ),
        if (platform != TtsPlatform.off) ...[
          const Divider(height: 28),
          _SectionHeader(
            title: '平台凭据',
            showSecrets: showSecrets,
            onToggleSecrets: onToggleSecrets,
          ),
          const SizedBox(height: 10),
          if (platform == TtsPlatform.xfyun) ...[
            _CredentialField(
              controller: xfyunAppId,
              label: 'AppID',
              obscure: false,
              showSecrets: showSecrets,
            ),
            const SizedBox(height: 12),
            _CredentialField(
              controller: xfyunApiKey,
              label: 'APIKey',
              obscure: true,
              showSecrets: showSecrets,
            ),
            const SizedBox(height: 12),
            _CredentialField(
              controller: xfyunApiSecret,
              label: 'APISecret',
              obscure: true,
              showSecrets: showSecrets,
            ),
            const SizedBox(height: 12),
            _CredentialField(
              controller: xfyunVoice,
              label: '发音人（vcn）',
              obscure: false,
              showSecrets: showSecrets,
              hint: '如 catherine、henry',
            ),
          ] else ...[
            _CredentialField(
              controller: youdaoAppKey,
              label: '应用 Key',
              obscure: false,
              showSecrets: showSecrets,
            ),
            const SizedBox(height: 12),
            _CredentialField(
              controller: youdaoAppSecret,
              label: '应用 Secret',
              obscure: true,
              showSecrets: showSecrets,
            ),
            const SizedBox(height: 12),
            _CredentialField(
              controller: youdaoVoice,
              label: '发音人（voice）',
              obscure: false,
              showSecrets: showSecrets,
              hint: 'female / male（美式）',
            ),
          ],
          const Divider(height: 28),
          Text(
            '音色参数',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _TtsSlider(label: '语速', value: speed, onChanged: onSpeedChanged),
          _TtsSlider(label: '音量', value: volume, onChanged: onVolumeChanged),
          _TtsSlider(label: '音调', value: pitch, onChanged: onPitchChanged),
        ],
        if (errorCode != null) ...[
          const SizedBox(height: 12),
          Text(
            'TTS 配置保存失败，请检查后重试。',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            child: Text(isSaving ? '正在保存…' : '保存 TTS 配置'),
          ),
        ),
      ],
    );
  }
}

final class _AssessmentSection extends StatelessWidget {
  const _AssessmentSection({
    required this.platform,
    required this.showSecrets,
    required this.isSaving,
    required this.errorCode,
    required this.xfyunAppId,
    required this.xfyunApiKey,
    required this.xfyunApiSecret,
    required this.youdaoAppKey,
    required this.youdaoAppSecret,
    required this.onPlatformChanged,
    required this.onToggleSecrets,
    required this.onSave,
  });

  final PronunciationAssessmentPlatform platform;
  final bool showSecrets;
  final bool isSaving;
  final String? errorCode;
  final TextEditingController xfyunAppId;
  final TextEditingController xfyunApiKey;
  final TextEditingController xfyunApiSecret;
  final TextEditingController youdaoAppKey;
  final TextEditingController youdaoAppSecret;
  final ValueChanged<PronunciationAssessmentPlatform> onPlatformChanged;
  final VoidCallback onToggleSecrets;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '第三方发音评测',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '配置后可在发音练习中录音并获取评分。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.appTextSecondary,
          ),
        ),
        const SizedBox(height: 10),
        RadioGroup<PronunciationAssessmentPlatform>(
          groupValue: platform,
          onChanged: (value) {
            if (!isSaving && value != null) {
              onPlatformChanged(value);
            }
          },
          child: Column(
            children: [
              for (final option in PronunciationAssessmentPlatform.values)
                RadioListTile<PronunciationAssessmentPlatform>(
                  value: option,
                  enabled: !isSaving,
                  title: Text(option.label),
                  subtitle: Text(option.description),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            ],
          ),
        ),
        if (platform != PronunciationAssessmentPlatform.off) ...[
          const Divider(height: 28),
          _SectionHeader(
            title: '平台凭据',
            showSecrets: showSecrets,
            onToggleSecrets: onToggleSecrets,
          ),
          const SizedBox(height: 10),
          if (platform == PronunciationAssessmentPlatform.xfyun) ...[
            _CredentialField(
              controller: xfyunAppId,
              label: 'AppID',
              obscure: false,
              showSecrets: showSecrets,
            ),
            const SizedBox(height: 12),
            _CredentialField(
              controller: xfyunApiKey,
              label: 'APIKey',
              obscure: true,
              showSecrets: showSecrets,
            ),
            const SizedBox(height: 12),
            _CredentialField(
              controller: xfyunApiSecret,
              label: 'APISecret',
              obscure: true,
              showSecrets: showSecrets,
            ),
          ] else ...[
            _CredentialField(
              controller: youdaoAppKey,
              label: '应用 Key',
              obscure: false,
              showSecrets: showSecrets,
            ),
            const SizedBox(height: 12),
            _CredentialField(
              controller: youdaoAppSecret,
              label: '应用 Secret',
              obscure: true,
              showSecrets: showSecrets,
            ),
          ],
        ],
        if (errorCode != null) ...[
          const SizedBox(height: 12),
          Text(
            '评测配置保存失败，请检查后重试。',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            child: Text(isSaving ? '正在保存…' : '保存评测配置'),
          ),
        ),
      ],
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.showSecrets,
    required this.onToggleSecrets,
  });

  final String title;
  final bool showSecrets;
  final VoidCallback onToggleSecrets;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextButton.icon(
          onPressed: onToggleSecrets,
          icon: Icon(
            showSecrets
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
          ),
          label: Text(showSecrets ? '隐藏' : '显示'),
        ),
      ],
    );
  }
}

final class _CredentialField extends StatelessWidget {
  const _CredentialField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.showSecrets,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool showSecrets;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure && !showSecrets,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint ?? '填写 $label',
      ),
    );
  }
}

final class _TtsSlider extends StatelessWidget {
  const _TtsSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '$value',
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: theme.appCardSurface,
      elevation: isDark ? 0 : 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: theme.appBorder),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

final class _ConfigFailure extends StatelessWidget {
  const _ConfigFailure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 50,
              color: Theme.of(context).appTextTertiary,
            ),
            const SizedBox(height: 14),
            Text('配置加载失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('无法读取第三方语音服务配置，请重试。'),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
