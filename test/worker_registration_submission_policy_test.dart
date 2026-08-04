import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/auth/policies/worker_registration_submission_policy.dart';

void main() {
  test('double submit ditolak sampai request registrasi pertama selesai', () {
    final gate = WorkerRegistrationSubmissionGate();

    expect(gate.tryStart(), isTrue);
    expect(gate.isBusy, isTrue);
    expect(gate.tryStart(), isFalse);

    gate.finish();
    expect(gate.isBusy, isFalse);
    expect(gate.tryStart(), isTrue);
  });
}
