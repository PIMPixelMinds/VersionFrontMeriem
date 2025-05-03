// ✅ FINAL VERSION: Fully Integrated BodyPage with Enhanced HistoryRepository

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:body_part_selector/body_part_selector.dart';
import 'package:flutter/rendering.dart';
import 'package:pim/data/repositories/shared_prefs_service.dart';
import 'package:pim/data/repositories/historique_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:pim/view/body/firebase_historique_api.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';

class BodyPage extends StatefulWidget {
  @override
  _BodyPageState createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> with SingleTickerProviderStateMixin {
  final SharedPrefsService _prefsService = SharedPrefsService();
  final GlobalKey _globalKey = GlobalKey();
  late HistoryRepository _historyRepository;

  BodyParts _selectedParts = const BodyParts();
  bool isFrontView = true;
  TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _token;

  late AnimationController _animationController;
  late Animation<double> _flipAnimation;

  final Map<String, int> bodyPartIndexMap = {
    'head': 1, 'neck': 2, 'leftShoulder': 3, 'rightShoulder': 4,
    'leftUpperArm': 5, 'rightUpperArm': 6, 'leftElbow': 7, 'rightElbow': 8,
    'leftLowerArm': 9, 'rightLowerArm': 10, 'leftHand': 11, 'rightHand': 12,
    'upperBody': 13, 'lowerBody': 14, 'leftUpperLeg': 15, 'rightUpperLeg': 16,
    'leftKnee': 17, 'rightKnee': 18, 'leftLowerLeg': 19, 'rightLowerLeg': 20,
    'leftFoot': 21, 'rightFoot': 22, 'abdomen': 23, 'vestibular': 24,
  };

  @override
  void initState() {
    super.initState();
    _loadToken();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _historyRepository = HistoryRepository(_globalKey);
  }

  Future<void> _loadToken() async {
    final token = await _prefsService.getAccessToken();
    setState(() {
      _token = token;
    });
    print("✅ JWT Token loaded: $_token");
  }

  void _onBodyPartSelected(BodyParts parts) {
    setState(() {
      _selectedParts = parts;
    });
    print("🧠 Selected part names: ${_getSelectedPartNames(parts)}");
  }

  List<String> _getSelectedPartNames(BodyParts parts) {
    final map = {
      'head': parts.head, 'neck': parts.neck, 'leftShoulder': parts.leftShoulder,
      'leftUpperArm': parts.leftUpperArm, 'leftElbow': parts.leftElbow,
      'leftLowerArm': parts.leftLowerArm, 'leftHand': parts.leftHand,
      'rightShoulder': parts.rightShoulder, 'rightUpperArm': parts.rightUpperArm,
      'rightElbow': parts.rightElbow, 'rightLowerArm': parts.rightLowerArm,
      'rightHand': parts.rightHand, 'upperBody': parts.upperBody,
      'lowerBody': parts.lowerBody, 'leftUpperLeg': parts.leftUpperLeg,
      'leftKnee': parts.leftKnee, 'leftLowerLeg': parts.leftLowerLeg,
      'leftFoot': parts.leftFoot, 'rightUpperLeg': parts.rightUpperLeg,
      'rightKnee': parts.rightKnee, 'rightLowerLeg': parts.rightLowerLeg,
      'rightFoot': parts.rightFoot, 'abdomen': parts.abdomen,
      'vestibular': parts.vestibular,
    };
    return map.entries.where((e) => e.value).map((e) => e.key).toList();
  }

  Future<void> _captureAndUploadScreenshot() async {
    if (_descriptionController.text.isEmpty) {
      _showErrorDialog("Please describe your pain.");
      return;
    }

    if (_token == null || _token!.isEmpty) {
      _showErrorDialog("You must be logged in.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final file = File('${(await getTemporaryDirectory()).path}/screenshot.png');
      await file.writeAsBytes(pngBytes);

      final selectedNames = _getSelectedPartNames(_selectedParts);
      final selectedIndexes = selectedNames.map((name) => bodyPartIndexMap[name] ?? 0).toList();

      final fcmToken = await FirebaseHistoriqueApi().getFcmToken();

      final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.saveHistoriqueEndpoint))
        ..headers['Authorization'] = 'Bearer $_token'
        ..fields['userText'] = _descriptionController.text
        ..fields['bodyPartName'] = selectedNames.join(', ')
        ..fields['bodyPartIndex'] = selectedIndexes.join(', ')
        ..fields['fcmToken'] = fcmToken ?? ''
        ..files.add(await http.MultipartFile.fromPath(
          'screenshot',
          file.path,
          contentType: MediaType('image', 'png'),
        ));

      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      print("🔍 Server response: $responseString");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSuccessDialog();
      } else {
        print("❌ HTTP Error ${response.statusCode} : $responseString");
        throw Exception("Server rejected the upload.");
      }
    } catch (e) {
      _showErrorDialog("An error occurred. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDescriptionSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Describe the pain",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: "e.g. I feel pain in my arm...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _captureAndUploadScreenshot();
                },
                icon: const Icon(Icons.send),
                label: const Text("Send"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("✅ Success"),
        content: Text("Your screenshot has been successfully uploaded!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/healthPage');
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("⚠️ Error"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text("Select a body part"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.flip_camera_android),
            onPressed: () {
              setState(() {
                isFrontView = !isFrontView;
                isFrontView ? _animationController.reverse() : _animationController.forward();
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
  padding: const EdgeInsets.symmetric(vertical: 20),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      RepaintBoundary(
        key: _globalKey,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(_flipAnimation.value * 3.14),
            child: child,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.6,
            child: BodyPartSelector(
              bodyParts: _selectedParts,
              onSelectionUpdated: _onBodyPartSelected,
              side: isFrontView ? BodySide.front : BodySide.back,
              selectedColor: AppColors.primaryBlue,
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      if (_isLoading)
        const CircularProgressIndicator()
      else
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: FloatingActionButton.extended(
            onPressed: _showDescriptionSheet,
            label: const Text("Describe"),
            icon: const Icon(Icons.edit),
            backgroundColor: AppColors.primaryBlue,
          ),
        ),
    ],
  ),
),
    );
  }
}
