import 'dart:async';
import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketIO {
  final String peerId;
  final String roomId;
  final String url;

  Function()? onOpen;
  Function()? onFail;
  Function()? onDisconnected;
  Function()? onClose;
  late IO.Socket _socket;
  IO.Socket get socket => _socket;

  Function(dynamic request, dynamic accept, dynamic reject)?
      onRequest; // request, accept, reject
  Function(dynamic notification)? onNotification;

  SocketIO({required this.peerId, required this.roomId, required this.url}) {
    final signaling = '$url/?peerId=$peerId&roomId=$roomId';
    log('connect to socketIO at: $signaling');
    _socket = IO.io(
        signaling,
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .setExtraHeaders({
          'peerId': peerId,
          'roomId': roomId,
        }) // optional
            .build());

    _socket.on('connect', (_) {
      if (onOpen != null) {
        onOpen!();
      }
    });

    _socket.on('disconnect', (_) {
      if (onDisconnected != null) {
        onDisconnected!();
      }
    });

    _socket.on('close', (_) {
      if (onClose != null) {
        onClose!();
      }
    });

    _socket.on('error', (_) {
      if (onFail != null) {
        onFail!();
      }
    });

    _socket.on('request', (dynamic request) {
      if (onRequest != null) {
        onRequest!(request, (dynamic response) {
          _socket.emit('response', response);
        }, (dynamic error) {
          _socket.emit('response', error);
        });
      }
    });

    _socket.on('notification', (dynamic notification) {
      if (onNotification != null) {
        onNotification!(notification);
      }
    });

    _socket.connect();
  }
  void close() {
    _socket.disconnect();
  }

  /// send request emit to socket server and wait for response
  sendEventEmitterAck(method, data) async {
    log('sendRequestEmitterAck() [method: $method, data: $data]');
    final completer = Completer<dynamic>();
    final requestId = _socket.id;
    _socket.emitWithAck(
      'request',
      {
        'method': method,
        'data': data,
        'requestId': requestId,
      },
      ack: (response) {
        log('Event $method: $response');
        completer.complete(response[1]);
      },
    );
    return completer.future;
  }

  /// send reuest emit to socket server
  /// use for send message to other peer
  sendEventEmitter(method, data) async {
    log('sendEventEmitter() [method: $method, data: $data]');
    _socket.emit('notification', {
      'method': method,
      'data': data,
    });
  }
}
