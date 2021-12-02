import 'package:flutter/material.dart';
import 'package:flutter_edumeet/features/producers/ui/controls/leave_room.dart';
import 'package:flutter_edumeet/features/producers/ui/controls/microphone.dart';
import 'package:flutter_edumeet/features/producers/ui/controls/video_select.dart';
import 'package:flutter_edumeet/features/producers/ui/controls/webcam.dart';

import 'chatting.dart';

class BaseCtrolWidget extends StatelessWidget {
  const BaseCtrolWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 15,
      ),
      child: Container(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 1,
          runSpacing: 1,
          children: [
            VideoInputSelectorWidget(),
            Webcam(),
            Microphone(),
            Chatting(),
            Leave(),
          ],
        ),
      ),
    );
  }
}
