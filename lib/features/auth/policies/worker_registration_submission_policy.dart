class WorkerRegistrationSubmissionGate {
  bool _busy = false;

  bool get isBusy => _busy;

  bool tryStart() {
    if (_busy) return false;
    _busy = true;
    return true;
  }

  void finish() {
    _busy = false;
  }
}
