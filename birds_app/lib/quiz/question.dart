import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizQuestion {
  final String birdId;
  final String correctName;
  final String audioUrl;
  final List<String> options;

  QuizQuestion({
    required this.birdId,
    required this.correctName,
    required this.audioUrl,
    required this.options,
  });
}

class BirdQuizPage extends StatefulWidget {
  const BirdQuizPage({super.key});

  @override
  State<BirdQuizPage> createState() => _BirdQuizPageState();
}

class _BirdQuizPageState extends State<BirdQuizPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int _score = 0;

  bool _isLoading = true;
  bool _isPlayingAudio = false;
  bool _isTimerRunning = false;

  // Timer Variables
  Timer? _timer;
  int _secondsRemaining = 10;

  // Track user selected answer for current question
  String? _selectedAnswer;

  StreamSubscription? _playerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      final snap = await FirebaseFirestore.instance.collection("birds").get();

      // Extract and filter valid bird records
      List<Map<String, dynamic>> allBirds = snap.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((b) {
            dynamic audio =
                b['audio_url'] ??
                b['audio'] ??
                b['sound_url'] ??
                (b['audios'] != null && (b['audios'] as List).isNotEmpty
                    ? b['audios'][0]
                    : null);

            final hasName =
                b['name'] != null && b['name'].toString().trim().isNotEmpty;
            final hasAudio =
                audio != null && audio.toString().trim().isNotEmpty;

            return hasName && hasAudio;
          })
          .toList();

      debugPrint("Found ${allBirds.length} valid birds with audio.");

      if (allBirds.length < 4) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      allBirds.shuffle();
      final quizBirds = allBirds.take(5).toList();

      List<QuizQuestion> generatedQuestions = [];

      for (var bird in quizBirds) {
        final correctName = bird['name'].toString().trim();
        final audioUrl =
            (bird['audio_url'] ??
                    bird['audio'] ??
                    bird['sound_url'] ??
                    bird['audios'][0])
                .toString();

        List<String> otherNames = allBirds
            .map((b) => b['name'].toString().trim())
            .where((name) => name != correctName)
            .toSet()
            .toList();

        otherNames.shuffle();

        List<String> choices = [correctName, ...otherNames.take(3)];
        choices.shuffle();

        generatedQuestions.add(
          QuizQuestion(
            birdId: bird['id'],
            correctName: correctName,
            audioUrl: audioUrl,
            options: choices,
          ),
        );
      }

      setState(() {
        _questions = generatedQuestions;
        _isLoading = false;
      });

      if (_questions.isNotEmpty) {
        _prepareQuestion();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error initializing quiz: $e");
    }
  }

  void _prepareQuestion() {
    _timer?.cancel();
    _playerCompleteSubscription?.cancel();

    setState(() {
      _secondsRemaining = 10;
      _selectedAnswer = null;
      _isPlayingAudio = false;
      _isTimerRunning = false;
    });

    _audioPlayer.stop();
  }

  void _startTimer() {
    if (_isTimerRunning) return;

    setState(() {
      _isTimerRunning = true;
      _secondsRemaining = 10;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onTimeOut();
      }
    });
  }

  void _playAudio(String url) async {
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        setState(() => _isPlayingAudio = false);
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        setState(() => _isPlayingAudio = true);

        _playerCompleteSubscription?.cancel();
        _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() => _isPlayingAudio = false);
            // Start the 10-second timer right after audio completes
            _startTimer();
          }
        });
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void _onTimeOut() {
    _timer?.cancel();
    _nextQuestion();
  }

  void _selectAnswer(String option) {
    if (_selectedAnswer != null) return; // Prevent multiple taps

    _timer?.cancel();
    _audioPlayer.stop();

    setState(() {
      _selectedAnswer = option;
      if (option == _questions[_currentIndex].correctName) {
        _score++;
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    _timer?.cancel();
    _audioPlayer.stop();
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _prepareQuestion();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    _timer?.cancel();
    _audioPlayer.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 64,
                color: Color(0xFFD6D900),
              ),
              const SizedBox(height: 8),
              Text(
                "Excellent Work!",
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E1A47),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You have completed the Bird Audio Identification Challenge!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inriaSans(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Score",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        Text(
                          "$_score / ${_questions.length}",
                          style: GoogleFonts.fredoka(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E1A47),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "Accuracy",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        Text(
                          "${((_score / _questions.length) * 100).toInt()}%",
                          style: GoogleFonts.fredoka(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E1A47),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // exit page
                    },
                    child: const Text("Exit"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentIndex = 0;
                        _score = 0;
                        _isLoading = true;
                      });
                      _loadQuizData();
                    },
                    child: const Text(
                      "Play Again",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF9C27B0)),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Bird Sound Challenge")),
        body: const Center(
          child: Text("Not enough birds with sound files in database."),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== TOP BAR =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Question ${_currentIndex + 1} of ${_questions.length}",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: const Color(0xFF2E1A47),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: _isTimerRunning
                                ? Colors.redAccent
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isTimerRunning ? "${_secondsRemaining}s" : "--",
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isTimerRunning
                                  ? Colors.redAccent
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ===== PROGRESS BAR =====
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _isTimerRunning ? (_secondsRemaining / 10) : 1.0,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation(
                      !_isTimerRunning
                          ? Colors.purple.shade200
                          : (_secondsRemaining <= 3
                                ? Colors.red
                                : const Color(0xFF9C27B0)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ===== AUDIO CARD =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Listen to the Bird Call",
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          color: const Color(0xFF2E1A47),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isTimerRunning
                            ? "Time running! Choose the correct bird option below."
                            : "Tap play to hear sound. 10s timer starts when finished!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => _playAudio(currentQuestion.audioUrl),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _isPlayingAudio
                                ? Colors.purple.shade100
                                : const Color(0xFFF3E5F5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF9C27B0),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            _isPlayingAudio
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 44,
                            color: const Color(0xFF9C27B0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  "Which bird is this?",
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    color: const Color(0xFF2E1A47),
                  ),
                ),

                const SizedBox(height: 14),

                // ===== MULTIPLE CHOICE OPTIONS =====
                Expanded(
                  child: ListView.separated(
                    itemCount: currentQuestion.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = currentQuestion.options[index];

                      Color buttonBg = Colors.white;
                      Color textColor = const Color(0xFF2E1A47);
                      BorderSide border = BorderSide.none;

                      if (_selectedAnswer != null) {
                        if (option == currentQuestion.correctName) {
                          buttonBg = Colors.green.shade100;
                          textColor = Colors.green.shade900;
                          border = const BorderSide(
                            color: Colors.green,
                            width: 2,
                          );
                        } else if (option == _selectedAnswer) {
                          buttonBg = Colors.red.shade100;
                          textColor = Colors.red.shade900;
                          border = const BorderSide(
                            color: Colors.red,
                            width: 2,
                          );
                        }
                      }

                      return GestureDetector(
                        onTap: () => _selectAnswer(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: buttonBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.fromBorderSide(border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFF3E5F5),
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: GoogleFonts.fredoka(
                                    fontSize: 12,
                                    color: const Color(0xFF9C27B0),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
