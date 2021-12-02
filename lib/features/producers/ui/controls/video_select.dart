import 'package:flutter/material.dart';
import 'package:flutter_edumeet/features/media_devices/bloc/media_devices_bloc.dart';
import 'package:flutter_edumeet/utils/colors.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VideoInputSelectorWidget extends StatelessWidget {
  const VideoInputSelectorWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<MediaDeviceInfo> videoInputDevices =
        context.select((MediaDevicesBloc bloc) => bloc.state.videoInputs);
    return ElevatedButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all(CircleBorder()),
        padding: MaterialStateProperty.all(EdgeInsets.all(8)),
        backgroundColor:
            MaterialStateProperty.all(Colors.white), // <-- Button color
        overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed))
            return Colors.grey; // <-- Splash color
        }),
        shadowColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed))
            return Colors.grey; // <-- Splash color
        }),
      ),
      onPressed: () {
        _showPopupMenu(context, videoInputDevices);
      },
      child: Icon(
        Icons.cameraswitch_sharp,
        color: Colors.black,
      ),
    );
  }

  void _showPopupMenu(
    BuildContext context,
    List<MediaDeviceInfo> videoInputDevices,
  ) async {
    BuildContext ctx = context;
    await showMenu(
      context: (ctx),
      position:
          RelativeRect.fromLTRB(0, 600 - kBottomNavigationBarHeight, 100, 100),
      items: videoInputDevices.map<PopupMenuItem<MediaDeviceInfo>>((device) {
        return PopupMenuItem<MediaDeviceInfo>(
          child: InkWell(
            onTap: () {
              context.read<MediaDevicesBloc>().add(
                    MediaDeviceSelectVideoInput(device),
                  );
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(device.deviceId == '0'
                    ? Icons.video_camera_back_outlined
                    : Icons.video_camera_front_outlined),
                Text(
                  device.deviceId == '0' ? "Camera back" : "Camera front",
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: AppColor.primary,
                  ),
                ),
              ],
            ),
          ),
          value: (device),
        );
      }).toList(),
      elevation: 8.0,
    );
  }
}
