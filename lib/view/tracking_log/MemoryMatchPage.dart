import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pim/core/constants/app_colors.dart';

class MemoryMatchPage extends StatefulWidget {
  const MemoryMatchPage({super.key});

  @override
  _MemoryMatchPageState createState() => _MemoryMatchPageState();
}

class _MemoryMatchPageState extends State<MemoryMatchPage> {
  List<String> _cards = [];
  List<bool> _cardFlips = List.generate(16, (index) => false);
  List<int> _cardValues = List.generate(16, (index) => 0);
  int _matchedCount = 0;
  int _score = 0;
  int _moves = 0;
  bool _isFirstClick = true;
  int _firstCardIndex = -1;
  int _secondCardIndex = -1;
  late Timer _showCardsTimer;
  late Timer _gameTimer;
  int _showCardsTime = 5;
  int _remainingTime = 60;
  bool _isRevealing = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _showCardsTimer.cancel();
    _gameTimer.cancel();
    super.dispose();
  }

  void _initializeGame() {
    _cards = List.generate(8, (index) => (index + 1).toString())
      ..addAll(List.generate(8, (index) => (index + 1).toString()))
      ..shuffle(Random());
    _cardFlips = List.generate(16, (index) => true);
    _initializeCardValues();
    _startShowCardsTimer();
  }

  void _initializeCardValues() {
    for (int i = 0; i < 16; i++) {
      _cardValues[i] = int.parse(_cards[i]);
    }
  }

  void _startShowCardsTimer() {
    _showCardsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_showCardsTime > 0) {
        setState(() => _showCardsTime--);
      } else {
        _showCardsTimer.cancel();
        _startGameTimer();
        setState(() {
          _cardFlips = List.generate(16, (index) => false);
          _isRevealing = false;
        });
      }
    });
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _gameTimer.cancel();
        _showGameOverDialog();
      }
    });
  }

  void _flipCard(int index) {
    if (_cardFlips[index] || _isRevealing || _isProcessing) return;

    setState(() {
      _cardFlips[index] = true;
      if (_isFirstClick) {
        _firstCardIndex = index;
        _isFirstClick = false;
      } else {
        _secondCardIndex = index;
        _moves++;
        _isProcessing = true;

        if (_cardValues[_firstCardIndex] == _cardValues[_secondCardIndex]) {
          _matchedCount++;
          _score += 10;
          _resetSelection();
          if (_matchedCount == 8) {
            _gameTimer.cancel();
            _showGameOverDialog();
          }
        } else {
          Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              _cardFlips[_firstCardIndex] = false;
              _cardFlips[_secondCardIndex] = false;
              _resetSelection();
            });
          });
        }
      }
    });
  }

  void _resetSelection() {
    _firstCardIndex = -1;
    _secondCardIndex = -1;
    _isFirstClick = true;
    _isProcessing = false;
  }

  void _showGameOverDialog() {
    final locale = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.primaryBlue,
          title: Text(locale.gameOver, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
  '${AppLocalizations.of(context)!.yourScore(_score)}',
  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
),
Text(
  '${AppLocalizations.of(context)!.moves}: $_moves',
  style: TextStyle(fontSize: 18, color: Colors.white),
),
Text(
  '${AppLocalizations.of(context)!.timeLeft(_remainingTime)}',
  style: TextStyle(fontSize: 18, color: Colors.white),
),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(locale.backToMenu, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF3c84fb), width: 1.5)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTimerWidget() {
    final locale = AppLocalizations.of(context)!;
    return Center(
      child: Text(
  locale.gameTimeLeft('$_remainingTime' as int),
  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
),
    );
  }

  Widget _buildCardGrid() {
    final locale = AppLocalizations.of(context)!;
    return Expanded(
      child: Stack(
        children: [
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: 16,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _flipCard(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primaryBlue,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, spreadRadius: 1),
                    ],
                  ),
                  child: Center(
                    child: _cardFlips[index]
                        ? Icon(_getCardIcon(_cards[index]), size: 36, color: Theme.of(context).colorScheme.onBackground)
                        : const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
          if (_isRevealing)
  Positioned.fill(
    child: Container(
      color: Colors.black.withOpacity(0.1), // ✅ s'applique à tout l'écran
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.getReady,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$_showCardsTime',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 100,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
        ],
      ),
    );
  }

  IconData _getCardIcon(String value) {
    return [
      Icons.ac_unit,
      Icons.access_alarm,
      Icons.account_balance,
      Icons.airport_shuttle,
      Icons.assignment,
      Icons.assessment,
      Icons.attach_money,
      Icons.business
    ][int.parse(value) - 1];
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(locale.memoryGameTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBox(locale.score, '$_score'),
                _buildInfoBox(locale.moves, '$_moves'),
              ],
            ),
            const SizedBox(height: 20),
            _buildGameTimerWidget(),
            const SizedBox(height: 20),
            _buildCardGrid(),
          ],
        ),
      ),
    );
  }
}
