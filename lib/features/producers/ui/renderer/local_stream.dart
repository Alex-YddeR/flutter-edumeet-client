import 'package:flutter_edumeet/features/media_devices/bloc/media_devices_bloc.dart';
import 'package:flutter_edumeet/features/producers/bloc/producers_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_edumeet/screens/metting/room/full_screen_view.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class LocalStream extends StatefulWidget {
  const LocalStream({Key? key, this.localUserName}) : super(key: key);

  final localUserName;

  @override
  _LocalStreamState createState() => _LocalStreamState();
}

class _LocalStreamState extends State<LocalStream> {
  late RTCVideoRenderer renderer;
  final double streamContainerWidth = 120;
  final double streamContainerHeight = 150;

  @override
  void initState() {
    super.initState();
    initRenderers();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProducersBloc, ProducersState>(
      listener: (context, state) {
        if (renderer.srcObject != state.webcam?.stream) {
          renderer.srcObject = state.webcam?.stream;
        }
      },
      builder: (context, state) {
        final MediaDeviceInfo? selectedVideoInput = context.select(
            (MediaDevicesBloc mediaDevicesBloc) =>
                mediaDevicesBloc.state.selectedVideoInput);
        if (renderer.srcObject != null && renderer.renderVideo) {
          final RTCVideoView videoView = RTCVideoView(
            renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            mirror: selectedVideoInput != null &&
                    selectedVideoInput.label.contains('back')
                ? false
                : true,
            // mirror: true,
          );

          return Padding(
            padding: const EdgeInsets.all(0.0),
            child: Stack(
              children: [
                Container(
                  key: ValueKey('RenderMe_View'),
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.3,
                  color: Colors.black12,
                  margin: const EdgeInsets.all(2),
                  child: ClipRRect(
                    // borderRadius: BorderRadius.circular(10.0),
                    child: videoView,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  left: 2,
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.localUserName ?? ''}',
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.fullscreen),
                    color: Colors.grey,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullscreenView(
                            child: videoView,
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        }

        return SizedBox.shrink();
      },
    );
  }

  void initRenderers() async {
    renderer = RTCVideoRenderer();
    await renderer.initialize();
  }

  @override
  void dispose() {
    renderer.dispose();
    super.dispose();
  }
}
