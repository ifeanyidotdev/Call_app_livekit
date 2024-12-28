import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SignalingServiceProvider extends ChangeNotifier {}

class SignalingService {
  Socket? socket;
  SignalingService._();

  static final instance = SignalingService._();

  init({required String websocketUrl, required String selfCallerID}) {
    // init Socket
    socket = io(websocketUrl, {
      "transports": ['websocket'],
      "query": {"callerId": selfCallerID}
    });

    // listen onConnect event
    socket!.onConnect((data) {
      log("Socket connected !!");
    });

    // listen onConnectError event
    socket!.onConnectError((data) {
      log("Connect Error $data");
    });

    // connect socket
    socket!.connect();
  }
}
