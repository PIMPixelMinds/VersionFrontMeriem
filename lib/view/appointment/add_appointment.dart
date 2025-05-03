import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pim/data/model/appointment_mode.dart';
import 'package:pim/view/appointment/firebase_api.dart';
import 'package:pim/viewmodel/appointment_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AddAppointmentSheet extends StatefulWidget {
  const AddAppointmentSheet({super.key});

  @override
  State<AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends State<AddAppointmentSheet> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  DateTime? selectedDate;
  String? fcmToken;

  @override
  void initState() {
    super.initState();
    _fetchFcmToken();
  }

  Future<void> _fetchFcmToken() async {
    final token = await FirebaseApi().getFcmToken();
    setState(() => fcmToken = token);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AppointmentViewModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      child: Padding(
        padding: mediaQuery.viewInsets, // move sheet up when keyboard is open
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  "New Appointment",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField("Full Name", "Enter Doctor Name", fullNameController, isDarkMode),
                const SizedBox(height: 16),
                _buildDatePickerField(isDarkMode),
                const SizedBox(height: 16),
                _buildPhoneField(isDarkMode),
                const SizedBox(height: 24),
                _buildBottomButton(viewModel, isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(bool isDarkMode) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: selectedDate != null
                ? DateFormat.yMMMd().format(selectedDate!)
                : "Select Appointment Date",
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(bool isDarkMode) {
    return IntlPhoneField(
      controller: phoneController,
      decoration: InputDecoration(
        labelText: 'Enter Doctor Phone Number',
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      initialCountryCode: 'TN',
      onChanged: (phone) {},
    );
  }

  Widget _buildBottomButton(AppointmentViewModel viewModel, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (fullNameController.text.isEmpty || selectedDate == null || phoneController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please fill all fields")),
            );
            return;
          }

          final appointment = Appointment(
            fullName: fullNameController.text.trim(),
            date: selectedDate!,
            phone: phoneController.text,
            status: "Upcoming",
            fcmToken: fcmToken ?? "",
          );

          await viewModel.addAppointment(appointment);

          if (viewModel.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.errorMessage!)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Appointment added successfully!")),
            );
            await viewModel.fetchAppointments();
            Navigator.of(context).pop();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: viewModel.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Add Appointment", style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (pickedDate != null) setState(() => selectedDate = pickedDate);
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller, bool isDarkMode) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
