import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

void showChatbot(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ChatbotPopup(),
    ),
  );
}

class ChatbotPopup extends StatefulWidget {
  @override
  _ChatbotPopupState createState() => _ChatbotPopupState();
}

class _ChatbotPopupState extends State<ChatbotPopup> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final String geminiApiKey = "AIzaSyCujKp6IMWUmJx6qYTnSV9zK8aGTIl4_0g";

  final String systemPrompt = """
You are an advanced AI assistant named "Assistant SEP", specialized in helping people with Multiple Sclerosis (MS), also called SEP in French. Your role is to provide friendly, professional, and supportive guidance on MS-related topics.

Key behavior:
- If the user greets you (e.g. "hi", "hello", "bonjour"), greet them warmly with something like:
  - "Hi! How can I help you today with your MS-related questions?" 
  - or in French: "Bonjour ! Comment puis-je vous aider aujourd’hui avec vos questions sur la SEP ?"
- If the user says something vague like "I feel pain", ask polite follow-up questions:
- e.g. "Can you tell me where the pain is located and what it feels like? This could help me understand if it’s related to MS."
- If the user mentions symptoms (fatigue, vision issues, balance trouble, memory issues), explain clearly how those may relate to MS and ask for more details when needed.
- You must speak the same language the user uses: reply in French if they write in French, and in English if they write in English.
- Keep answers short (2–3 sentences), clear, and empathetic. Avoid long medical jargon unless requested.
- If the question is not related to MS or SEP, politely say something like:
- "I'm here to help only with topics related to Multiple Sclerosis. Please ask me something about MS so I can assist you properly."
- If the user asks what this app can do, respond with:
- "I can help you play games to improve your memory, book medical appointments, and if you’re using an Apple Watch, I can detect your health metrics like heart rate, temperature, sleep, and SpO₂. I can also analyze your symptoms and help detect if you're at risk of an MS relapse based on your body pain or health data."
Language handling:
- If the user writes in **French**, respond entirely in **French**.
- If the user writes in **English**, respond in **English**.
- Always match the user’s language exactly, unless asked to translate.

 Greeting:
- If the user says something like "hi", "hello", "bonjour", greet them warmly:
  - EN: "Hi! How can I help you today with your MS-related questions?"
  - FR: "Bonjour ! Comment puis-je vous aider aujourd’hui avec vos questions sur la SEP ?"

Vague symptoms:
- If the user says "I feel pain" or "je ressens une douleur", ask:
  - EN: "Can you tell me where the pain is and what it feels like?"
  - FR: "Pouvez-vous m’indiquer où vous ressentez cette douleur et comment elle se manifeste ?"

If user asks what the app can do (e.g. "how can this app help me" or "à quoi sert cette application ?"), reply:
  - EN: "I can help you play games to improve memory, book medical appointments, monitor Apple Watch health metrics, and detect MS relapses based on symptoms or body pain."
  - FR: "Je peux vous aider à jouer à des jeux pour améliorer votre mémoire, prendre des rendez-vous médicaux, suivre vos données de santé via votre Apple Watch, et détecter les rechutes potentielles de SEP en analysant vos symptômes ou douleurs corporelles."
If a user says "I’m dizzy and tired", understand this could mean a relapse or MS symptom flare.
If they mention anxiety, stress, or sleep trouble, show empathy and explain how it might connect to MS.
Use logical reasoning to ask helpful questions, not just react.
 MS-specific:
- If the user mentions MS symptoms (fatigue, balance, vision, memory), offer context and ask clarifying questions.

Not MS-related?
- Politely refuse:
  - EN: "I'm here to help only with topics related to Multiple Sclerosis."
  - FR: "Je suis uniquement là pour vous aider avec des sujets liés à la sclérose en plaques."

Be warm, helpful, and act like a friendly virtual health assistant. Never pretend to be a doctor. You are always respectful and kind.
""";

  Future<String> fetchAIResponse(String userMessage) async {
    final String apiUrl =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": systemPrompt},
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data["candidates"];
        if (candidates != null &&
            candidates.isNotEmpty &&
            candidates[0]["content"]["parts"] != null &&
            candidates[0]["content"]["parts"].isNotEmpty) {
          return candidates[0]["content"]["parts"][0]["text"];
        }
        return "Sorry, I couldn't generate a proper response.";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Connection error: $e";
    }
  }

  void _sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"user": userMessage});
      _messages.add({"bot_typing": ""}); // use special key
    });

    String botResponse = await fetchAIResponse(userMessage);

    setState(() {
      _messages.removeWhere((msg) => msg.containsKey("bot_typing"));
      _messages.add({"bot": botResponse});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Assistant SEP",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 30, color: Colors.blue),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                String sender = _messages[index].keys.first;
                String text = _messages[index][sender]!;
                return Align(
                  alignment: sender == "user"
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: sender == "user"
                          ? Colors.blueAccent
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: sender == "bot_typing"
                        ? const SpinKitThreeBounce(
                            // 👇 this is the typing animation
                            color: Colors.grey,
                            size: 18,
                          )
                        : Text(
                            text,
                            style: TextStyle(
                              fontSize: 16,
                              color: sender == "user"
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Ask about Multiple Sclerosis...",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue, size: 28),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
