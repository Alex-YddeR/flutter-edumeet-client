import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_edumeet/features/signaling/room_client_repository.dart';
import 'package:flutter_edumeet/screens/login/login.dart';

class Leave extends StatelessWidget {
  const Leave({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all(CircleBorder()),
        padding: MaterialStateProperty.all(EdgeInsets.all(8)),
        backgroundColor:
            MaterialStateProperty.all(Colors.red), // <-- Button color
        overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed))
            return Colors.red.shade900; // <-- Splash color
        }),
        shadowColor: MaterialStateProperty.resolveWith<Color?>((states) {
          if (states.contains(MaterialState.pressed))
            return Colors.red; // <-- Splash color
        }),
      ),
      onPressed: () {
        onCallEnd(context);
      },
      child: Icon(
        Icons.call_end,
        color: Colors.white,
        // size: screenHeight * 0.045,
      ),
    );
  }

// leave room
  static void onCallEnd(BuildContext context) {
    context.read<RoomClientRepository>().close();

    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => LoginPage()), (route) => false);
  }
}
