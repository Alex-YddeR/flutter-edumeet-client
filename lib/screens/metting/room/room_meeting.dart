import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_edumeet/components/edumeet_appbar.dart';
import 'package:flutter_edumeet/features/me/bloc/me_bloc.dart';
import 'package:flutter_edumeet/features/peers/bloc/peers_bloc.dart';
import 'package:flutter_edumeet/features/peers/enitity/peer.dart';
import 'package:flutter_edumeet/features/peers/ui/list_remote_streams.dart';
import 'package:flutter_edumeet/features/peers/ui/share_screen_view.dart';
import 'package:flutter_edumeet/features/producers/ui/controls/base_controls_widget.dart';
import 'package:flutter_edumeet/features/producers/ui/renderer/local_stream.dart';
import 'package:flutter_edumeet/features/room/bloc/room_bloc.dart';
import 'package:flutter_edumeet/models/room_model.dart';
import 'package:flutter_edumeet/utils/app_util.dart';
import 'package:flutter_edumeet/utils/badge_widget.dart';
import 'package:flutter_edumeet/utils/colors.dart';
import 'package:wakelock/wakelock.dart';

class RoomMeeting extends StatefulWidget {
  static const String RoutePath = '/room';

  const RoomMeeting({Key? key, required this.roomModelArguments})
      : super(key: key);

  final RoomModel roomModelArguments;

  @override
  _RoomMeetingState createState() => _RoomMeetingState();
}

class _RoomMeetingState extends State<RoomMeeting> {
// Defined variable logic
  bool show = true;

  void toggle() {
    setState(() {
      show = !show;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      //Prevent app goes to sleep
      Wakelock.enable();
    });
    AppUtil.enableOrientation();
    super.initState();
  }

  @override
  void dispose() {
    //Disable sleep the app
    Wakelock.disable();
    AppUtil.disableOrientationLandcape();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String url = context.select((RoomBloc bloc) => bloc.state.url);
    final Map<String, Peer> peers =
        context.select((PeersBloc bloc) => bloc.state.peers);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: EdumeetAppBar(
        display: show,
        title: Text(
            'Room id: ${Uri.parse(url).queryParameters['roomId'] ?? Uri.parse(url).queryParameters['roomid']}'),
        centerTitle: false,
        actions: [
          InkWell(
              child: Icon(Icons.hail_outlined),
              onTap: () {
                _raseHandler(context);
              }),
        ],

        /// Add badge value via paticipant count -> value
        leading: Badge(
          right: 8,
          top: 0,
          value: peers.length.toString(),
          color: AppColor.red,
          child: Icon(Icons.group_outlined),
        ),
        color: AppColor.primary,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: toggle,
          child: BlocBuilder<PeersBloc, PeersState>(
            buildWhen: (previous, current) =>
                previous.shareScreenPeer.length !=
                current.shareScreenPeer.length,
            builder: (context, state) {
              log("presenter: REBUILD AFTER CHANGE PRESENTER MODE! - ${state.shareScreenPeer.length} - ${BlocProvider.of<MeBloc>(context).state.presenterConsumerIds.length}");
              if (state.shareScreenPeer.length > 0) {
                return ShareScreenView();
              }
              return Column(
                children: [
                  Expanded(child: ListRemoteStreams()),
                  LocalStream(localUserName: widget.roomModelArguments.name),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: show
          ? Container(
              height: kBottomNavigationBarHeight + 12,
              color: AppColor.primary,
              child: BaseCtrolWidget(),
            )
          : AppUtil.widgetEmpty,
    );
  }

  void _raseHandler(BuildContext ctx) {
    AppUtil.onDev();
  }
}
