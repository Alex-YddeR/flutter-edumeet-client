import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_edumeet/features/peers/bloc/peers_bloc.dart';
import 'package:flutter_edumeet/features/peers/enitity/peer.dart';
import 'package:flutter_edumeet/features/peers/ui/remote_stream.dart';
import 'package:flutter_edumeet/features/producers/bloc/producers_bloc.dart';
import 'package:flutter_edumeet/features/producers/ui/renderer/local_stream.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasoup_client_flutter/mediasoup_client_flutter.dart';

class CamerasList extends StatefulWidget {
  const CamerasList({Key? key}) : super(key: key);

  @override
  _CamerasListState createState() => _CamerasListState();
}

class _CamerasListState extends State<CamerasList> {
  final _streamPage = StreamController<int>.broadcast();
  //Trang hiện tại
  int _currentPage = 0;
  //Số lượng camera trên một page
  final int _cameraPerPage = 4;

  Widget? _localCamera;

  @override
  void initState() {
    _localCamera = LocalStream();
    super.initState();
  }

  @override
  void dispose() {
    _streamPage.close();
    super.dispose();
  }

  bool isActiveLocalCamera(BuildContext context) {
    final Producer? webcam =
        BlocProvider.of<ProducersBloc>(context).state.webcam;
    return webcam != null;
  }

  @override
  Widget build(BuildContext context) {
    log('presenter: call build cameras grid');
    final _size = MediaQuery.of(context).size;
    final Map<String, Peer> peers =
        BlocProvider.of<PeersBloc>(context).state.peers;
    final _localOn = isActiveLocalCamera(context);
    final _countCamera = peers.length + (_localOn ? 1 : 0);
    final _totalPageCamera = (_countCamera ~/ _cameraPerPage) +
        (((_countCamera % _cameraPerPage) != 0) ? 1 : 0);
    if ((_currentPage + 1) > _totalPageCamera) {
      _streamPage.sink.add(0);
    }
    final width = _size.width;
    return StreamBuilder<int>(
      stream: _streamPage.stream,
      initialData: _currentPage,
      builder: (context, snapshot) {
        _currentPage = snapshot.data!;

        final _totalCamera =
            _localOn ? (peers.length + _currentPage + 1) : peers.length;
        final _totalPage = (_totalCamera ~/ _cameraPerPage) +
            (((_totalCamera % _cameraPerPage) != 0) ? 1 : 0);
        log("presenter: number of video: $_totalCamera, _totalPage:$_totalPage");
        final _isLastPage = (_currentPage + 1) == _totalPage;
        return Stack(
          children: [
            ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _totalCamera == 0
                  ? 0
                  : _isLastPage
                      ? (_totalCamera % _cameraPerPage) == 0
                          ? _cameraPerPage
                          : (_totalCamera % _cameraPerPage)
                      : _cameraPerPage,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0 && _localOn) {
                  return Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Container(
                      width: width / _cameraPerPage,
                      child: _localCamera ?? const SizedBox.shrink(),
                    ),
                  );
                } else {
                  final item = peers.values.elementAt(
                      ((_currentPage * _cameraPerPage) + index) -
                          (_localOn ? (_currentPage + 1) : 0));
                  return Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: SizedBox(
                      key: ValueKey('${item.id}_container'),
                      width: width / _cameraPerPage,
                      height: 30,
                      // child: Container(
                      //   child:
                      //       // RemoteStream(
                      //       //   key: ValueKey(item.id),
                      //       //   peer: item,
                      //       //   thumbnailMode: true,
                      //       // ),
                      //       ParticipantWidget(
                      //     displayName: item.displayName,
                      //     isRaisedHand: item.isRaisedHand,
                      //     micState: item.audio?.paused,
                      //     showFullScreenButton:
                      //         item.renderer?.renderVideo ?? false,
                      //     videoView: (item.renderer?.renderVideo ?? false)
                      //         ? RTCVideoView(
                      //             item.renderer!,
                      //             objectFit: RTCVideoViewObjectFit
                      //                 .RTCVideoViewObjectFitCover,
                      //           )
                      //         : Container(
                      //             child: FittedBox(
                      //               fit: BoxFit.contain,
                      //               child: Icon(
                      //                 Icons.person,
                      //                 // size: double.infinity,
                      //               ),
                      //             ),
                      //           ),
                      //     thumbnailMode: true,
                      //   ),
                      // ),
                      child: RemoteStream(
                        key: ValueKey(item.id),
                        peer: item,
                      ),
                    ),
                  );
                }
              },
            ),
            (_totalPage > 1)
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 50.0,
                          width: 50.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.black12,
                          ),
                          child: InkWell(
                            onTap: () {
                              log('presenter: on left');
                              if (snapshot.data! > 0) {
                                _streamPage.sink.add(snapshot.data! - 1);
                              }
                            },
                            child: Icon(Icons.arrow_back_ios_new),
                          ),
                        ),
                        Container(
                          height: 50.0,
                          width: 50.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.black12,
                          ),
                          child: InkWell(
                            onTap: () {
                              log('presenter: on right');
                              if ((snapshot.data! + 1) < _totalPage) {
                                _streamPage.sink.add(snapshot.data! + 1);
                              }
                            },
                            child: Icon(Icons.arrow_forward_ios),
                          ),
                        ),
                      ],
                    ),
                  )
                : SizedBox.shrink(),
          ],
        );
      },
    );
  }
}
