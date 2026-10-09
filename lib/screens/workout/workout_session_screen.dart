import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/daily_stats_service.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/pose_detection_service.dart';
import '../../core/services/push_up_analysis_service.dart';
import '../../core/services/squat_analysis_service.dart';
import '../../core/theme/app_colors.dart';
import 'models/exercise.dart';
import 'widgets/ai_viewfinder_preview.dart';
import 'widgets/push_up_debug_telemetry_card.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Exercise? initialExercise;
  final PoseDetectionService? poseDetectionService;
  final CameraController? cameraController;
  final SquatAnalysisService? squatAnalysisService;
  final PushUpAnalysisService? pushUpAnalysisService;

  const WorkoutSessionScreen({
    super.key,
    this.initialExercise,
    this.poseDetectionService,
    this.cameraController,
    this.squatAnalysisService,
    this.pushUpAnalysisService,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late Exercise _selectedExercise;
  bool _isStarted = false;
  int _repCount = 0;
  String _formStatus = 'Ready';
  int _secondsElapsed = 0;
  Timer? _timer;
  bool _isWorkoutRecorded = false;

  Future<void> _completeWorkoutSession() async {
    if (_isWorkoutRecorded) return;
    if (_repCount == 0 && _secondsElapsed == 0) return;
    _isWorkoutRecorded = true;

    final durationMinutes = (_secondsElapsed / 60).round();

    await DailyStatsService.instance.recordWorkoutCompleted(
      durationMinutes: durationMinutes,
      totalReps: _repCount,
      caloriesBurned: 0,
    );

    await GamificationService.instance.recordWorkoutCompleted(
      workoutId: _selectedExercise.id,
      reps: _repCount,
    );
  }

  // Real AI Pose Detection & Camera properties
  late final PoseDetectionService _poseDetectionService;
  late final bool _isCustomPoseService;
  late final SquatAnalysisService _squatAnalysisService;
  late final bool _isCustomSquatService;
  late final PushUpAnalysisService _pushUpAnalysisService;
  late final bool _isCustomPushUpService;
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  bool _isStreamRunning = false;
  SquatLandmarks? _currentLandmarks;
  PushUpLandmarks? _currentPushUpLandmarks;

  @override
  void initState() {
    super.initState();
    _selectedExercise =
        widget.initialExercise ?? Exercise.sampleExercises.first;

    _isCustomPoseService = widget.poseDetectionService != null;
    _poseDetectionService =
        widget.poseDetectionService ?? PoseDetectionService();

    _isCustomSquatService = widget.squatAnalysisService != null;
    _squatAnalysisService =
        widget.squatAnalysisService ?? SquatAnalysisService();

    _isCustomPushUpService = widget.pushUpAnalysisService != null;
    _pushUpAnalysisService =
        widget.pushUpAnalysisService ?? PushUpAnalysisService();

    _poseDetectionService.squatLandmarksNotifier.addListener(
      _onSquatLandmarksUpdated,
    );
    _poseDetectionService.pushUpLandmarksNotifier.addListener(
      _onPushUpLandmarksUpdated,
    );
    _poseDetectionService.poseStatusNotifier.addListener(_onPoseStatusUpdated);
    _squatAnalysisService.repCountNotifier.addListener(_onSquatRepCountChanged);
    _squatAnalysisService.feedbackNotifier.addListener(_onSquatFeedbackChanged);
    _pushUpAnalysisService.repCountNotifier.addListener(
      _onPushUpRepCountChanged,
    );
    _pushUpAnalysisService.feedbackNotifier.addListener(
      _onPushUpFeedbackChanged,
    );

    if (widget.cameraController != null) {
      _cameraController = widget.cameraController;
      _isCameraInitialized = _cameraController!.value.isInitialized;
    } else {
      _initCamera();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _completeWorkoutSession();
    _poseDetectionService.squatLandmarksNotifier.removeListener(
      _onSquatLandmarksUpdated,
    );
    _poseDetectionService.pushUpLandmarksNotifier.removeListener(
      _onPushUpLandmarksUpdated,
    );
    _poseDetectionService.poseStatusNotifier.removeListener(
      _onPoseStatusUpdated,
    );
    _squatAnalysisService.repCountNotifier.removeListener(
      _onSquatRepCountChanged,
    );
    _squatAnalysisService.feedbackNotifier.removeListener(
      _onSquatFeedbackChanged,
    );
    _pushUpAnalysisService.repCountNotifier.removeListener(
      _onPushUpRepCountChanged,
    );
    _pushUpAnalysisService.feedbackNotifier.removeListener(
      _onPushUpFeedbackChanged,
    );
    if (!_isCustomPoseService) {
      _poseDetectionService.dispose();
    }
    if (!_isCustomSquatService) {
      _squatAnalysisService.dispose();
    }
    if (!_isCustomPushUpService) {
      _pushUpAnalysisService.dispose();
    }
    _stopImageStreamIfNeeded();
    if (widget.cameraController == null) {
      _cameraController?.dispose();
    }
    super.dispose();
  }

  void _onSquatLandmarksUpdated() {
    if (!mounted) return;
    final squatLandmarks = _poseDetectionService.squatLandmarksNotifier.value;
    if (identical(_currentLandmarks, squatLandmarks)) return;
    setState(() {
      _currentLandmarks = squatLandmarks;
    });

    if (_isStarted && _selectedExercise.id == 'ex_squats') {
      _squatAnalysisService.processLandmarks(squatLandmarks);
    }
  }

  void _onPushUpLandmarksUpdated() {
    if (!mounted) return;
    final pushUpLandmarks = _poseDetectionService.pushUpLandmarksNotifier.value;
    if (identical(_currentPushUpLandmarks, pushUpLandmarks)) return;
    setState(() {
      _currentPushUpLandmarks = pushUpLandmarks;
    });

    if (_isStarted && _selectedExercise.id == 'ex_pushups') {
      _pushUpAnalysisService.processLandmarks(pushUpLandmarks);
    }
  }

  void _onSquatRepCountChanged() {
    if (!mounted || _selectedExercise.id != 'ex_squats') return;
    setState(() {
      _repCount = _squatAnalysisService.repCount;
    });
  }

  void _onPushUpRepCountChanged() {
    if (!mounted || _selectedExercise.id != 'ex_pushups') return;
    setState(() {
      _repCount = _pushUpAnalysisService.repCount;
    });
  }

  void _onSquatFeedbackChanged() {
    if (!mounted || !_isStarted || _selectedExercise.id != 'ex_squats') return;
    setState(() {
      _formStatus = _squatAnalysisService.feedback;
    });
  }

  void _onPushUpFeedbackChanged() {
    if (!mounted || !_isStarted || _selectedExercise.id != 'ex_pushups') return;
    setState(() {
      _formStatus = _pushUpAnalysisService.feedback;
    });
  }

  void _onPoseStatusUpdated() {
    if (!mounted) return;
    final status = _poseDetectionService.poseStatusNotifier.value;
    if (!_isStarted) {
      setState(() {
        _formStatus = status;
      });
    }
  }

  bool get _isTestingEnvironment {
    final typeName = WidgetsBinding.instance.runtimeType.toString();
    return typeName.contains('Test') ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  Future<void> _initCamera() async {
    // In headless test environments (flutter test), skip native platform channel calls
    if (_isTestingEnvironment) {
      return;
    }

    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _isPermissionDenied = true;
            _isCameraInitialized = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isPermissionDenied = false;
        });
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('GENFIT: No cameras found on device');
        return;
      }

      _availableCameras = cameras;

      // Prefer front camera for selfie exercise tracking
      final int frontIndex = cameras.indexWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );
      _selectedCameraIndex = frontIndex >= 0 ? frontIndex : 0;

      await _setupCameraController(_availableCameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('GENFIT: Camera init exception: $e');
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    final prevController = _cameraController;
    if (prevController != null && widget.cameraController == null) {
      await _stopImageStreamIfNeeded();
      await prevController.dispose();
      _cameraController = null;
    }

    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
      });

      // Start stream immediately so AI viewfinder visualizes pose landmarks in real time
      _startImageStreamIfNeeded();
    } catch (e) {
      debugPrint('GENFIT: CameraController initialization error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_availableCameras.length < 2) return;
    _poseDetectionService.clearLandmarks();
    if (mounted) {
      setState(() {
        _currentLandmarks = null;
        _currentPushUpLandmarks = null;
      });
    }
    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    await _setupCameraController(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> _startImageStreamIfNeeded() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isStreamRunning) {
      return;
    }

    try {
      _isStreamRunning = true;
      await _cameraController!.startImageStream((CameraImage image) {
        if (!mounted) return;
        final camDesc = _cameraController?.description;
        if (camDesc == null) return;
        _poseDetectionService.processCameraImage(image: image, camera: camDesc);
      });
    } catch (e) {
      debugPrint('GENFIT: Failed to start image stream: $e');
      _isStreamRunning = false;
    }
  }

  Future<void> _stopImageStreamIfNeeded() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        !_isStreamRunning) {
      return;
    }

    try {
      _isStreamRunning = false;
      await _cameraController!.stopImageStream();
    } catch (e) {
      debugPrint('GENFIT: Failed to stop image stream: $e');
    } finally {
      _poseDetectionService.clearLandmarks();
      if (mounted) {
        setState(() {
          _currentLandmarks = null;
          _currentPushUpLandmarks = null;
        });
      }
    }
  }

  void _toggleStartStop() {
    setState(() {
      if (_isStarted) {
        // Stop / Pause session
        _isStarted = false;
        _formStatus = 'Ready';
        _timer?.cancel();
        _completeWorkoutSession();
        _poseDetectionService.clearLandmarks();
        _currentLandmarks = null;
        _currentPushUpLandmarks = null;
      } else {
        // Start session
        _isStarted = true;
        if (_selectedExercise.id == 'ex_pushups') {
          _formStatus =
              _currentPushUpLandmarks?.hasSufficientPushUpPoints == true
              ? 'Top position • Ready'
              : 'Get into position';
        } else {
          _formStatus = _currentLandmarks?.hasSufficientSquatPoints == true
              ? 'Full Body Detected • Ready'
              : 'Tracking • Good Form';
        }
        _startTimer();
        _startImageStreamIfNeeded();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    if (_isTestingEnvironment) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _incrementRep() {
    if (!_isStarted) return;
    if (_selectedExercise.id == 'ex_pushups') {
      _pushUpAnalysisService.incrementRep();
    } else {
      _squatAnalysisService.incrementRep();
    }
  }

  void _selectExercise(Exercise exercise) {
    if (_selectedExercise.id == exercise.id) return;
    _poseDetectionService.clearLandmarks();
    setState(() {
      _selectedExercise = exercise;
      _currentLandmarks = null;
      _currentPushUpLandmarks = null;
      _repCount = 0;
      _secondsElapsed = 0;
      _isStarted = false;
      _isWorkoutRecorded = false;
      _formStatus = 'Ready';
      _timer?.cancel();
      _stopImageStreamIfNeeded();
      _squatAnalysisService.reset();
      _pushUpAnalysisService.reset();
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _completeWorkoutSession();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () async {
              await _completeWorkoutSession();
              if (context.mounted) Navigator.of(context).pop();
            },
            tooltip: 'Exit Session',
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Workout Session',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              Text(
                _selectedExercise.name,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'Reset Reps',
              onPressed: () {
                setState(() {
                  _repCount = 0;
                  _secondsElapsed = 0;
                  _formStatus = 'Ready';
                  _isStarted = false;
                  _isWorkoutRecorded = false;
                  _timer?.cancel();
                  _stopImageStreamIfNeeded();
                  _squatAnalysisService.reset();
                  _pushUpAnalysisService.reset();
                });
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise Switcher Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: Exercise.sampleExercises.map((ex) {
                    final isSelected = ex.id == _selectedExercise.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        onSelected: (_) => _selectExercise(ex),
                        label: Text(ex.name),
                        avatar: Icon(
                          ex.icon,
                          size: 16,
                          color: isSelected
                              ? Colors.black
                              : AppColors.textSecondaryDark,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevatedDark,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.black
                              : AppColors.textPrimaryDark,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.cardBorderDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // 1. Workout Preview Area with AI Viewfinder & Camera
              AiViewfinderPreview(
                isTracking: _isStarted,
                exercise: _selectedExercise,
                formStatus: _formStatus,
                cameraController: _cameraController,
                isCameraInitialized: _isCameraInitialized,
                isPermissionDenied: _isPermissionDenied,
                onRequestPermission: _initCamera,
                onFlipCamera: _availableCameras.length > 1 ? _flipCamera : null,
                squatLandmarks: _currentLandmarks,
                pushUpLandmarks: _currentPushUpLandmarks,
              ),
              const SizedBox(height: 14),

              // Temporary Real-Time Push-Up AI Diagnostics (Diagnostic-only, easily removable)
              if (_selectedExercise.id == 'ex_pushups') ...[
                PushUpDebugTelemetryCard(service: _pushUpAnalysisService),
                const SizedBox(height: 14),
              ],

              // 2. Selected Exercise Detail Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selectedExercise.icon,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _selectedExercise.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevatedDark,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _selectedExercise.category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '💡 Tip: ${_selectedExercise.formHint}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryDark,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Telemetry Indicators (Dominant Rep Counter, Form Status, Duration)
              Row(
                children: [
                  // Rep Counter (Visually Dominant Athlete Hero Metric)
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isStarted
                              ? AppColors.primary
                              : AppColors.cardBorderDark,
                          width: _isStarted ? 1.5 : 1.0,
                        ),
                        boxShadow: _isStarted
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REP COUNTER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_repCount',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: -1.0,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedExercise.isTimed
                                    ? '/ ${_selectedExercise.defaultDurationSeconds}s'
                                    : '/ ${_selectedExercise.defaultReps}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Form Status with Dynamic Coaching Visuals
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevatedDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isStarted
                              ? (_formStatus.contains('Good')
                                    ? AppColors.primary.withValues(alpha: 0.6)
                                    : AppColors.accentOrange.withValues(
                                        alpha: 0.5,
                                      ))
                              : AppColors.cardBorderDark,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FORM STATUS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isStarted
                                      ? (_formStatus.contains('Good')
                                            ? AppColors.primary
                                            : (_formStatus.contains(
                                                        'controlled',
                                                      ) ||
                                                      _formStatus.contains(
                                                        'camera',
                                                      ) ||
                                                      _formStatus.contains(
                                                        'visible',
                                                      ) ||
                                                      _formStatus.contains(
                                                        'lower',
                                                      ) ||
                                                      _formStatus.contains(
                                                        'aligned',
                                                      ) ||
                                                      _formStatus.contains(
                                                        'Stand',
                                                      )
                                                  ? AppColors.accentOrange
                                                  : AppColors.accentCyan))
                                      : AppColors.accentYellow,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_isStarted &&
                                                      _formStatus.contains(
                                                        'Good',
                                                      )
                                                  ? AppColors.primary
                                                  : AppColors.accentOrange)
                                              .withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formStatus,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _isStarted
                                        ? (_formStatus.contains('Good')
                                              ? AppColors.primary
                                              : AppColors.textPrimaryDark)
                                        : AppColors.accentYellow,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Elapsed: ${_formatDuration(_secondsElapsed)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Start / Stop Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _toggleStartStop,
                  icon: Icon(
                    _isStarted ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 24,
                  ),
                  label: Text(
                    _isStarted ? 'Stop Workout' : 'Start AI Workout',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStarted
                        ? AppColors.accentRed
                        : AppColors.primary,
                    foregroundColor: _isStarted ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              // Optional Demo Rep Button while active
              if (_isStarted) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _incrementRep,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Simulate AI Counted Rep (+1)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // 5. Short explanation of future AI camera tracking
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentCyan.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.accentCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Future AI Camera Tracking',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentCyan,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'In the upcoming production release, GenFit will use on-device MoveNet / MediaPipe computer vision through your camera. It will track 17 body skeletal landmarks in real-time to automatically count reps and give live posture corrections with 100% on-device privacy.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryDark,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
