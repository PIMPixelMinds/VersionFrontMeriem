import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/model/medication_models.dart';
import '../../viewmodel/medication_viewmodel.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StockProgressCard extends StatefulWidget {
  final Medication medication;
  const StockProgressCard({super.key, required this.medication});

  @override
  State<StockProgressCard> createState() => _StockProgressCardState();
}

class _StockProgressCardState extends State<StockProgressCard> {
  List<StockHistory> _stockHistory = [];
  bool _loading = false;
  String? _fetchError;

  Future<void> _fetchStockHistory() async {
    setState(() {
      _loading = true;
      _fetchError = null;
    });
    try {
      final history =
          await Provider.of<MedicationViewModel>(context, listen: false)
              .getStockHistory(widget.medication.id, onError: (msg) {
        setState(() => _fetchError = msg);
      });
      setState(() => _stockHistory = history);
    } catch (e) {
      setState(() => _fetchError = 'Erreur lors de la rÃ©cupÃ©ration du stock');
    }
    setState(() => _loading = false);
  }

  void _showStockHistoryDialog() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    await _fetchStockHistory();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          localizations.stockHistory,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : _fetchError != null
                  ? Text(
                      _fetchError!,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    )
                  : _stockHistory.isEmpty
                      ? Text(
                          localizations.noStockModification,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        )
                      : SizedBox(
                          height: 300,
                          width: 350,
                          child: ListView.builder(
                            itemCount: _stockHistory.length,
                            itemBuilder: (context, index) {
                              final entry = _stockHistory[index];
                              return ListTile(
                                leading: Icon(
                                  entry.type == 'add'
                                      ? Icons.add_circle
                                      : entry.type == 'take'
                                          ? Icons.remove_circle
                                          : Icons.edit,
                                  color: entry.type == 'add'
                                      ? Colors.green
                                      : entry.type == 'take'
                                          ? Colors.red
                                          : Colors.grey,
                                ),
                                title: Text(
                                  '${entry.type == 'add' ? 'Ajout' : entry.type == 'take' ? 'Prise' : 'Ajustement'} : ${entry.changeAmount > 0 ? '+' : ''}${entry.changeAmount}',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
  localizations.stockFlow(
    entry.previousStock.toString(),
    entry.currentStock.toString(), // Renamed from newStock
  ) + '\n${entry.notes ?? ''}',
  style: TextStyle(
    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
  ),
),
                                trailing: Text(
                                  '${entry.createdAt.day}/${entry.createdAt.month} ${entry.createdAt.hour}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localizations.close,
              style: TextStyle(
                color: isDarkMode ? Colors.blue[300] : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final stock = widget.medication.currentStock;
    final threshold = widget.medication.lowStockThreshold;
    final double progress =
        threshold > 0 ? (stock / threshold).clamp(0.0, 1.0) : 1.0;

    return GestureDetector(
      onTap: _showStockHistoryDialog,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.stock,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          stock <= threshold ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '$stock',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? (stock <= threshold
                                ? Colors.red[300]
                                : Colors.green[300])
                            : (stock <= threshold ? Colors.red : Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              threshold > 0
                  ? localizations.lowThreshold(threshold.toString())
                  : localizations.noThresholdDefined,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            if (stock <= threshold)
              Text(
                localizations.lowStock,
                style: TextStyle(
                  color: isDarkMode ? Colors.red[300] : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
