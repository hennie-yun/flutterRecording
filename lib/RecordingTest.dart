import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';

class AudioController extends GetxController {
  var duration = Duration.zero.obs; // 총 시간
  var position = Duration.zero.obs; // 진행 중인 시간

  final recorder = sound.FlutterSoundRecorder();
  var isRecording = false.obs; // RxBool로 변경
  var audioPath = ''.obs; // 녹음 중단 시 경로 받아올 변수
  var playAudioPath = ''.obs; // 저장할 때 받아올 변수, 재생 시 필요

  // 재생에 필요한 것들
  final AudioPlayer audioPlayer = AudioPlayer(); // 오디오 파일을 재생하는 기능 제공
  var isPlaying = false.obs; // 현재 재생 중인지

  @override
  void onInit() {
    super.onInit();
    initRecorder();
    // playAudio(); // 첫 실행 시 자동 재생을 원하지 않으면 이 줄을 주석 처리

    // 재생 상태가 변경될 때마다 상태를 감지하는 이벤트 핸들러
    audioPlayer.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });

    // 재생 파일의 전체 길이를 감지하는 이벤트 핸들러
    audioPlayer.onDurationChanged.listen((newDuration) {
      duration.value = newDuration;
    });

    // 재생 중인 파일의 현재 위치를 감지하는 이벤트 핸들러
    audioPlayer.onPositionChanged.listen((newPosition) {
      position.value = newPosition;
    });
  }

  Future<void> playAudio() async {
    try {
      if (isPlaying.value) {
        await audioPlayer.stop(); // 이미 재생 중인 경우 정지시킵니다.
      }

      // 파일 소스를 설정합니다.
      final source = DeviceFileSource(playAudioPath.value);

      await audioPlayer.setSource(source);
      await Future.delayed(Duration(seconds: 2));

      duration.value = duration.value;
      isPlaying.value = true;

      await audioPlayer.resume();

    } catch (e) {
      print("오디오 재생 중 오류 발생: $e");
    }
  }


  Future<void> initRecorder() async {
    final status = await Permission.microphone.request();

    if (status.isDenied) {
      if (await Permission.microphone.shouldShowRequestRationale) {
        print('마이크 권한을 허용해 주세요.');
      } else {
        print('앱 설정에서 마이크 권한을 허용해 주세요.');
      }
    } else if (status.isPermanentlyDenied) {
      print('마이크 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해 주세요.');
      openAppSettings();
    } else if (status.isGranted) {
      print('마이크 권한이 허용되었습니다.');
      try {
        await recorder.openRecorder();
        recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
      } catch (e) {
        print('녹음기 초기화 중 오류 발생: $e');
      }
    } else {
      print('기타 권한 상태: ${status.toString()}');
    }
  }


  Future<String> saveRecordingLocally() async {
    if (audioPath.value.isEmpty) return ''; // 녹음된 오디오 경로가 비어있으면 빈 문자열 반환

    final audioFile = File(audioPath.value);
    if (!audioFile.existsSync()) return ''; // 파일이 존재하지 않으면 빈 문자열 반환

    try {
      final directory = await getApplicationDocumentsDirectory();
      final newPath = p.join(directory.path, 'recordings'); // recordings 디렉터리 생성
      final newFile = File(p.join(newPath, 'audio.mp3'));

      if (!(await newFile.parent.exists())) {
        await newFile.parent.create(recursive: true); // recordings 디렉터리가 없으면 생성
      }

      await audioFile.copy(newFile.path); // 기존 파일을 새로운 위치로 복사
      playAudioPath.value = newFile.path;

      return newFile.path; // 새로운 파일의 경로 반환
    } catch (e) {
      print('Error saving recording: $e');
      return ''; // 오류 발생 시 빈 문자열 반환
    }
  }

  Future<void> stop() async {
    final path = await recorder.stopRecorder(); // 녹음 중지하고, 녹음된 오디오 파일의 경로를 얻음
    audioPath.value = path!;

    isRecording.value = false;

    final savedFilePath = await saveRecordingLocally(); // 녹음된 파일을 로컬에 저장
  }

  Future<void> record() async {
    if (!isRecording.value) {
      await recorder.startRecorder(toFile: 'audio');
      isRecording.value = true; // RxBool 값을 업데이트
    }
  }




  String formatTime(Duration duration) {
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class Audio extends StatelessWidget {
  const Audio({super.key});

  @override
  Widget build(BuildContext context) {
    final AudioController controller = Get.put(AudioController());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.0,
        title: const Text(
          '녹음',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                child: Column(
                  children: [
                    Obx(() => Slider(
                      min: 0,
                      max: controller.duration.value.inSeconds.toDouble(),
                      value: controller.position.value.inSeconds.toDouble(),
                      onChanged: (value) async {
                        controller.position.value = Duration(seconds: value.toInt());
                        await controller.audioPlayer.seek(controller.position.value);
                      },
                      activeColor: Colors.black,
                    )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.formatTime(controller.position.value),
                            style: const TextStyle(color: Colors.brown),
                          ),
                          const SizedBox(width: 20),
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.transparent,
                            child: IconButton(
                              padding: const EdgeInsets.only(bottom: 50),
                              icon: Icon(
                                controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                                color: Colors.brown,
                              ),
                              iconSize: 25,
                              onPressed: () async {
                                if (controller.isPlaying.value) {
                                  await controller.audioPlayer.pause();
                                  controller.isPlaying.value = false;
                                } else {
                                  await controller.playAudio();
                                  await controller.audioPlayer.resume();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            controller.formatTime(controller.duration.value),
                            style: const TextStyle(color: Colors.brown),
                          ),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Obx(() => IconButton(
                onPressed: () async {
                  if (controller.isRecording.value) {
                    await controller.stop();
                  } else {
                    await controller.record();
                  }
                },
                icon: Icon(
                  controller.isRecording.value ? Icons.stop : Icons.mic,
                  size: 30,
                  color: Colors.black,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
