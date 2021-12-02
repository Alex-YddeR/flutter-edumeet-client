import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_edumeet/features/me/bloc/me_bloc.dart';
import 'package:flutter_edumeet/features/media_devices/bloc/media_devices_bloc.dart';
import 'package:flutter_edumeet/features/peers/bloc/peers_bloc.dart';
import 'package:flutter_edumeet/features/producers/bloc/producers_bloc.dart';
import 'package:flutter_edumeet/features/room/bloc/room_bloc.dart';
import 'package:flutter_edumeet/models/room_model.dart';

List<BlocProvider> getRoomModules({
  required RouteSettings settings,
}) {
  return [
    BlocProvider<ProducersBloc>(
      lazy: false,
      create: (context) => ProducersBloc(),
    ),
    BlocProvider<PeersBloc>(
      lazy: false,
      create: (context) => PeersBloc(
        mediaDevicesBloc: context.read<MediaDevicesBloc>(),
      ),
    ),
    BlocProvider<MeBloc>(
      lazy: false,
      create: (context) => MeBloc(roomModel: settings.arguments as RoomModel),
    ),
    BlocProvider<RoomBloc>(
      lazy: false,
      create: (context) => RoomBloc(settings.arguments as RoomModel),
    ),
  ];
}
