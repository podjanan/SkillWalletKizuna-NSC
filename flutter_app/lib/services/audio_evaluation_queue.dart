import 'dart:async';
import 'dart:collection';

/// Sequential per-device audio evaluation queue.
///
/// Ensures each user's recordings are evaluated one-at-a-time so the local
/// Whisper server is never hit with concurrent requests from the same device.
/// Each [ItemIntroScreen] instance should create its own queue so the queue
/// is automatically GC'd when the screen is disposed.
class AudioEvaluationQueue {
  final Queue<_EvalTask> _pending = Queue();
  bool _isRunning = false;

  /// Enqueue [work] and return a Future that resolves with the evaluation
  /// result.  The work is executed as soon as the queue is free.
  Future<Map<String, dynamic>> enqueue(
      Future<Map<String, dynamic>> Function() work) {
    final completer = Completer<Map<String, dynamic>>();
    _pending.add(_EvalTask(work, completer));
    _drain();
    return completer.future;
  }

  bool get isBusy => _isRunning || _pending.isNotEmpty;

  void _drain() async {
    if (_isRunning || _pending.isEmpty) return;
    _isRunning = true;
    while (_pending.isNotEmpty) {
      final task = _pending.removeFirst();
      try {
        final result = await task.work();
        task.completer.complete(result);
      } catch (e, st) {
        task.completer.completeError(e, st);
      }
    }
    _isRunning = false;
  }
}

class _EvalTask {
  final Future<Map<String, dynamic>> Function() work;
  final Completer<Map<String, dynamic>> completer;
  _EvalTask(this.work, this.completer);
}
