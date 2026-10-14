enum StartupStep {
  session('Verificando sesión'),
  permissions('Validando permisos'),
  cities('Sincronizando ciudades'),
  register('Confirmando sesión');

  const StartupStep(this.label);
  final String label;
}

enum StepStatus { pending, running, done, failed, skipped }

enum StartupOutcome { running, ready, locked, signedOut, noAccess, failed }

class StartupState {
  const StartupState({
    required this.steps,
    this.outcome = StartupOutcome.running,
    this.message,
  });

  factory StartupState.initial() => StartupState(
        steps: {for (final step in StartupStep.values) step: StepStatus.pending},
      );

  final Map<StartupStep, StepStatus> steps;
  final StartupOutcome outcome;
  final String? message;

  double get progress {
    final done = steps.values
        .where((s) => s == StepStatus.done || s == StepStatus.skipped)
        .length;
    return done / steps.length;
  }

  bool get hasFailed => steps.values.contains(StepStatus.failed);

  StartupState withStep(StartupStep step, StepStatus status) => StartupState(
        steps: {...steps, step: status},
        outcome: outcome,
        message: message,
      );

  StartupState finish(StartupOutcome outcome, {String? message}) =>
      StartupState(steps: steps, outcome: outcome, message: message);
}