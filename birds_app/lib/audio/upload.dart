import 'dart:convert';
import 'dart:io';

import 'package:birds_app/global_language.dart' show currentLanguage;
import 'package:birds_app/services/translation_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// ─────────────────────────────────────────────
//  CONFIG
// ─────────────────────────────────────────────
const String kBaseUrl = 'http://15.207.113.210:8000';

// ─────────────────────────────────────────────
//  DESIGN TOKENS  –  Matching AudioRecordPage
// ─────────────────────────────────────────────
class AppColors {
  static const Color headerText = Color(0xFF2E1A47);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color secondaryPurple = Color(0xFF5E35B1);
  static const Color lightPurpleBg = Color(0xFFF3E5F5);

  static const Color textBody = Color(0xFF2C3E50);
  static const Color textMuted = Color(0xFF757575);

  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerBg = Color(0xFFFFEBEE);

  static const Color birdCrow = Color(0xFF6C7A89);
  static const Color birdCoucal = Color(0xFF9C27B0);
  static const Color birdPeacock = Color(0xFF4A90D9);
  static const Color birdRooster = Color(0xFFE8863A);
}

const Map<String, Color> kBirdColor = {
  'crow': AppColors.birdCrow,
  'greenbilled coucal': AppColors.birdCoucal,
  'peacock': AppColors.birdPeacock,
  'rooster': AppColors.birdRooster,
};

const Map<String, IconData> kBirdIcon = {
  'crow': Icons.nights_stay_outlined,
  'greenbilled coucal': Icons.park_outlined,
  'peacock': Icons.auto_awesome_outlined,
  'rooster': Icons.wb_sunny_outlined,
};

// ─────────────────────────────────────────────
//  WIDGET
// ─────────────────────────────────────────────
class UploadSound extends StatefulWidget {
  const UploadSound({super.key});

  @override
  State<UploadSound> createState() => _UploadSoundState();
}

