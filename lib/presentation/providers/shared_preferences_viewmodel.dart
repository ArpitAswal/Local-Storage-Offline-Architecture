import 'package:flutter/material.dart';
import '../../data/services/shared_preferences_service.dart';

/// [SharedPreferencesViewModel] - The state holder for the Shared Preference screen.
/// Implements MVVM Architecture by exposing state variables and operations to the View,
/// updating the UI via [notifyListeners()] instead of [setState()].
class SharedPreferencesViewModel extends ChangeNotifier {
  // Access singleton SharedPreferencesService
  final SharedPreferencesService _service = SharedPreferencesService.instance;

  int _counter = 0;
  int _externalCounter = 0;
  bool _isInitialized = false;

  // Getters to expose read-only state to the View
  int get counter => _counter;
  int get externalCounter => _externalCounter;
  bool get isInitialized => _isInitialized;

  /// Initializes the service asynchronously and reads initial values.
  Future<void> initialize() async {
    // FLOW: Step 1 - Do not re-initialize if already done.
    if (_isInitialized) return;

    try {
      // FLOW: Step 2 - Initialize the underlying SharedPreferences service and migration tools.
      await _service.init();

      // FLOW: Step 3 - Synchronously fetch the cached counter.
      _counter = _service.getCounterWithCache();

      // FLOW: Step 4 - Asynchronously fetch the external counter.
      _externalCounter = await _service.getExternalCounterAsync();

      // FLOW: Step 5 - Mark initialization complete.
      _isInitialized = true;
      
      // FLOW: Step 6 - Trigger UI rebuild.
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing SharedPreferencesViewModel: $e");
    }
  }

  /// Increments the cached counter synchronously (via SharedPreferencesWithCache)
  /// and updates persistent storage in the background.
  Future<void> incrementCounter() async {
    // FLOW: Step 1 - Increment the local state immediately.
    _counter++;
    notifyListeners(); // UI updates instantly due to memory cache speed

    // FLOW: Step 2 - Persist the value to the underlying cached preference.
    await _service.setCounterWithCache(_counter);
  }

  /// Increments the external counter asynchronously (via SharedPreferencesAsync)
  /// with a direct platform round-trip.
  Future<void> incrementExternalCounter() async {
    // FLOW: Step 1 - Fetch the current value from storage, increment it, and write it back.
    final currentVal = await _service.getExternalCounterAsync();
    final newVal = currentVal + 1;
    
    // FLOW: Step 2 - Save directly to the platform storage asynchronously.
    await _service.setExternalCounterAsync(newVal);

    // FLOW: Step 3 - Update viewmodel state and notify the UI of the change.
    _externalCounter = newVal;
    notifyListeners();
  }

  // Benchmark state properties
  bool _isBenchmarking = false;
  double _cacheAvgLatencyUs = 0.0;
  double _asyncAvgLatencyUs = 0.0;
  String _benchmarkExplanation = '';
  bool _benchmarkCompleted = false;

  // Getters for benchmark states
  bool get isBenchmarking => _isBenchmarking;
  double get cacheAvgLatencyUs => _cacheAvgLatencyUs;
  double get asyncAvgLatencyUs => _asyncAvgLatencyUs;
  String get benchmarkExplanation => _benchmarkExplanation;
  bool get benchmarkCompleted => _benchmarkCompleted;

  /// Resets all values in local storage and resets memory state.
  Future<void> resetAll() async {
    // FLOW: Step 1 - Invoke service clear method.
    await _service.clearAll();

    // FLOW: Step 2 - Reset local properties.
    _counter = 0;
    _externalCounter = 0;
    _benchmarkCompleted = false;
    _cacheAvgLatencyUs = 0.0;
    _asyncAvgLatencyUs = 0.0;
    _benchmarkExplanation = '';

    // FLOW: Step 3 - Rebuild listening Widgets.
    notifyListeners();
  }

  /// Runs a high-precision performance benchmark comparing the two APIs.
  Future<void> runPerformanceBenchmark() async {
    // FLOW: Step 1 - Set benchmark state to active and notify views.
    _isBenchmarking = true;
    _benchmarkCompleted = false;
    _benchmarkExplanation = "Initializing benchmark...";
    notifyListeners();

    // Small delay to let the UI render the loading spinner.
    await Future.delayed(const Duration(milliseconds: 300));

    // FLOW: Step 2 - Run Cached Benchmark (1,000 synchronous memory reads)
    _benchmarkExplanation = "Reading 1,000 entries from SharedPreferencesWithCache (Synchronous Cache)...";
    notifyListeners();
    
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      _service.getCounterWithCache();
    }
    stopwatch.stop();
    // Calculate average microsecond latency per read.
    _cacheAvgLatencyUs = stopwatch.elapsedMicroseconds / 1000.0;

    // FLOW: Step 3 - Run Async Benchmark (100 asynchronous platform channel reads)
    _benchmarkExplanation = "Reading 100 entries from SharedPreferencesAsync (Asynchronous Direct Disk)...";
    notifyListeners();

    stopwatch.reset();
    stopwatch.start();
    for (int i = 0; i < 100; i++) {
      await _service.getExternalCounterAsync();
    }
    stopwatch.stop();
    // Calculate average microsecond latency per read.
    _asyncAvgLatencyUs = stopwatch.elapsedMicroseconds / 100.0;

    // FLOW: Step 4 - Calculate the speed multiplier.
    // If cache read was measured at 0 us, set to a nominal minimum (0.1 us) to avoid division by zero.
    final nominalCache = _cacheAvgLatencyUs == 0.0 ? 0.08 : _cacheAvgLatencyUs;
    final double timesFaster = _asyncAvgLatencyUs / nominalCache;

    _benchmarkExplanation = 
        "A single read from SharedPreferencesWithCache takes ~${_cacheAvgLatencyUs.toStringAsFixed(2)} μs, "
        "whereas SharedPreferencesAsync takes ~${_asyncAvgLatencyUs.toStringAsFixed(2)} μs.\n\n"
        "⚡ SharedPreferencesWithCache is approx. ${timesFaster.toStringAsFixed(0)}x faster for reads "
        "because it retrieves values instantly from Dart memory, completely bypassing platform method channels and disk boundaries!";
    
    _isBenchmarking = false;
    _benchmarkCompleted = true;
    notifyListeners();
  }
}
