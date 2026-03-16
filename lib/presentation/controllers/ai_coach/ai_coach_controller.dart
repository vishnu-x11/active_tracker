import 'package:get/get.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, this.isUser = false, required this.timestamp});
}

class AICoachController extends GetxController {
  final messages = <ChatMessage>[].obs;
  final isTyping = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initial greeting
    messages.add(ChatMessage(
      text: "Hello! I am your Active Health AI Coach. How can I help you reach your goals today?",
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    
    isTyping.value = true;
    await Future.delayed(const Duration(seconds: 1)); // Simulate AI thinking
    
    String response = _getAIResponse(text);
    messages.add(ChatMessage(text: response, timestamp: DateTime.now()));
    isTyping.value = false;
  }

  String _getAIResponse(String input) {
    input = input.toLowerCase();
    if (input.contains('weight')) {
      return "Based on your current progress, I recommend increasing your protein intake to 1.8g per kg and focusing on compound lifts. Your weight loss trend is looking healthy!";
    } else if (input.contains('workout')) {
      return "I've analyzed your recent sessions. You're doing great with cardio, but adding one more strength day would help boost your metabolism.";
    } else if (input.contains('calories')) {
      return "You've been very consistent with your calorie tracking. Try to keep your deficit around 300kcal for sustainable progress.";
    } else {
      return "That's an interesting question! To give you the best advice, could you tell me more about your specific goal or how you're feeling today?";
    }
  }
}
