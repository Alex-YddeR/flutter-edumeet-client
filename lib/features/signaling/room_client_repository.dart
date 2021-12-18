import 'dart:async';
import 'dart:developer';

import 'package:flutter_edumeet/features/me/bloc/me_bloc.dart';
import 'package:flutter_edumeet/features/media_devices/bloc/media_devices_bloc.dart';
import 'package:flutter_edumeet/features/peers/bloc/peers_bloc.dart';
import 'package:flutter_edumeet/features/peers/enitity/peer.dart';
import 'package:flutter_edumeet/features/producers/bloc/producers_bloc.dart';
import 'package:flutter_edumeet/features/room/bloc/room_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_edumeet/features/signaling/socket_io.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

class RoomClientRepository {
  final ProducersBloc producersBloc;
  final PeersBloc peersBloc;
  final MeBloc meBloc;
  final RoomBloc roomBloc;
  final MediaDevicesBloc mediaDevicesBloc;

  final String roomId;
  final String peerId;
  final String url;
  final String displayName;

  bool _closed = false;

  SocketIO? _socketIo;
  Device? _mediasoupDevice;
  Transport? _sendTransport;
  Transport? _recvTransport;
  bool _produce = false;
  bool _consume = true;
  StreamSubscription<MediaDevicesState>? _mediaDevicesBlocSubscription;
  String? audioInputDeviceId;
  String? audioOutputDeviceId;
  String? videoInputDeviceId;
  // Create local audio/video track.
  MediaStream? _localStream;

  RoomClientRepository({
    required this.producersBloc,
    required this.peersBloc,
    required this.meBloc,
    required this.roomBloc,
    required this.roomId,
    required this.peerId,
    required this.url,
    required this.displayName,
    required this.mediaDevicesBloc,
  }) {
    _mediaDevicesBlocSubscription =
        mediaDevicesBloc.stream.listen((MediaDevicesState state) async {
      if (state.selectedAudioInput != null &&
          state.selectedAudioInput?.deviceId != audioInputDeviceId) {
        await disableMic();
        enableMic();
      }

      if (state.selectedVideoInput != null &&
          state.selectedVideoInput?.deviceId != videoInputDeviceId) {
        await disableWebcam();
        enableWebcam();
      }
    });
  }

  void close() {
    if (_closed) {
      return;
    }

    _socketIo?.close();
    _sendTransport?.close();
    _recvTransport?.close();
    _mediaDevicesBlocSubscription?.cancel();
    _localStream?.dispose();
  }

  /// Disable mic
  Future<void> disableMic() async {
    String micId = producersBloc.state.mic!.id;

    producersBloc.add(ProducerRemove(source: 'mic'));

    try {
      _socketIo!.sendEventEmitter('closeTransport', {'producerId': micId});
    } catch (error) {}
  }

  /// Disable webcam
  Future<void> disableWebcam() async {
    meBloc.add(MeSetWebcamInProgress(progress: true));
    String webcamId = producersBloc.state.webcam!.id;

    producersBloc.add(ProducerRemove(source: 'webcam'));

    try {
      _socketIo!.sendEventEmitter('closeProducer', {'producerId': webcamId});
    } catch (error) {} finally {
      meBloc.add(MeSetWebcamInProgress(progress: false));
    }
  }

  /// Mute mic
  Future<void> muteMic() async {
    producersBloc.add(ProducerPaused(source: 'mic'));

    try {
      _socketIo!.sendEventEmitter(
          'pauseProducer', {'producerId': producersBloc.state.mic!.id});
    } catch (error) {}
  }

  /// unMute mic
  Future<void> unmuteMic() async {
    producersBloc.add(ProducerResumed(source: 'mic'));

    try {
      _socketIo!.sendEventEmitter('resumeProducer', {
        'producerId': producersBloc.state.mic!.id,
      });
    } catch (error) {}
  }

