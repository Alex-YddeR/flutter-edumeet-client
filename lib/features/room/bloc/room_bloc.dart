import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_edumeet/models/room_model.dart';

part 'room_event.dart';
part 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc(RoomModel? roomModel)
      : super(
          RoomState(
            url: 'https://letsmeet.no/?roomId=${roomModel!.roomId}',
          ),
        );

  @override
  Stream<RoomState> mapEventToState(
    RoomEvent event,
  ) async* {
    if (event is RoomSetActiveSpeakerId) {
      yield* _mapRoomSetActiveSpeakerIdToState(event);
    }
  }

  Stream<RoomState> _mapRoomSetActiveSpeakerIdToState(
      RoomSetActiveSpeakerId event) async* {
    yield state.newActiveSpeaker(activeSpeakerId: event.speakerId);
  }
}
