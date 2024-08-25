import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'MyHomePgaeController.dart';


class MyHomePage extends StatelessWidget {
  final MyHomePgaeController controller = Get.put(MyHomePgaeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Home Page'),
      ),
      body: Center(
        child: Obx(() {
          // Observe the canWritePoem variable
          return Text(
            controller.canWritePoem.value ? '시를 쓸 수 있다' : '시를 쓸 수 없다',
            style: TextStyle(fontSize: 24),
          );
        }),
      ),
    );
  }
}
