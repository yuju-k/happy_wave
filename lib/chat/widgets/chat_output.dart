import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../services/message_service.dart';

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
  State<ChatOutput> createState() => _ChatOutputState();
}

class _ChatOutputState extends State<ChatOutput> {
  final MessageService _messageService = MessageService();
  final ScrollController _scrollController = ScrollController();
  final List<types.Message> _messages = [];
  final Map<String, bool> _showOriginalMap = {};

  bool _isLoadingOlder = false;
  bool _hasMoreMessages = true;
  bool _isInitialLoad = true;

  // URL 감지를 위한 정규 표현식
  static final RegExp _urlRegExp = RegExp(
    r'(?:(?:https?|ftp):\/\/|www\.|ftp\.)(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[-A-Z0-9+&@#\/%=~_|$?!:,.])*(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[A-Z0-9+&@#\/%=~_|$])',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _scrollController.addListener(_onScroll);
  }

  /// 초기 메시지 로드
  Future<void> _loadInitialMessages() async {
    try {
      final initialMessages = await _messageService.loadInitialMessages(
        roomId: widget.chatRoomId,
      );

      if (!mounted) return;

      setState(() {
        _messages.addAll(initialMessages);
        _isInitialLoad = false;
        // 각 메시지의 원본 컨테이너 상태 초기화
        for (final message in initialMessages) {
          _showOriginalMap[message.id] = false;
        }
      });

      // 초기 로드 후 맨 아래로 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd();
      });

      // 초기 로드 완료 후 새 메시지 구독 시작
      _subscribeToNewMessages();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 로드 오류: $error')));
      }
    }
  }

  /// 새 메시지 실시간 구독
  void _subscribeToNewMessages() {
    // 현재 가장 최신 메시지의 시간을 기준으로 스트리밍 시작
    DateTime? afterTime;
    if (_messages.isNotEmpty) {
      final latestMessage = _messages.last;
      afterTime = DateTime.fromMillisecondsSinceEpoch(latestMessage.createdAt!);
    }

    _messageService
        .streamNewMessages(widget.chatRoomId, afterTime: afterTime)
        .listen(
          (newMessage) {
            if (!mounted) return;

            setState(() {
              _messages.add(newMessage);
              _showOriginalMap[newMessage.id] = false;

              // 메모리 관리: 너무 많은 메시지가 쌓이면 오래된 것 제거
              _messageService.clearOldMessagesFromMemory(_messages);
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToEnd();
            });
          },
          onError: (error) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('메시지 스트림 오류: $error')));
            }
          },
        );
  }

  /// 스크롤 이벤트 처리 (상단 도달 시 이전 메시지 로드)
  void _onScroll() {
    if (_scrollController.position.pixels <= 100 && // 상단 근처
        !_isLoadingOlder &&
        _hasMoreMessages &&
        !_isInitialLoad) {
      _loadOlderMessages();
    }
  }

  /// 이전 메시지 로드 (페이지네이션)
  Future<void> _loadOlderMessages() async {
    if (_messages.isEmpty) return;

    setState(() {
      _isLoadingOlder = true;
    });

    try {
      final oldestMessage = _messages.first;
      final beforeTime = DateTime.fromMillisecondsSinceEpoch(
        oldestMessage.createdAt!,
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
          // 새로 로드된 메시지들의 원본 컨테이너 상태 초기화
          for (final message in olderMessages) {
            _showOriginalMap[message.id] = false;
          }
        }
        _isLoadingOlder = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingOlder = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이전 메시지 로드 오류: $error')));
      }
    }
  }

  /// 스크롤을 리스트의 끝으로 부드럽게 이동합니다.
  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// 원본 컨테이너 표시 상태를 토글합니다.
  void _toggleOriginalContainer(String messageId) {
    setState(() {
      _showOriginalMap[messageId] = !(_showOriginalMap[messageId] ?? false);
    });
  }

  /// URL을 안전하게 실행합니다.
  Future<void> _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (!uri.hasScheme) {
      uri = Uri.parse('http://$url'); // 스키마가 없으면 http://를 붙여줍니다.
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('링크를 열 수 없습니다: $url')));
      }
    }
  }

  /// 텍스트 내 URL을 감지하고 클릭 가능하게 만듭니다.
  TextSpan _buildClickableText(String text) {
    final List<TextSpan> spans = [];
    text.splitMapJoin(
      _urlRegExp,
      onMatch: (Match match) {
        final url = match.group(0);
        if (url != null) {
          spans.add(
            TextSpan(
              text: url,
              style: const TextStyle(
                color: Colors.blue, // 링크 색상
                decoration: TextDecoration.underline, // 밑줄
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      _launchURL(url);
                    },
            ),
          );
        }
        return '';
      },
      onNonMatch: (String nonMatch) {
        spans.add(
          TextSpan(
            text: nonMatch,
            style: const TextStyle(
              color: Colors.black, // 텍스트 색상
            ),
          ),
        );
        return '';
      },
    );
    return TextSpan(children: spans);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 상단 로딩 인디케이터
        if (_isLoadingOlder)
          Container(
            padding: const EdgeInsets.all(16),
            child: const CircularProgressIndicator(),
          ),

        // 메시지 리스트
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              if (message is! types.TextMessage) return const SizedBox.shrink();

              final isMyMessage = message.author.id == widget.myUserId;
              final createdTime = DateTime.fromMillisecondsSinceEpoch(
                message.createdAt!,
              );
              final formattedTime = DateFormat('HH:mm').format(createdTime);

              return _buildMessageBubble(
                context,
                message: message,
                isMyMessage: isMyMessage,
                formattedTime: formattedTime,
              );
            },
          ),
        ),
      ],
    );
  }

  /// 메시지 버블 UI를 생성합니다.
  Widget _buildMessageBubble(
    BuildContext context, {
    required types.TextMessage message,
    required bool isMyMessage,
    required String formattedTime,
  }) {
    final showOriginal = _showOriginalMap[message.id] ?? false;
    final isConverted = message.metadata?['converted'] as bool? ?? false;
    final textOriginalMessage =
        message.metadata?['originalMessage'] as String? ?? '';

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isMyMessage
                  ? const Color.fromARGB(255, 212, 250, 253)
                  : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 메시지 텍스트와 시간/아이콘을 함께 배치
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 메시지 텍스트
                  // 메시지 텍스트 (URL 감지 기능 적용)
                  Expanded(
                    child: RichText(
                      // RichText 위젯 사용
                      text: _buildClickableText(message.text),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 시간과 아이콘
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (isConverted) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _toggleOriginalContainer(message.id),
                              child: Icon(
                                Icons.auto_fix_high,
                                size: 18,
                                color:
                                    showOriginal
                                        ? Colors.grey
                                        : const Color(0xFF389EA9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // 원본 컨테이너를 조건부로 표시
              if (showOriginal) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Color(0xFF389EA9), width: 3.0),
                    ),
                    color: Color(0xFFF5F5F5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '원본 메시지',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF389EA9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        textOriginalMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
