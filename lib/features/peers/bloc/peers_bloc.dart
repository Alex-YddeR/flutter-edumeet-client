import 'dart:async';
import 'dart:developer';
import 'package:collection/collection.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_edumeet/features/peers/enitity/peer.dart';
import 'package:flutter_edumeet/features/media_devices/bloc/media_devices_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

part 'peers_event.dart';
part 'peers_state.dart';

class PeersBloc extends Bloc<dynamic, PeersState> {
  final MediaDevicesBloc mediaDevicesBloc;
  String selectedOutputId = '';
  PeersBloc({required this.mediaDevicesBloc}) : super(PeersState()) {
    // if (mediaDevicesBloc.state.selectedAudioOutput?.deviceId != null) {
    //   selectedOutputId = mediaDevicesBloc.state.selectedAudioOutput!.deviceId;
    // }
    //
    // mediaDevicesBloc.stream.listen((event) {
    //   state.peers.values.forEach((p) {
    //     final String? deviceId = event.selectedAudioOutput?.deviceId;
    //     if (deviceId != null) {
    //       selectedOutputId = deviceId;
    //       p.renderer?.audioOutput = selectedOutputId;
    //     }
    //   });
    // });
  }

  @override
  Stream<PeersState> mapEventToState(
    dynamic event,
  ) async* {
    if (event is PeerAdd) {
      yield* _mapPeerAddToState(event);
    } else if (event is PeerAddShareScreen) {
      yield* _mapPeerAddShareScreenToState(event);
    } else if (event is PeerRemove) {
      yield* _mapPeerRemoveToState(event);
    } else if (event is PeerRemoveShareScreen) {
      yield* _mapPeerPeerRemoveShareScreenToState(event);
    } else if (event is PeerAddConsumer) {
      yield* _mapConsumerAddToState(event);
    } else if (event is PeerAddConsumerShareScreen) {
      yield* _mapConsumerAddShareScreenToState(event);
    } else if (event is PeerRemoveConsumer) {
      yield* _mapConsumerRemoveToState(event);
    } else if (event is PeerRemoveConsumerShareScreen) {
      yield* _mapConsumerRemoveShareScreenToState(event);
    } else if (event is PeerPausedConsumer) {
      yield* _mapPeerPausedConsumer(event);
    } else if (event is PeerResumedConsumer) {
      yield* _mapPeerResumedConsumer(event);
    } else if (event is PeerchangeDisplayNameConsumer) {
      yield* _mapPeerchangeDisplayNameConsumer(event);
    }
  }

  @override
  void onTransition(Transition<dynamic, PeersState> transition) {
    log('onTransition: $transition');
    super.onTransition(transition);
  }

  Stream<PeersState> _mapPeerAddToState(PeerAdd event) async* {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    final Peer newPeer = Peer.fromMap(event.newPeer);
    newPeers[newPeer.id] = newPeer;

    yield PeersState.copy(state, peers: newPeers);
  }

  Stream<PeersState> _mapPeerAddShareScreenToState(
      PeerAddShareScreen event) async* {
    final Map<String, Peer> shareScreenPeer =
        Map<String, Peer>.of(state.shareScreenPeer);
    final Peer newPeer = Peer.fromMap(event.newPeer);
    shareScreenPeer[newPeer.id] = newPeer;

    yield PeersState.copy(state, shareScreenPeer: shareScreenPeer);
  }

  Stream<PeersState> _mapPeerRemoveToState(PeerRemove event) async* {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    newPeers.remove(event.peerId);

    yield PeersState.copy(state, peers: newPeers);

    //TODO: Emiter event peers-bloc-participant-left
  }

  Stream<PeersState> _mapPeerPeerRemoveShareScreenToState(
      PeerRemoveShareScreen event) async* {
    final Map<String, Peer> shareScreenPeer =
        Map<String, Peer>.of(state.shareScreenPeer);
    // final String key = shareScreenPeer.keys.elementAt(0);
    shareScreenPeer.remove(event.peerId);

    yield PeersState.copy(state, shareScreenPeer: shareScreenPeer);
  }

