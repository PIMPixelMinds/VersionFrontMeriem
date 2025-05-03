import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/utils.dart';
import '../../data/repositories/historique_repository.dart';
import '../../core/constants/app_colors.dart';

class HealthGroupedPage extends StatefulWidget {
  @override
  _HealthGroupedPageState createState() => _HealthGroupedPageState();
}

class _HealthGroupedPageState extends State<HealthGroupedPage> {
  List<dynamic> groupedHistorique = [];
  bool isLoading = true;
  int currentPage = 0;
  int itemsPerPage = 10;

  late final HistoryRepository _historyRepository;

  @override
  void initState() {
    super.initState();
    _historyRepository = HistoryRepository(GlobalKey()); // placeholder, not used for screenshot here
    fetchGroupedHistorique().then((_) => checkForPainNeedPopup());
  }

  Future<void> checkForPainNeedPopup() async {
    try {
      final needsPainCheckRecords = await _historyRepository.getHistoriqueNeedsPainCheck();

      if (needsPainCheckRecords.isNotEmpty) {
        final record = needsPainCheckRecords.first;
        final String historiqueId = record['_id'];
        final String zone = record['bodyPartName'] ?? "cette zone";

        final result = await _showPainCheckDialog(historiqueId, zone);

        if (result != null) {
          await _historyRepository.sendPainStatusUpdate(historiqueId, result);
          await fetchGroupedHistorique();
        }
      }
    } catch (e) {
      print("❌ Erreur récupération des douleurs needing check : $e");
    }
  }

  Future<void> fetchGroupedHistorique() async {
    try {
      List<dynamic> data = await _historyRepository.getGroupedHistorique();
      setState(() {
        groupedHistorique = data;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur : $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchHistoriqueByDate(DateTime startDate, [DateTime? endDate]) async {
    setState(() => isLoading = true);

    try {
      final data = await _historyRepository.getHistoriqueByDate(startDate, endDate);

      Map<String, List<dynamic>> grouped = {};

      for (var item in data) {
        if (item['createdAt'] != null) {
          final createdAt = DateTime.parse(item['createdAt']);
          String dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
          grouped.putIfAbsent(dateKey, () => []).add(item);
        }
      }

     setState(() {
  groupedHistorique = grouped.entries
      .map((e) => {'date': e.key, 'records': e.value})
      .toList()
    ..sort((a, b) =>
        DateTime.parse(b['date'] as String).compareTo(DateTime.parse(a['date'] as String)));
  isLoading = false;
});
    } catch (e) {
      print("❌ Erreur lors du filtre par date : $e");
      setState(() => isLoading = false);
    }
  }

  Future<bool?> _showPainCheckDialog(String historiqueId, String zone) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Suivi de douleur"),
        content: Text("As-tu encore mal à $zone ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Non")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Oui")),
        ],
      ),
    ).then((result) async {
      if (result != null) {
        await _historyRepository.sendPainStatusUpdate(historiqueId, result);
        await fetchGroupedHistorique();
      }
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final allRecords = groupedHistorique.expand((group) => group['records'] as List).toList();
    final totalPages = (allRecords.length / itemsPerPage).ceil();
    final currentPageRecords = allRecords.skip(currentPage * itemsPerPage).take(itemsPerPage).toList();

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : groupedHistorique.isEmpty
              ? Center(child: Text("No pain records available.", style: TextStyle(fontSize: 16)))
              : Column(
                  children: [
                    _buildDateFilterButton(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: currentPageRecords.length,
                        itemBuilder: (context, index) =>
                            _buildPainCard(currentPageRecords[index], index + 1 + currentPage * itemsPerPage),
                      ),
                    ),
                    _buildPaginationControls(totalPages),
                  ],
                ),
    );
  }

