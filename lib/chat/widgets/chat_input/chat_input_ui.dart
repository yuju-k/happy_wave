import 'package:flutter/material.dart';
import 'chat_input_controller.dart';

class ChatInputUI {
  final ChatInputController controller;

  ChatInputUI({required this.controller});

  // ===========================================
  // 메인 빌드 메서드
  // ===========================================
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (controller.showSuggestions) _buildSuggestionWidget(context),
        _buildInputContainer(context),
      ],
    );
  }

  // ===========================================
  // 입력 컨테이너
  // ===========================================
  Widget _buildInputContainer(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFD8F3F1)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        child: TextField(
          controller: controller.textController,
          enabled: !controller.isLoading,
          decoration: InputDecoration(
            hintText: controller.getHintText(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            suffixIcon: _buildSendButton(context),
          ),
          onSubmitted: (_) => controller.handleTextSubmission(),
        ),
      ),
    );
  }

  // ===========================================
  // 제안 위젯
  // ===========================================
  Widget _buildSuggestionWidget(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(color: Color(0xFF71D9D4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuggestionHeader(),
          const SizedBox(height: 12),
          _buildMessageButtons(),
        ],
      ),
    );
  }

  Widget _buildSuggestionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '💡 더 좋은 표현을 제안드려요!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: controller.closeSuggestions,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      ),
    );
  }

  // ===========================================
  // 메시지 버튼들
  // ===========================================
  Widget _buildMessageButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildMessageButton(
            label: '원본',
            message: controller.originalMessage,
            onPressed: controller.selectOriginalMessage,
            isOriginal: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _buildMessageButton(
            label: '제안',
            message: controller.suggestionResult,
            onPressed: controller.selectSuggestion,
            isOriginal: false,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageButton({
    required String label,
    required String message,
    required VoidCallback onPressed,
    required bool isOriginal,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFEDFFFE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOriginal ? Colors.orange.shade200 : Colors.green.shade200,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildButtonHeader(label, isOriginal),
            const SizedBox(height: 6),
            _buildButtonMessage(message),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonHeader(String label, bool isOriginal) {
    return Row(
      children: [
        Icon(
          isOriginal ? Icons.edit : Icons.lightbulb,
          size: 16,
          color: isOriginal ? Colors.orange : Colors.green,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOriginal ? Colors.orange : Colors.green,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonMessage(String message) {
    return Text(
      message,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ===========================================
  // 전송 버튼
  // ===========================================
  Widget _buildSendButton(BuildContext context) {
    if (controller.isLoading) {
      return _buildLoadingIndicator(context);
    }

    return IconButton(
      icon: const Icon(Icons.send),
      onPressed: controller.isLoading ? null : controller.handleSendButtonPress,
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
