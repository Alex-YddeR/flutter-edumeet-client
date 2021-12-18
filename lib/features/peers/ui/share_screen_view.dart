import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_edumeet/features/peers/bloc/peers_bloc.dart';
import 'package:flutter_edumeet/features/peers/enitity/peer.dart';
import 'package:flutter_edumeet/features/peers/ui/cameras_list.dart';
import 'package:flutter_edumeet/features/peers/ui/remote_stream.dart';

class ShareScreenView extends StatelessWidget {
  const ShareScreenView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return BlocBuilder<PeersBloc, PeersState>(
      builder: (context, state) {
        final Map<String, Peer> shareScreenPeers = state.shareScreenPeer;
        final String _key =
            shareScreenPeers.keys.elementAt(shareScreenPeers.length - 1);
        final Peer _shareScreenPeer = state.shareScreenPeer[_key]!;
        log("presenter: REBUILD SHARE SCREEN VIEW! - ${shareScreenPeers.length}");
        return Column(
          children: [
            Expanded(
              child: RemoteStream(
                key: ValueKey(_shareScreenPeer.id),
                peer: _shareScreenPeer,
              ),
            ),
            Container(
              height: size.height / 8,
              color: Colors.grey,
              child: CamerasList(),
            ),
          ],
        );
      },
    );
  }
}