  Widget _buildDateFilterButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: _showDateFilterModal,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Date", style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
            icon: Icon(Icons.chevron_left),
          ),
          SizedBox(width: 16),
          Text("${currentPage + 1} / $totalPages"),
          SizedBox(width: 16),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? () => setState(() => currentPage++) : null,
            icon: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildPainCard(dynamic record, int index) {
    final bool isActive = record['isActive'] == true;
    final String? startTime = record['startTime'];
    final String? endTime = record['endTime'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: AppColors.primaryBlue.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecordImage(record['imageUrl']),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record['generatedDescription'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 5),
                      Text(
                        DateFormat('dd MMMM yyyy - HH:mm')
                            .format(DateTime.parse(record['createdAt']).toLocal()),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  if (startTime != null && isActive && record['wasOver24h'] != true)
                    StreamBuilder<Duration>(
                      stream: _liveDurationStream(DateTime.parse(startTime).toLocal()),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox();
                        final d = snapshot.data!;
                        final h = d.inHours.toString().padLeft(2, '0');
                        final m = (d.inMinutes % 60).toString().padLeft(2, '0');
                        final s = (d.inSeconds % 60).toString().padLeft(2, '0');

                        return Row(
                          children: [
                            Icon(Icons.timer, size: 16, color: Colors.grey),
                            SizedBox(width: 5),
                            Text(
                              "$h:$m:$s",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  if (record['wasOver24h'] == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Douleur détectée depuis plus de 24h.\nConsulte un professionnel de santé.",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordImage(String imagePath) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        child: Image.network(
          "http://192.168.73.201:3000$imagePath",
          width: 250,
          height: 250,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 250,
            height: 250,
            color: Colors.grey.shade300,
            child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 250,
              height: 250,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
  void _showDateFilterModal() {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      String selected = 'Today'; // valeur par défaut
      final options = ['Today', 'This week', 'This month', 'This quarter', 'This year', 'Custom'];

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text("Date", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                ...options.map((option) {
                  return RadioListTile(
                    value: option,
                    groupValue: selected,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (value) {
                      setModalState(() => selected = value as String);
                    },
                    title: Text(option),
                  );
                }).toList(),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // fermer le modal

                    DateTime now = DateTime.now();
                    DateTime start, end;

                    switch (selected) {
                      case 'Today':
                        await fetchHistoriqueByDate(now);
                        break;
                      case 'This week':
                        start = now.subtract(Duration(days: now.weekday - 1));
                        end = start.add(Duration(days: 6));
                        await fetchHistoriqueByDate(start, end);
                        break;
                      case 'This month':
                        start = DateTime(now.year, now.month, 1);
                        end = DateTime(now.year, now.month + 1, 0);
                        await fetchHistoriqueByDate(start, end);
                        break;
                      case 'This quarter':
                        int currentQuarter = ((now.month - 1) ~/ 3) + 1;
                        start = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);
                        end = DateTime(now.year, currentQuarter * 3 + 1, 0);
                        await fetchHistoriqueByDate(start, end);
                        break;
                      case 'This year':
                        start = DateTime(now.year, 1, 1);
                        end = DateTime(now.year, 12, 31);
                        await fetchHistoriqueByDate(start, end);
                        break;
                      case 'Custom':
  DateTime now = DateTime.now();
  DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2023),
    lastDate: now,
    builder: (context, child) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDarkMode
              ? ColorScheme.dark(
                  primary: AppColors.primaryBlue,
                  onPrimary: Colors.white,
                  surface: Colors.grey[900]!,
                  onSurface: Colors.white,
                )
              : ColorScheme.light(
                  primary: AppColors.primaryBlue,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            rangeSelectionBackgroundColor: AppColors.primaryBlue.withOpacity(0.3), // ✅ Plage de dates sélectionnées
            rangePickerSurfaceTintColor: Colors.transparent, // ✅ optionnel pour éviter un effet de surbrillance moche
          ),
        ),
        child: child!,
      );
    },
  );
  if (picked != null) {
    await fetchHistoriqueByDate(picked.start, picked.end);
  }
  break;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
  "Apply",
  style: TextStyle(color: Colors.white),
),
                )
              ],
            ),
          );
        },
      );
    },
  );
}
Stream<Duration> _liveDurationStream(DateTime startTime) async* {
  while (true) {
    await Future.delayed(Duration(seconds: 1));
    yield DateTime.now().difference(startTime);
  }
}
}
