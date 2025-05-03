import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodel/auth_viewmodel.dart';

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({super.key});

  @override
  _MedicalHistoryPageState createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  String? selectedStage;
  final TextEditingController diagnosisController = TextEditingController();
  List<String> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userProfile = authViewModel.userProfile;

    if (userProfile != null) {
      diagnosisController.text = userProfile['diagnosis'] ?? '';
      selectedStage = userProfile['type'];
      if (userProfile['medicalReport'] != null) {
        selectedFiles.add(userProfile['medicalReport'].toString().split('/').last);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBlue : Colors.white,
      appBar: AppBar(
        title: Text(
          localizations.medicalHistory,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      localizations.diagnosis,
                      localizations.enterDiagnosis,
                      diagnosisController,
                      isDarkMode,
                    ),
                    const SizedBox(height: 15),
                    _buildStageSelector(isDarkMode, localizations),
                    const SizedBox(height: 15),
                    _buildFilePicker(isDarkMode, localizations),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(isDarkMode, localizations),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      color: AppColors.primaryBlue,
      child: const SizedBox(height: 10),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStageSelector(bool isDarkMode, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.type,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStageButton("SEP-RR", isDarkMode),
            const SizedBox(width: 10),
            _buildStageButton("SEP-PS", isDarkMode),
            const SizedBox(width: 10),
            _buildStageButton("SEP-PP", isDarkMode),
            const SizedBox(width: 10),
            _buildStageButton("SEP-PR", isDarkMode),
          ],
        ),
      ],
    );
  }

  Widget _buildStageButton(String stage, bool isDarkMode) {
    bool isSelected = selectedStage == stage;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStage = stage;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue
                : (isDarkMode ? Colors.grey[800] : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey),
          ),
          child: Center(
            child: Text(
              stage,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(bool isDarkMode, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.reports,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();
if (result != null) {
  setState(() {
    selectedFiles.clear(); // optionnel : remplacer les anciens
    selectedFiles.add(result.files.single.path!); // <== utiliser le `path`, pas juste le `name`
  });
}
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
  selectedFiles.isEmpty
      ? localizations.selectFile
      : selectedFiles.map((f) => f.split('/').last).join(", "),
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(bool isDarkMode, AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ElevatedButton(
        onPressed: () async {
          final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
          await authViewModel.updateProfile(
            context: context,
            newDiagnosis: diagnosisController.text.isNotEmpty ? diagnosisController.text : null,
            newType: selectedStage,
            newMedicalReportPath: selectedFiles.isNotEmpty ? selectedFiles.first : null,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          localizations.edit,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}