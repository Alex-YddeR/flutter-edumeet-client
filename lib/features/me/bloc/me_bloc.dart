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
        ));

  @override
  Stream<MeState> mapEventToState(
    MeEvent event,
  ) async* {
    if (event is MeSetWebcamInProgress) {
      yield* _mapMeSetWebCamInProgressToState(event);
    }
  }

  Stream<MeState> _mapMeSetWebCamInProgressToState(
      MeSetWebcamInProgress event) async* {
    yield MeState.copy(state, webcamInProgress: event.progress);
  }
}
