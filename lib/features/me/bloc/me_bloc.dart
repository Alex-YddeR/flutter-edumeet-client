import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_edumeet/models/room_model.dart';
import 'package:random_string/random_string.dart';

part 'me_event.dart';
part 'me_state.dart';

class MeBloc extends Bloc<MeEvent, MeState> {
  MeBloc({required RoomModel roomModel})
      : super(MeState(
          webcamInProgress: false,
          shareInProgress: false,
          id: randomAlpha(8),
          displayName: roomModel.name,
          presenterConsumerIds: [],
        ));

  @override
  Stream<MeState> mapEventToState(
    MeEvent event,
  ) async* {
    if (event is MeSetWebcamInProgress) {
      yield* _mapMeSetWebCamInProgressToState(event);
    }
    if (event is MePresenterModeAddConsumer) {
      yield* _mapMePresenterAddConsumerToState(event);
    }
    if (event is MePresenterModeRemoveConsumer) {
      yield* _mapMePresenterRemoveConsumerToState(event);
    }
  }

  Stream<MeState> _mapMeSetWebCamInProgressToState(
      MeSetWebcamInProgress event) async* {
    yield MeState.copy(state, webcamInProgress: event.progress);
  }

  Stream<MeState> _mapMePresenterAddConsumerToState(
      MePresenterModeAddConsumer event) async* {
    final List<String> presenterConsumerIds = state.presenterConsumerIds;
    presenterConsumerIds.add(event.presenterConsumnerId);

    yield MeState.copy(state, presenterConsumerId: presenterConsumerIds);
  }

  Stream<MeState> _mapMePresenterRemoveConsumerToState(
      MePresenterModeRemoveConsumer event) async* {
    final List<String> presenterConsumerIds = state.presenterConsumerIds;
    presenterConsumerIds.remove(event.presenterConsumnerId);

    yield MeState.copy(state, presenterConsumerId: presenterConsumerIds);
  }
}
