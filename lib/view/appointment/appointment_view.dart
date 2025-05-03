// appointment_page.dart
import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pim/core/constants/app_colors.dart';
import 'package:pim/data/model/appointment_mode.dart';
import 'package:pim/view/appointment/add_appointment.dart';
import 'package:pim/viewmodel/appointment_viewmodel.dart';
import 'package:provider/provider.dart';

enum FilterStatus { Upcoming, Completed, Canceled }

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({Key? key}) : super(key: key);

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  FilterStatus status = FilterStatus.Upcoming;
  Alignment _alignment = Alignment.centerLeft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppointmentViewModel>(context, listen: false)
          .fetchAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Appointment Schedule',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _weekDaysView(isDarkMode),
            const SizedBox(height: 16),
            _datePickerView(isDarkMode),
            const SizedBox(height: 16),
            _filterTabs(isDarkMode),
            const SizedBox(height: 16),
            Expanded(child: _appointmentList(isDarkMode)),
          ],
        ),
      ),
    );
  }

  Widget _weekDaysView(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            DateFormat.yMMMd().format(DateTime.now()),
            style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            "Today",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black),
          ),
        ]),
        _addAppointmentButton(() {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddAppointmentSheet(),
          );
        }, "Add Appointment"),
      ],
    );
  }

  Widget _datePickerView(bool isDarkMode) {
    return DatePicker(
      DateTime.now(),
      height: 95,
      width: 75,
      initialSelectedDate: DateTime.now(),
      selectionColor: AppColors.primaryBlue,
      selectedTextColor: Colors.white,
      dateTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.grey[400]! : Colors.black),
      monthTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.grey[400]! : Colors.black),
      dayTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.grey[400]! : Colors.black),
      controller: DatePickerController(),
    );
  }

  Widget _filterTabs(bool isDarkMode) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
          color: isDarkMode ? Colors.white24 : Colors.grey[200],
          borderRadius: BorderRadius.circular(25)),
      child: Stack(children: [
        AnimatedAlign(
          alignment: _alignment,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Container(
            width: MediaQuery.of(context).size.width / 2.7 - 26,
            height: 45,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20)),
          ),
        ),
        Row(
          children: FilterStatus.values.map((filterStatus) {
            final isSelected = status == filterStatus;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    status = filterStatus;
                    _alignment = switch (status) {
                      FilterStatus.Upcoming => Alignment.centerLeft,
                      FilterStatus.Completed => Alignment.center,
                      FilterStatus.Canceled => Alignment.centerRight,
                    };
                  });
                },
                child: Center(
                  child: Text(
                    filterStatus.name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Widget _appointmentList(bool isDarkMode) {
    return Consumer<AppointmentViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading)
          return const Center(child: CircularProgressIndicator());

        final filtered = viewModel.appointments
            .where((a) => a.status == status.name)
            .toList();
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              "No ${status.name} appointments",
              style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final appointment = filtered[index];
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading:
                    const Icon(Icons.event_note, color: AppColors.primaryBlue),
                title: Text(appointment.fullName),
                subtitle: Text(DateFormat('EEE, MMM d • hh:mm a')
                    .format(appointment.date)),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel, color: AppColors.error),
                  onPressed: () async {
                    await viewModel.cancelAppointment(appointment.fullName);
                    await viewModel.fetchAppointments();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _addAppointmentButton(VoidCallback? onTap, String label) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 44,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.primaryBlue),
        child: Row(
          children: [
            Image.asset('assets/add.png',
                height: 20, width: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
