import 'package:get/get.dart';
import 'package:http/http.dart' as http;


class MyHomePgaeController extends GetxController {
  var baseUrl = 'https://api.leemhoon.com/poems/can-write';

  var canWritePoem = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final uri = Uri.parse(baseUrl);
      final response = await http.get(uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('시를 쓸 수 있다');
        canWritePoem.value = true;
      } else if (response.statusCode == 400) {
        print('시 2번 다씀');
        canWritePoem.value = false;
      } else {
        print('에러 발생: ${response.statusCode}');
        canWritePoem.value = false;
      }
    } catch (e) {
      print('요청 중 예외 발생: $e');
      canWritePoem.value = false;
    }
  }
}
