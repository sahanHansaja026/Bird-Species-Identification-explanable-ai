import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// Unified Palette matching All_Birds_List
class AppColors {
  static const Color headerText = Color(0xFF2E1A47);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color secondaryPurple = Color(0xFF5E35B1);
  static const Color lightPurpleBg = Color(0xFFF3E5F5);
  static const Color activeRecording = Color(0xFFE53935);
  static const Color recordingBg = Color(0xFFFFEBEE);

  static const Color textBody = Color(0xFF2C3E50);
  static const Color textMuted = Color(0xFF757575);

  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerBg = Color(0xFFFFEBEE);
}

const String kBaseUrl = 'http://16.192.165.191:8000';

class AudioRecordPage extends StatefulWidget {
  const AudioRecordPage({super.key});

  @override
  State<AudioRecordPage> createState() => _AudioRecordPageState();
}

class _AudioRecordPageState extends State<AudioRecordPage>
    with TickerProviderStateMixin {
  final AudioRecorder recorder = AudioRecorder();

  bool isRecording = false;
  bool loading = false;
  String? audioPath;

  Map<String, dynamic>? result;
  String? error;

  // Animation Controllers
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Floating Bird Mascot Animation
    _floatController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulsing Mic Ring Animation for Active Recording
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> startRecording() async {
    if (!await recorder.hasPermission()) {
      setState(() {
        error = "Microphone permission denied";
      });
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/bird_${DateTime.now().millisecondsSinceEpoch}.wav';

    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    _pulseController.repeat(reverse: true);

    setState(() {
      isRecording = true;
      audioPath = path;
      result = null;
      error = null;
    });
  }

  Future<void> stopRecording() async {
    final path = await recorder.stop();
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      isRecording = false;
      audioPath = path;
    });
  }

  Future<void> classifyAudio() async {
    if (audioPath == null) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/predict'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioPath!,
          contentType: MediaType('audio', 'wav'),
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);

      setState(() {
        result = json;
      });
    } catch (e) {
      setState(() {
        error = "Server connection failed";
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    recorder.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

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
                if (loading) ...[const SizedBox(height: 32), _buildLoading()],
                if (error != null) ...[
                  const SizedBox(height: 18),
                  _buildError(),
                ],
                if (result != null) ...[
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
                    Icons.graphic_eq_rounded,
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
                      "Audio Song Identification",
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
          'Record or collect a singing voice bird sound sample and let AI figure out its identity!',
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
    final hasFile = audioPath != null;
    return GestureDetector(
      onTap: isRecording ? stopRecording : startRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: isRecording
              ? AppColors.recordingBg
              : (hasFile ? Colors.purple.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRecording
                ? AppColors.activeRecording
                : (hasFile ? AppColors.primaryPurple : Colors.transparent),
            width: (hasFile || isRecording) ? 2 : 1.5,
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
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: isRecording ? _pulseAnim.value : 1.0,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRecording
                      ? AppColors.activeRecording.withOpacity(0.15)
                      : AppColors.lightPurpleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRecording
                      ? Icons.stop_rounded
                      : (hasFile
                            ? Icons.audiotrack_rounded
                            : Icons.mic_rounded),
                  size: 44,
                  color: isRecording
                      ? AppColors.activeRecording
                      : AppColors.primaryPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isRecording
                  ? 'Listening closely... Tap to Stop!'
                  : (hasFile
                        ? audioPath!.split('/').last
                        : 'Tap to Start Recording'),
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.headerText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              isRecording
                  ? 'Capturing real-time environment audio'
                  : 'Saves automatically to application document storage',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassifyButton() {
    final ready = audioPath != null && !loading && !isRecording;
    return GestureDetector(
      onTap: ready ? classifyAudio : null,
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
              ready ? 'Identify the Bird!' : 'Record a sound first',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ready ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
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
            'Analyzing frequencies…',
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
              error!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final String predictedBird =
        result?['predicted_bird']?.toString() ?? 'Unknown Bird';
    final double confidence =
        (result?['confidence'] as num?)?.toDouble() ?? 0.0;
    final String pct = (confidence * 100).toStringAsFixed(1);

    final display = predictedBird
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
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
                    color: AppColors.lightPurpleBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'IDENTIFIED',
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryPurple,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '$pct% Match',
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
                  decoration: const BoxDecoration(
                    color: AppColors.lightPurpleBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 24,
                    color: AppColors.primaryPurple,
                  ),
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
                        'Primary classification match',
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
              child: LinearProgressIndicator(
                value: confidence,
                minHeight: 10,
                backgroundColor: AppColors.lightPurpleBg,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.primaryPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilities() {
    // Falls back seamlessly whether backend sends 'all_probabilities' or 'probabilities'
    final rawProbs =
        (result?['all_probabilities'] ?? result?['probabilities'])
            as Map<String, dynamic>? ??
        {};
    if (rawProbs.isEmpty) return const SizedBox();

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
            'ALL CANDIDATE SCORES',
            style: GoogleFonts.fredoka(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryPurple,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...rawProbs.entries.map((e) {
            final double val = (e.value as num).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key.toUpperCase(),
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          color: AppColors.textBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(val * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 6,
                      backgroundColor: AppColors.lightPurpleBg,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryPurple,
                      ),
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
    final xai = result?['explainable_ai'] as Map<String, dynamic>?;
    if (xai == null) return const SizedBox();

    final imageData = xai['gradcam_image'] as String?;
    final layerUsed = xai['grad_cam_layer_used'] as String? ?? '—';
    final description = xai['description'] as String? ?? '';

    Widget buildGradCamImage(String src) {
      if (src.startsWith('data:image')) {
        // Render in-memory Base64 Data URL string from FastAPI
        final base64Bytes = base64Decode(src.split(',').last);
        return Image.memory(
          base64Bytes,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildImageError(),
        );
      } else {
        // Fallback for standard HTTP/HTTPS URLs
        return Image.network(
          src,
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _buildImageError(),
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
                'AI INTERPRETATION',
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
            label: 'Target Layer',
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

  Widget _buildImageError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.danger),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not display interpretation map visualization image.',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

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
