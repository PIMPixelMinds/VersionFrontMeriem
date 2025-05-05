import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pim/core/constants/app_colors.dart';
import '../../core/utils/utils.dart';
import '../../data/repositories/historique_repository.dart';

class HealthPage extends StatefulWidget {
  @override
  _HealthPageState createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final HistoryRepository _historyRepository = HistoryRepository(GlobalKey());
  List<dynamic> historique = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistorique();
  }

  String formatDate(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    return DateFormat('dd MMM yyyy - HH:mm').format(date);
  }

  Future<void> fetchHistorique() async {
    try {
      List<dynamic> data = await _historyRepository.getHistorique();
      setState(() {
        historique = data;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur lors du chargement de l'historique : $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Pain History",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : historique.isEmpty
              ? Center(child: Text("No history available."))
              : ListView.builder(
                  itemCount: historique.length,
                  itemBuilder: (context, index) {
                    final item = historique[index];
                    return _buildPainHistoryCard(item);
                  },
                ),
    );
  }

  Widget _buildPainHistoryCard(dynamic item) {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['imageUrl'] != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  "http://192.168.100.7:3000${item['imageUrl']}",
                  width: 250,
                  height: 250,
              
                
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              item['generatedDescription'] ?? 'No description available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              formatDate(item['createdAt']),
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          if (item['startTime'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.timelapse, size: 16, color: Colors.grey),
                  SizedBox(width: 5),
                  Text(
                    formatDuration(item['startTime'], item['endTime']),
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}