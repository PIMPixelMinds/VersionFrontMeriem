import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pim/viewmodel/healthTracker_viewmodel.dart';

class MSNQTestPage extends StatefulWidget {
  const MSNQTestPage({super.key});

  @override
  _MSNQTestPageState createState() => _MSNQTestPageState();
}

class _MSNQTestPageState extends State<MSNQTestPage> {
  final Map<String, bool> _answers = {};
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  VoidCallback? onComplete;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializePage());
  }

  Future<void> _initializePage() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args['onComplete'] != null) {
      onComplete = args['onComplete'];
    }

    final viewModel = Provider.of<HealthTrackerViewModel>(context, listen: false);

    try {
      if (viewModel.questions.isEmpty) {
        await viewModel.fetchQuestions(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading test: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAnswers() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final viewModel = Provider.of<HealthTrackerViewModel>(context, listen: false);

    try {
      if (_answers.length != viewModel.questions.length) {
        throw Exception('Please answer all questions before submitting.');
      }

      final formattedAnswers = _answers.entries.map((entry) {
        return {
          'questionId': entry.key,
          'answer': entry.value ? 'Yes' : 'No',
        };
      }).toList();

      viewModel.answers = Map.fromEntries(formattedAnswers.map((e) => MapEntry(e['questionId']!, e['answer'] == 'Yes')));

      await viewModel.submitQuestionnaire(context);

      // 🛠 VERY IMPORTANT: Force refresh lock status
      await viewModel.checkQuestionnaireAvailability();

      if (onComplete != null) {
        onComplete!();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Answers submitted successfully.")),
        );

        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
    print('✅ After submitting test - isTestLocked=${viewModel.isTestLocked}');
    print('✅ After submitting test - nextAvailableDate=${viewModel.nextAvailableDate}');

  }


  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HealthTrackerViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MSNQ Test'),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(HealthTrackerViewModel viewModel) {
    if (_isLoading || viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.questionnaireError != null) {
      return Center(child: Text(viewModel.questionnaireError!));
    }

    if (viewModel.questions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: viewModel.questions.length,
            itemBuilder: (context, index) => _buildQuestionItem(viewModel, index),
          ),
        ),
        _buildSubmitButton(viewModel),
      ],
    );
  }

  Widget _buildQuestionItem(HealthTrackerViewModel viewModel, int index) {
    final question = viewModel.questions[index];
    final questionId = question['_id'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Q${index + 1}: ${question['text']}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Yes'),
                    value: true,
                    groupValue: _answers[questionId],
                    onChanged: (value) {
                      setState(() => _answers[questionId] = value!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('No'),
                    value: false,
                    groupValue: _answers[questionId],
                    onChanged: (value) {
                      setState(() => _answers[questionId] = value!);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(HealthTrackerViewModel viewModel) {
    final isReadyToSubmit = _answers.length == viewModel.questions.length && !_isSubmitting;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: isReadyToSubmit ? _submitAnswers : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(fontSize: 18),
        ),
        child: const Text('Submit Answers'),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