  Stream<PeersState> _mapConsumerAddToState(PeerAddConsumer event) async* {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    if (kIsWeb) {
      if (newPeers[event.peerId]?.renderer == null) {
        newPeers[event.peerId] =
            newPeers[event.peerId]!.copyWith(renderer: RTCVideoRenderer());
        await newPeers[event.peerId]!.renderer!.initialize();
      }

      if (event.consumer.kind == 'video') {
        newPeers[event.peerId] =
            newPeers[event.peerId]!.copyWith(video: event.consumer);
        newPeers[event.peerId]!.renderer!.srcObject =
            newPeers[event.peerId]!.video!.stream;
      }

      if (event.consumer.kind == 'audio') {
        newPeers[event.peerId] =
            newPeers[event.peerId]!.copyWith(audio: event.consumer);
        if (newPeers[event.peerId]!.video == null) {
          newPeers[event.peerId]!.renderer!.srcObject =
              newPeers[event.peerId]!.audio!.stream;
        }
      }
    } else {
      // if (newPeers[event.peerId]?.renderer == null) {
      //   newPeers[event.peerId] =
      //       newPeers[event.peerId]!.copyWith(renderer: RTCVideoRenderer());
      //   //Create new renderer for the camera
      //   await newPeers[event.peerId]!.renderer!.initialize();
      // }

      if (event.consumer.kind == 'video') {
        newPeers[event.peerId] = newPeers[event.peerId]!.copyWith(
          renderer: RTCVideoRenderer(),
          video: event.consumer,
        );
        await newPeers[event.peerId]!.renderer!.initialize();
        // newPeers[event.peerId] =
        //     newPeers[event.peerId]!.copyWith(video: event.consumer);
        newPeers[event.peerId]!.renderer!.srcObject =
            newPeers[event.peerId]!.video!.stream;
      } else {
        log('event.consumer.paused:${event.consumer.paused}');
        newPeers[event.peerId] = newPeers[event.peerId]!.copyWith(
          audio: event.consumer,
        );
      }
    }

    yield PeersState.copy(state, peers: newPeers);
  }

  Stream<PeersState> _mapConsumerAddShareScreenToState(
      PeerAddConsumerShareScreen event) async* {
    final Map<String, Peer> shareScreenPeer =
        Map<String, Peer>.of(state.shareScreenPeer);
    // final String key = shareScreenPeer.keys.elementAt(0);

    if (kIsWeb) {
      if (shareScreenPeer[event.peerId]?.renderer == null) {
        shareScreenPeer[event.peerId] = shareScreenPeer[event.peerId]!
            .copyWith(renderer: RTCVideoRenderer());
        await shareScreenPeer[event.peerId]!.renderer!.initialize();
      }

      if (event.consumer.kind == 'video') {
        shareScreenPeer[event.peerId] =
            shareScreenPeer[event.peerId]!.copyWith(video: event.consumer);
        shareScreenPeer[event.peerId]!.renderer!.srcObject =
            shareScreenPeer[event.peerId]!.video!.stream;
      }

      if (event.consumer.kind == 'audio') {
        shareScreenPeer[event.peerId] =
            shareScreenPeer[event.peerId]!.copyWith(audio: event.consumer);
        if (shareScreenPeer[event.peerId]!.video == null) {
          shareScreenPeer[event.peerId]!.renderer!.srcObject =
              shareScreenPeer[event.peerId]!.audio!.stream;
        }
      }
    } else {
      if (event.consumer.kind == 'video') {
        shareScreenPeer[event.peerId] = shareScreenPeer[event.peerId]!.copyWith(
          renderer: RTCVideoRenderer(),
          video: event.consumer,
        );
        await shareScreenPeer[event.peerId]!.renderer!.initialize();
        // newPeers[event.peerId]!.renderer!.audioOutput = selectedOutputId;
        shareScreenPeer[event.peerId]!.renderer!.srcObject =
            shareScreenPeer[event.peerId]!.video!.stream;
      } else {
        shareScreenPeer[event.peerId] = shareScreenPeer[event.peerId]!.copyWith(
          audio: event.consumer,
        );
      }
    }

    yield PeersState.copy(state, shareScreenPeer: shareScreenPeer);
  }