  /// Enable webcam
  void enableWebcam() async {
    if (meBloc.state.webcamInProgress) {
      return;
    }
    meBloc.add(MeSetWebcamInProgress(progress: true));
    if (_mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo) ==
        false) {
      return;
    }
    try {
      // NOTE: prefer using h264
      RtpCodecCapability? codec = _mediasoupDevice!.rtpCapabilities.codecs
          .firstWhere((RtpCodecCapability c) {
        return c.mimeType.toLowerCase() == 'video/vp9' ||
            c.mimeType.toLowerCase() == 'video/vp8';
      },
              // (RtpCodecCapability c) =>
              //     c.mimeType.toLowerCase() == 'video/h264',
              orElse: () =>
                  throw 'desired vp9 codec+configuration is not supported');

      /// Get video input device
      final MediaStreamTrack track = _localStream!.getVideoTracks().first;
      meBloc.add(MeSetWebcamInProgress(progress: true));
      _sendTransport!.produce(
        track: track,
        codecOptions: ProducerCodecOptions(
          videoGoogleStartBitrate: 1000,
        ),
        encodings: kIsWeb
            ? [
                RtpEncodingParameters(
                    scalabilityMode: 'S3T3_KEY', scaleResolutionDownBy: 1.0),
              ]
            : [],
        stream: _localStream!,
        appData: {
          'source': 'webcam',
        },
        source: 'webcam',
        codec: codec,
      );
    } catch (error) {
      // if (videoStream != null) {
      //   await videoStream.dispose();
      // }
    }
  }

  /// Enable mic
  void enableMic() async {
    if (_mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio) ==
        false) {
      return;
    }

    try {
      /// Get audio input device
      final MediaStreamTrack track = _localStream!.getAudioTracks().first;
      _sendTransport!.produce(
        track: track,
        codecOptions: ProducerCodecOptions(opusStereo: 1, opusDtx: 1),
        stream: _localStream!,
        appData: {
          'source': 'mic',
        },
        source: 'mic',
      );
    } catch (error) {
      // if (audioStream != null) {
      //   await audioStream.dispose();
      // }
    }
  }

  /// Prduce Callback
  /// mic
  /// webcam
  void _producerCallback(Producer producer) {
    if (producer.source == 'mic') {
      producer.on('transportclose', () {
        producersBloc.add(ProducerRemove(source: 'mic'));
      });

      producer.on('trackended', () {
        disableMic().catchError((data) {});
      });
    } else if (producer.source == 'webcam') {
      producer.on('transportclose', () {
        producersBloc.add(ProducerRemove(source: 'webcam'));
      });

      producer.on('trackended', () {
        disableWebcam().catchError((data) {});
      });
      meBloc.add(MeSetWebcamInProgress(progress: false));
    }

    producersBloc.add(ProducerAdd(producer: producer));
  }

  void _consumerCallback(Consumer consumer, [dynamic accept]) {
    // consumer.on('transportclose', () {
    //   // consumersBloc.add(ConsumerRemove(consumerId: consumer.id));
    // });
    String peerId = consumer.peerId!;

    // ScalabilityMode scalabilityMode = ScalabilityMode.parse(
    //     consumer.rtpParameters.encodings.first.scalabilityMode);

    try {
      consumer.resume();
      _socketIo!.sendEventEmitter('resumeConsumer', {
        'consumerId': consumer.id,
      });

      final bool check = consumer.appData['source'].toString() == "screen";
      log("map presenter to state: check $check");
      if (consumer.appData['source'].toString() == "screen") {
        peersBloc.add(
            PeerAddConsumerShareScreen(peerId: peerId, consumer: consumer));
        meBloc
            .add(MePresenterModeAddConsumer(presenterConsumnerId: consumer.id));
      } else {
        peersBloc.add(PeerAddConsumer(peerId: peerId, consumer: consumer));
      }
    } catch (error) {
      print(error);
    }
  }

  /// Create a new mediasoup Device.
  Future<MediaStream> createStream() async {
    audioInputDeviceId = mediaDevicesBloc.state.selectedAudioInput!.deviceId;
    videoInputDeviceId = mediaDevicesBloc.state.selectedVideoInput!.deviceId;
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': {
        'optional': [
          {
            'sourceId': audioInputDeviceId,
          },
        ],
      },
      'video': {
        'mandatory': {
          'minWidth':
              '1280', // Provide your own width, height and frame rate here
          'minHeight': '720',
          'minFrameRate': '30',
        },
        'optional': [
          {
            'sourceId': videoInputDeviceId,
          },
        ],
      },
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    return stream;
  }

  /// Join a room
  Future<void> _joinRoom() async {
    try {
      _mediasoupDevice = Device();
      // Get routerRtpCapabilities response Map data from server.

      Map routerRtpCapabilities = await _socketIo!.sendEventEmitterAck(
        'getRouterRtpCapabilities',
        {},
      );

      log('getted getRouterRtpCapabilities: $routerRtpCapabilities');

      ///Load the device with the router RTP capabilities.
      final rtpCapabilities = RtpCapabilities.fromMap(routerRtpCapabilities);
      rtpCapabilities.headerExtensions
          .removeWhere((he) => he.uri == 'urn:3gpp:video-orientation');
      await _mediasoupDevice!.load(routerRtpCapabilities: rtpCapabilities);

      if (_mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeAudio) ==
              true ||
          _mediasoupDevice!.canProduce(RTCRtpMediaType.RTCRtpMediaTypeVideo) ==
              true) {
        _produce = true;
      }

      if (_produce) {
        // Create a transport in the server via socket io client for sending our media through it.
        Map transportInfo =
            await _socketIo!.sendEventEmitterAck('createWebRtcTransport', {
          'forceTcp': false,
          'producing': true,
          'consuming': false,
          'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
        });
        log('getted transportInfo: $transportInfo');

        _sendTransport = _mediasoupDevice!.createSendTransportFromMap(
          transportInfo,
          producerCallback: _producerCallback,
        );

        // Set transport method "connect" event handler connectWebRtcTransport send via socket io client.
        // with params: transportId, dtlsParameters
        // Done in the server, tell our transport.
        // Something was wrong in server side.
        _sendTransport!.on('connect', (Map data) async {
          await _socketIo!
              .sendEventEmitter('connectWebRtcTransport', {
                'transportId': _sendTransport!.id,
                'dtlsParameters': data['dtlsParameters'].toMap(),
              })
              .then(data['callback'])
              .catchError(data['errback']);
        });

        // Set transport "produce" event handler.
        // Here we must communicate our local parameters to our remote transport.
        // Done in the server, pass the response to our transport.
        // Something was wrong in server side.
        _sendTransport!.on('produce', (Map data) async {
          try {
            Map response = await _socketIo!.sendEventEmitterAck(
              'produce',
              {
                'transportId': _sendTransport!.id,
                'kind': data['kind'],
                'rtpParameters': data['rtpParameters'].toMap(),
                if (data['appData'] != null)
                  'appData': Map<String, dynamic>.from(data['appData'])
              },
            );

            data['callback'](response['id']);
          } catch (error) {
            data['errback'](error);
          }
        });

        // Set transport "producedata" event handler.
        // Here we must communicate our local parameters to our remote transport.
        // Done in the server, pass the response to our transport.
        // Something was wrong in server side.
        _sendTransport!.on('producedata', (data) async {
          try {
            Map response = await _socketIo!.sendEventEmitterAck('produceData', {
              'transportId': _sendTransport!.id,
              'sctpStreamParameters': data['sctpStreamParameters'].toMap(),
              'label': data['label'],
              'protocol': data['protocol'],
              'appData': data['appData'],
            });

            data['callback'](response['id']);
          } catch (error) {
            data['errback'](error);
          }
        });
      }

      if (_consume) {
        // Create a transport in the server via socket io client for receiving our media through it.
        Map transportInfo = await _socketIo!.sendEventEmitterAck(
          'createWebRtcTransport',
          {
            'forceTcp': false,
            'producing': false,
            'consuming': true,
            'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
          },
        );
        log('getted consume transportInfo: $transportInfo');

        _recvTransport = _mediasoupDevice!.createRecvTransportFromMap(
          transportInfo,
          consumerCallback: _consumerCallback,
        );
        // Set transport method "connect" event handler connectWebRtcTransport send via socket io client.
        // with params: transportId, dtlsParameters
        // Done in the server, tell our transport.
        // Something was wrong in server side.
        _recvTransport!.on(
          'connect',
          (data) {
            _socketIo!
                .sendEventEmitter(
                  'connectWebRtcTransport',
                  {
                    'transportId': _recvTransport!.id,
                    'dtlsParameters': data['dtlsParameters'].toMap(),
                  },
                )
                .then(data['callback'])
                .catchError(data['errback']);
          },
        );
      }

      // Request to join the room.
      // displayName: display name of the user.
      // device: device information.
      // rtpCapabilities: RTP capabilities of the user.
      // sctpCapabilities: SCTP capabilities of the user.
      // Response peers from the server.

      Map response = await _socketIo!.sendEventEmitterAck('join', {
        'displayName': displayName,
        'picture': '',
        'rtpCapabilities': _mediasoupDevice!.rtpCapabilities.toMap(),
        'sctpCapabilities': _mediasoupDevice!.sctpCapabilities.toMap(),
      });
      log('getted join response $response');

      response['peers'].forEach((value) {
        peersBloc.add(PeerAdd(newPeer: value));
      });

      if (_produce) {
        // Create a producer for sending our media.
        // Enable microphone and camera.
        _localStream = await createStream();
        enableMic();
        enableWebcam();

        _sendTransport!.on('connectionstatechange', (connectionState) {
          if (connectionState == 'connected') {
            // enableChatDataProducer();
            // enableBotDataProducer();
          }
        });
      }
    } catch (error) {
      print(error);
      close();
    }
  }

  /// join connect to the room via socket io client.
  void join() {
    _socketIo = SocketIO(
      peerId: peerId,
      roomId: roomId,
      url: url,
    );

    /// Listen notification from server.
    /// When the server send a notification, the client will handle it.
    /// case 'roomReady':
    /// The server is ready to join the room.

    _socketIo!.onOpen = () {
      print('WebSocket connection sucessfully');
    };
    _socketIo!.onFail = () {
      print('WebSocket connection failed');
    };
    _socketIo!.onDisconnected = () {
      if (_sendTransport != null) {
        _sendTransport!.close();
        _sendTransport = null;
      }
      if (_recvTransport != null) {
        _recvTransport!.close();
        _recvTransport = null;
      }
    };

    _socketIo!.onClose = () {
      if (_closed) return;

      close();
    };

    /// Listen socket io client event.
    _socketIo!.onNotification = (notification) async {
      log("WSS notifications: $notification['method']");
      switch (notification['method']) {
        case 'roomReady':
        case 'roomBack':
          {
            _joinRoom();
            break;
          }
        case 'producerScore':
          {
            break;
          }
        case 'newConsumer':
          log('rcv newConsumer ${notification['data']}');
          final bool check =
              notification['data']['appData']['source'].toString() == "screen";
          log("map presenter to state on newConsumer: check $check");
          if (check) {
            final Map<String, Peer> peers = peersBloc.state.peers;
            final Peer? currentPeer = peers[notification['data']['peerId']];

            peersBloc.add(PeerAddShareScreen(newPeer: {
              'id': notification['data']['peerId'],
              'displayName': currentPeer!.displayName + " Share Screen",
              'raisedHand': false,
            }));

            _recvTransport!.consume(
              id: notification['data']['id'],
              producerId: notification['data']['producerId'],
              kind: RTCRtpMediaTypeExtension.fromString(
                  notification['data']['kind']),
              rtpParameters:
                  RtpParameters.fromMap(notification['data']['rtpParameters']),
              appData:
                  Map<String, dynamic>.from(notification['data']['appData']),
              peerId: notification['data']['peerId'],
            );
          } else {
            _recvTransport!.consume(
              id: notification['data']['id'],
              producerId: notification['data']['producerId'],
              kind: RTCRtpMediaTypeExtension.fromString(
                  notification['data']['kind']),
              rtpParameters:
                  RtpParameters.fromMap(notification['data']['rtpParameters']),
              appData:
                  Map<String, dynamic>.from(notification['data']['appData']),
              peerId: notification['data']['peerId'],
            );
          }
          break;
        case 'consumerClosed':
          {
            String consumerId = notification['data']['consumerId'];
            final Map<String, Peer> shareScreenPeer =
                peersBloc.state.shareScreenPeer;
            final List<String> presenterConsumerIds =
                meBloc.state.presenterConsumerIds;
            final bool check = presenterConsumerIds.contains(consumerId);
            if (check) {
              peersBloc
                  .add(PeerRemoveConsumerShareScreen(consumerId: consumerId));

              final Peer? peer = shareScreenPeer.values.firstWhere(
                  (element) => element.consumers.contains(consumerId));

              peersBloc.add(PeerRemoveShareScreen(peerId: peer!.id));
              meBloc.add(MePresenterModeRemoveConsumer(
                  presenterConsumnerId: consumerId));
            } else {
              peersBloc.add(PeerRemoveConsumer(consumerId: consumerId));
            }

            break;
          }
        case 'consumerPaused':
          {
            String consumerId = notification['data']['consumerId'];
            peersBloc.add(PeerPausedConsumer(consumerId: consumerId));
            break;
          }

        case 'consumerResumed':
          {
            String consumerId = notification['data']['consumerId'];
            peersBloc.add(PeerResumedConsumer(consumerId: consumerId));
            break;
          }

        case 'newPeer':
          {
            final Map<String, dynamic> newPeer =
                Map<String, dynamic>.from(notification['data']);
            peersBloc.add(PeerAdd(newPeer: newPeer));
            break;
          }

        case 'peerClosed':
          {
            String peerId = notification['data']['peerId'];
            peersBloc.add(PeerRemove(peerId: peerId));
            break;
          }

        default:
          break;
      }
    };
  }
}
