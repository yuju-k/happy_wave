import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'chat_message_bubble.dart';
import '../services/message_service.dart';
import 'chat_config.dart';

/// Displays a chat interface with message history and real-time updates.
class ChatOutput extends StatefulWidget {
  final String chatRoomId;
  final String myName;
  final String myUserId;
  final String? otherUserName;
  final String? otherUserId;

  const ChatOutput({
    super.key,
    required this.chatRoomId,
    required this.myName,
    required this.myUserId,
    this.otherUserName,
    this.otherUserId,
  });

  @override
  ChatOutputState createState() => ChatOutputState();
}

class ChatOutputState extends State<ChatOutput> {
  final MessageService _messageService = MessageService();
  final ScrollController _scrollController = ScrollController();
  final List<types.Message> _messages = [];
  final Map<String, bool> _showOriginalMap = {};

  bool _isLoadingOlder = false;
  bool _hasMoreMessages = true;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads initial messages for the chat room.
  Future<void> _loadInitialMessages() async {
    try {
      final initialMessages = await _messageService.loadInitialMessages(
        roomId: widget.chatRoomId,
      );

      if (!mounted) return;

      setState(() {
        _messages.addAll(initialMessages);
        _isInitialLoad = false;
        _initializeOriginalMap(initialMessages);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });

      _subscribeToNewMessages();
    } catch (error) {
      _showErrorSnackBar('Failed to load messages: $error');
    }
  }

  /// Subscribes to real-time new message updates.
  void _subscribeToNewMessages() {
    final afterTime =
        _messages.isNotEmpty
            ? DateTime.fromMillisecondsSinceEpoch(_messages.last.createdAt!)
            : null;

    _messageService
        .streamNewMessages(widget.chatRoomId, afterTime: afterTime)
        .listen(
          (newMessage) {
            if (!mounted) return;

            setState(() {
              _messages.add(newMessage);
              _showOriginalMap[newMessage.id] = false;
              _messageService.clearOldMessagesFromMemory(_messages);
            });

            WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd());
          },
          onError:
              (error) => _showErrorSnackBar('Message stream error: $error'),
        );
  }

  /// Handles scroll events to load older messages when reaching the top.
  void _handleScroll() {
    if (_scrollController.position.pixels <= ChatConfig.scrollThreshold &&
        !_isLoadingOlder &&
        _hasMoreMessages &&
        !_isInitialLoad) {
      _loadOlderMessages();
    }
  }

  /// Loads older messages for pagination.
  Future<void> _loadOlderMessages() async {
    if (_messages.isEmpty) return;

    setState(() => _isLoadingOlder = true);

    try {
      final beforeTime = DateTime.fromMillisecondsSinceEpoch(
        _messages.first.createdAt!,
      );

      final olderMessages = await _messageService.loadOlderMessages(
        roomId: widget.chatRoomId,
        beforeTime: beforeTime,
      );

      if (!mounted) return;

      setState(() {
        if (olderMessages.isEmpty) {
          _hasMoreMessages = false;
        } else {
          _messages.insertAll(0, olderMessages);
          _initializeOriginalMap(olderMessages);
        }
        _isLoadingOlder = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _isLoadingOlder = false);
        _showErrorSnackBar('Failed to load older messages: $error');
      }
    }
  }

  /// Initializes the original message visibility map for new messages.
  void _initializeOriginalMap(List<types.Message> messages) {
    for (final message in messages) {
      _showOriginalMap[message.id] = false;
    }
  }

  /// Scrolls to the end of the message list smoothly.
  void scrollToEnd() {
    if (!_scrollController.hasClients || !mounted) return;

    // Attempt to scroll to the bottom
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: ChatConfig.scrollDuration,
      curve: Curves.easeOut,
    );

    // Verify and retry if not at bottom after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || !_scrollController.hasClients) return;

      final currentPosition = _scrollController.position.pixels;
      final maxExtent = _scrollController.position.maxScrollExtent;

      // If not at the bottom, retry scrolling
      if (currentPosition < maxExtent - 10) {
        _scrollController.animateTo(
          maxExtent,
          duration: ChatConfig.scrollDuration,
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Displays an error snackbar with the given message.
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (_isLoadingOlder)
          const Padding(
            padding: EdgeInsets.all(ChatConfig.padding),
            child: CircularProgressIndicator(),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              if (message is! types.TextMessage) return const SizedBox.shrink();

              return ChatMessageBubble(
                message: message,
                isMyMessage: message.author.id == widget.myUserId,
                showOriginal: _showOriginalMap[message.id] ?? false,
                onToggleOriginal:
                    () => setState(() {
                      _showOriginalMap[message.id] =
                          !(_showOriginalMap[message.id] ?? false);
                    }),
              );
            },
          ),
        ),
      ],
    );
  }
}
