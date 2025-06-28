import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'chat_config.dart';

class ChatMessageBubble extends StatelessWidget {
  final types.TextMessage message;
  final bool isMyMessage;
  final bool showOriginal;
  final VoidCallback onToggleOriginal;
  final bool isOriginalViewEnabled;
  final bool isOriginalMessageToggleEnabled;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.showOriginal,
    required this.onToggleOriginal,
    required this.isOriginalViewEnabled,
    required this.isOriginalMessageToggleEnabled,
  });

  /// Builds a clickable text span with detected URLs.
  TextSpan _buildClickableText(String text, BuildContext context) {
    final spans = <TextSpan>[];
    text.splitMapJoin(
      ChatConfig.urlRegExp,
      onMatch: (Match match) {
        final url = match.group(0);
        if (url != null) {
          spans.add(
            TextSpan(
              text: url,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () => _launchURL(url, context),
            ),
          );
        }
        return '';
      },
      onNonMatch: (String nonMatch) {
        spans.add(
          TextSpan(text: nonMatch, style: const TextStyle(color: Colors.black)),
        );
        return '';
      },
    );
    return TextSpan(children: spans);
  }

  /// Launches a URL, adding http:// if no scheme is present.
  Future<void> _launchURL(String url, BuildContext context) async {
    Uri uri = Uri.parse(url);
    if (!uri.hasScheme) {
      uri = Uri.parse('http://$url');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to open link: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdTime = DateTime.fromMillisecondsSinceEpoch(message.createdAt!);
    final formattedTime = DateFormat('HH:mm').format(createdTime);
    final isConverted = message.metadata?['converted'] as bool? ?? false;
    final originalMessage =
        message.metadata?['originalMessage'] as String? ?? '';

    final displayOriginalView = isOriginalMessageToggleEnabled;
    final displayOriginalToggle = isOriginalViewEnabled;

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * ChatConfig.maxBubbleWidth,
        ),
        margin: const EdgeInsets.symmetric(
          vertical: ChatConfig.marginVertical,
          horizontal: ChatConfig.marginHorizontal,
        ),
        padding: const EdgeInsets.all(ChatConfig.padding),
        decoration: BoxDecoration(
          color:
              isMyMessage
                  ? ChatConfig.myMessageColor
                  : ChatConfig.otherMessageColor,
          borderRadius: BorderRadius.circular(ChatConfig.borderRadius),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: RichText(
                      text: _buildClickableText(message.text, context),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: ChatConfig.spacing),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: ChatConfig.timeFontSize,
                              color: Colors.grey,
                            ),
                          ),
                          if (isConverted && displayOriginalView) ...[
                            const SizedBox(width: ChatConfig.iconSpacing),
                            if (displayOriginalToggle) ...[
                              GestureDetector(
                                onTap: onToggleOriginal,
                                child: Icon(
                                  Icons.auto_fix_high,
                                  size: ChatConfig.iconSize,
                                  color:
                                      showOriginal
                                          ? Colors.grey
                                          : ChatConfig.iconColor,
                                ),
                              ),
                            ] else ...[
                              Icon(
                                Icons.auto_fix_high,
                                size: ChatConfig.iconSize,
                                color:
                                    showOriginal
                                        ? Colors.grey
                                        : ChatConfig.iconColor,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (showOriginal && displayOriginalView) ...[
                const SizedBox(height: ChatConfig.spacing),
                _buildOriginalMessageContainer(originalMessage),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the container for the original message.
  Widget _buildOriginalMessageContainer(String originalMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChatConfig.padding),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: ChatConfig.iconColor,
            width: ChatConfig.borderWidth,
          ),
        ),
        color: ChatConfig.originalMessageBackground,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Original Message',
            style: TextStyle(
              fontSize: ChatConfig.labelFontSize,
              color: ChatConfig.iconColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: ChatConfig.spacingSmall),
          Text(
            originalMessage,
            style: const TextStyle(
              fontSize: ChatConfig.messageFontSize,
              color: Colors.black87,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
