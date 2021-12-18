part of 'peers_bloc.dart';

class PeersState extends Equatable {
  final Map<String, Peer> peers;
  final Map<String, Peer> shareScreenPeer;

  const PeersState({
    this.peers = const <String, Peer>{},
    this.shareScreenPeer = const <String, Peer>{},
  });

  static PeersState copy(
    PeersState old, {
    Map<String, Peer>? peers,
    Map<String, Peer>? shareScreenPeer,
  }) {
    return PeersState(
      peers: peers ?? old.peers,
      shareScreenPeer: shareScreenPeer ?? old.shareScreenPeer,
    );
  }

  @override
  List<Object> get props => [peers, shareScreenPeer];
}
