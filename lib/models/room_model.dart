class RoomModel {
  final String name;
  final String roomId;

  RoomModel(this.name, this.roomId);

  @override
  String toString() {
    return 'RoomModel{name: $name, roomId: $roomId}';
  }
}
