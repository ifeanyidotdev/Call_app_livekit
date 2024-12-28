import 'package:call_app_livekit/src/screens/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PpScreen extends StatefulWidget {
  const PpScreen({super.key});

  @override
  _PpScreenState createState() => _PpScreenState();
}

class _PpScreenState extends State<PpScreen> {
  final TextEditingController _callIdController = TextEditingController();
  final TextEditingController _peerIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _callIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Remote Peer Id',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _peerIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter peer Id',
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blue),
              ),
              onPressed: () {
                context.push(CallScreen.routeName, extra: {
                  "callId": _callIdController.text,
                  "peerId": _peerIdController.text,
                });
              },
              child: const Text(
                'Join Call',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
