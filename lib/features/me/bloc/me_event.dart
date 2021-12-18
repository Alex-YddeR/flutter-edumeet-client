part of 'me_bloc.dart';

abstract class MeEvent extends Equatable {
  const MeEvent();
}

class MeSetWebcamInProgress extends MeEvent {
  final bool progress;

  const MeSetWebcamInProgress({required this.progress});

  @override
  List<Object> get props => [progress];
}

class MePresenterModeAddConsumer extends MeEvent {
  final String presenterConsumnerId;

  const MePresenterModeAddConsumer({required this.presenterConsumnerId});

  @override
  List<Object> get props => [presenterConsumnerId];
}

class MePresenterModeRemoveConsumer extends MeEvent {
  final String presenterConsumnerId;

  const MePresenterModeRemoveConsumer({required this.presenterConsumnerId});

  @override
  List<Object> get props => [presenterConsumnerId];
}
