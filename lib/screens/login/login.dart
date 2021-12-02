import 'package:flutter_edumeet/models/room_model.dart';
import 'package:flutter_edumeet/screens/metting/room/room_meeting.dart';
import 'package:flutter_edumeet/utils/app_util.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  static const String RoutePath = '/';
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Defind Text Ctrl
  final _nameCtrl = TextEditingController();
  final _meetingIdCtrl = TextEditingController();

  // Defind Variable Logic
  bool _busy = false;
  bool _validate = false;

  @override
  void initState() {
    AppUtil.disableOrientationLandcape();
    super.initState();
  }

  @override
  void dispose() {
    _disposeTextCtrl();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        title: Center(child: Text("Join a Meeting")),
      ),
      body: InkWell(
        onTap: () {
          AppUtil.hideKeyboard(context);
        },
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).accentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor,
              ),
            ),
            constraints: BoxConstraints(
              maxWidth: 320,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _meetingIdCtrl,
                  decoration: InputDecoration(
                    labelText: 'Meeting Id',
                    errorText:
                        _validate ? 'Field Meeting Id Can\'t Be Empty' : null,
                  ),
                ),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Screen name',
                    errorText:
                        _validate ? 'Field Screen Name Can\'t Be Empty' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() {
                              _meetingIdCtrl.text.isEmpty ||
                                      _nameCtrl.text.isEmpty
                                  ? _validate = true
                                  : _validate = false;
                            });
                            !_validate
                                ? connect(context, _nameCtrl.text,
                                    _meetingIdCtrl.text)
                                : AppUtil.showToast(
                                    'Please enter full information');
                          },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_busy)
                          const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        const Text('Join'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> connect(
      BuildContext ctx, String meetingName, String meetingId) async {
    try {
      setState(() {
        _busy = true;
      });
      // Navigator.push<void>(ctx, MaterialPageRoute(builder: (_) {
      //   return flutter_edumeetingPage(
      //     roomModel: RoomModel(meetingName, meetingId),
      //   );
      // }));
      Navigator.pushNamed(
        context,
        RoomMeeting.RoutePath,
        arguments: RoomModel(meetingName, meetingId),
      );
    } catch (error) {
      print('Could not connect $error');
      AppUtil.showToast('${error}');
    }
  }

  /// Dispose Clear TextEditingController
  _disposeTextCtrl() {
    _nameCtrl.dispose();
    _meetingIdCtrl.dispose();
  }
}