  Stream<PeersState> _mapConsumerRemoveToState(
      PeerRemoveConsumer event) async* {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    final Peer? peer = newPeers.values
        .firstWhereOrNull((p) => p.consumers.contains(event.consumerId));

    if (peer != null) {
      if (kIsWeb) {
        if (peer.audio?.id == event.consumerId) {
          final consumer = peer.audio;
          if (peer.video == null) {
            final renderer = newPeers[peer.id]?.renderer!;
            newPeers[peer.id] = newPeers[peer.id]!.removeAudioAndRenderer();
            yield PeersState.copy(state, peers: newPeers);
            await Future.delayed(Duration(microseconds: 300));
            await renderer?.dispose();
          } else {
            newPeers[peer.id] = newPeers[peer.id]!.removeAudio();
            yield PeersState.copy(state, peers: newPeers);
          }
          await consumer?.close();
        } else if (peer.video?.id == event.consumerId) {
          final consumer = peer.audio;
          if (peer.audio != null) {
            newPeers[peer.id]!.renderer!.srcObject =
                newPeers[peer.id]!.audio!.stream;
            newPeers[peer.id] = newPeers[peer.id]!.removeVideo();
            yield PeersState.copy(state, peers: newPeers);
          } else {
            final renderer = newPeers[peer.id]!.renderer!;
            newPeers[peer.id] = newPeers[peer.id]!.removeVideoAndRenderer();
            yield PeersState.copy(state, peers: newPeers);
            await renderer.dispose();
          }
          await consumer?.close();
        }
      } else {
        if (peer.audio?.id == event.consumerId) {
          final _consumer = peer.audio;
          newPeers[peer.id] = newPeers[peer.id]!.removeAudio();
          yield PeersState.copy(state, peers: newPeers);
          await _consumer?.close();
        } else if (peer.video?.id == event.consumerId) {
          final consumer = peer.video;
          final renderer = peer.renderer;
          newPeers[peer.id] = newPeers[peer.id]!.removeVideoAndRenderer();
          // await _consumer?.close();
          // await _renderer?.dispose();
          // _renderer?.srcObject = null;
          yield PeersState.copy(state, peers: newPeers);
          consumer
              ?.close()
              .then((_) => Future.delayed(Duration(microseconds: 300)))
              .then((_) async => await renderer?.dispose());
        }
      }
    }
  }

  Stream<PeersState> _mapConsumerRemoveShareScreenToState(
      PeerRemoveConsumerShareScreen event) async* {
    final Map<String, Peer> shareScreenPeer =
        Map<String, Peer>.of(state.shareScreenPeer);
    final Peer? peer = shareScreenPeer.values
        .firstWhereOrNull((p) => p.consumers.contains(event.consumerId));

    if (peer != null) {
      if (peer.audio?.id == event.consumerId) {
        final consumer = peer.audio;
        shareScreenPeer[peer.id] = shareScreenPeer[peer.id]!.removeAudio();
        yield PeersState.copy(state, shareScreenPeer: shareScreenPeer);
        await consumer?.close();
      } else if (peer.video?.id == event.consumerId) {
        final consumer = peer.video;
        final renderer = peer.renderer;
        shareScreenPeer[peer.id] =
            shareScreenPeer[peer.id]!.removeVideoAndRenderer();
        // await consumer?.close();
        // await renderer?.dispose();
        consumer
            ?.close()
            .then((_) => Future.delayed(Duration(microseconds: 300)))
            .then((_) async => await renderer?.dispose());
      }
    }
  }

  Stream<PeersState> _mapPeerPausedConsumer(PeerPausedConsumer event) async* {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    final Peer? peer = newPeers.values
        .firstWhereOrNull((p) => p.consumers.contains(event.consumerId));

    if (peer != null) {
      newPeers[peer.id] = newPeers[peer.id]!.copyWith(
        audio: peer.audio!.pauseCopy(),
      );

      yield PeersState.copy(state, peers: newPeers);
    }
  }

  Stream<PeersState> _mapPeerResumedConsumer(PeerResumedConsumer event) async* {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    final Peer? peer = newPeers.values
        .firstWhereOrNull((p) => p.consumers.contains(event.consumerId));

    if (peer != null) {
      newPeers[peer.id] = newPeers[peer.id]!.copyWith(
        audio: peer.audio!.resumeCopy(),
      );

      yield PeersState.copy(state, peers: newPeers);
    }
  }

  Stream<PeersState> _mapPeerchangeDisplayNameConsumer(
      PeerchangeDisplayNameConsumer event) async* {
    final Map<String, Peer> newPeers = Map<String, Peer>.of(state.peers);
    newPeers.update(
      event.peerId,
      (Peer peer) {
        return peer.copyWith(displayName: event.displayName);
      },
    );

    yield PeersState.copy(state, peers: newPeers);
  }

  @override
  Future<void> close() {
    state.peers.values.forEach((peer) {
      peer.renderer?.dispose();
      // peer.renderer?.srcObject = null;
    });
    return super.close();
  }
}