class _UploadSoundState extends State<UploadSound>
    with TickerProviderStateMixin {
  String? _fileName;
  String? _filePath;
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  Future<String> t(String text) async {
    return await TranslationService.translate(
      text: text,
      targetLang: currentLanguage.value,
    );
  }

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(
      begin: 0.0,
      end: -6.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'ogg', 'flac', 'm4a'],
    );
    if (result == null) return;
    setState(() {
      _fileName = result.files.single.name;
      _filePath = result.files.single.path;
      _result = null;
      _error = null;
    });
  }

  Future<void> _classify() async {
    if (_filePath == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$kBaseUrl/predict');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _filePath!,
          contentType: MediaType('audio', '*'),
        ),
      );
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json.containsKey('error')) {
        setState(() {
          _error = json['error'] as String;
        });
      } else {
        setState(() {
          _result = json;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Unable to reach the server. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String get _bird => (_result?['predicted_bird'] as String?) ?? '';
  double get _confidence => ((_result?['confidence'] as num?)?.toDouble() ?? 0);
  Map<String, dynamic> get _probs =>
      (_result?['all_probabilities'] as Map<String, dynamic>?) ?? {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 204, 140, 252),
              Color.fromARGB(255, 249, 249, 249),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildUploadZone(),
                const SizedBox(height: 16),
                _buildClassifyButton(),
                if (_isLoading) ...[
                  const SizedBox(height: 32),
                  _buildLoading(),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  _buildError(),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  _buildResultCard(),
                  const SizedBox(height: 14),
                  _buildDynamicImageExplanation(),
                  const SizedBox(height: 14),
                  _buildProbabilities(),
                ],
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.purple.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.headerText,
                    size: 20,
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.12),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.file_upload_outlined,
                    color: AppColors.primaryPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BirdVox AI",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.headerText,
                      ),
                    ),
                    Text(
                      "Audio File Identification",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: child,
              ),
              child: const Icon(
                Icons.flutter_dash_rounded,
                size: 38,
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'What bird is singing?',
          style: GoogleFonts.fredoka(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.headerText,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Upload a recording and our AI will identify the species for you.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadZone() {
    final hasFile = _filePath != null;
    return GestureDetector(
      onTap: _pickFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: hasFile ? Colors.purple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasFile ? AppColors.primaryPurple : Colors.transparent,
            width: hasFile ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.lightPurpleBg,
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  hasFile ? Icons.audio_file_rounded : Icons.upload_rounded,
                  key: ValueKey(hasFile),
                  size: 40,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                hasFile ? _fileName! : 'Tap to choose a sound file',
                key: ValueKey(_fileName),
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headerText,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFile
                  ? 'Tap to choose a different file'
                  : 'WAV  ·  MP3  ·  OGG  ·  FLAC  ·  M4A',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassifyButton() {
    final ready = _filePath != null && !_isLoading;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) =>
          Transform.scale(scale: ready ? _pulseAnim.value : 1.0, child: child),
      child: GestureDetector(
        onTap: ready ? _classify : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: ready ? AppColors.primaryPurple : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(18),
            boxShadow: ready
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_rounded,
                size: 20,
                color: ready ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                ready ? 'Identify the Bird!' : 'Choose a file first',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ready ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              valueColor: AlwaysStoppedAnimation(AppColors.primaryPurple),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Listening to the recording…',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.headerText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final color = kBirdColor[_bird] ?? AppColors.primaryPurple;
    final icon = kBirdIcon[_bird] ?? Icons.flutter_dash_rounded;
    final pct = (_confidence * 100).toStringAsFixed(1);
    final display = _bird.isEmpty
        ? 'Unknown Bird'
        : _bird
              .split(' ')
              .map((w) => w[0].toUpperCase() + w.substring(1))
              .join(' ');

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'IDENTIFIED',
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$pct% confident',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: AppColors.secondaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 26, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        display,
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.headerText,
                        ),
                      ),
                      Text(
                        'Bird species detected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                key: ValueKey('conf-$_confidence'),
                tween: Tween(begin: 0, end: _confidence),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor: AppColors.lightPurpleBg,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilities() {
    if (_probs.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALL BIRD SCORES',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryPurple,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ..._probs.entries.map((e) {
            final label = e.key;
            final prob = (e.value as num).toDouble();
            final color = kBirdColor[label] ?? AppColors.primaryPurple;
            final icon = kBirdIcon[label] ?? Icons.flutter_dash_rounded;
            final display = label
                .split(' ')
                .map((w) => w[0].toUpperCase() + w.substring(1))
                .join(' ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                display,
                                style: GoogleFonts.fredoka(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textBody,
                                ),
                              ),
                            ),
                            Text(
                              '${(prob * 100).toStringAsFixed(1)}%',
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('$label-$prob'),
                            tween: Tween(begin: 0, end: prob),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 6,
                              backgroundColor: AppColors.lightPurpleBg,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDynamicImageExplanation() {
    final xai = _result?['explainable_ai'] as Map<String, dynamic>?;
    if (xai == null) return const SizedBox();

    final imageData = xai['gradcam_image'] as String?;
    final layerUsed = xai['grad_cam_layer_used'] as String? ?? '—';
    final description = xai['description'] as String? ?? '';

    // Helper widget to render Base64 Data URL or standard Network Image
    Widget buildGradCamImage(String src) {
      if (src.contains('base64,')) {
        try {
          // 1. Extract raw base64 string after the comma
          final rawBase64 = src.split('base64,').last;

          // 2. Clean out newlines, spaces, and carriage returns
          final cleanedBase64 = rawBase64.replaceAll(RegExp(r'\s+'), '');

          // 3. Normalize Base64 padding if needed
          final normalizedBase64 = base64.normalize(cleanedBase64);

          final base64Bytes = base64Decode(normalizedBase64);

          return Image.memory(
            base64Bytes,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              debugPrint("Base64 Render Error: $error");
              return _buildImageError('Invalid base64 image payload.');
            },
          );
        } catch (e) {
          debugPrint("Base64 Decode Exception: $e");
          return _buildImageError('Failed to decode Base64 image data.');
        }
      } else {
        // Fallback for standard Network URLs
        return Image.network(
          src,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildImageError('Could not fetch heat map from URL ($src).'),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.lightPurpleBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 20,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI EXPLAINABILITY',
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryPurple,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textBody,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.layers_outlined,
            label: 'Target layer',
            value: layerUsed,
          ),
          if (imageData != null && imageData.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: buildGradCamImage(imageData),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.broken_image_outlined, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.secondaryPurple),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textBody),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
