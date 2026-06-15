import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/shared_widgets.dart';
import 'chat_message.dart';

class MafiaChatScreen extends StatefulWidget {
  const MafiaChatScreen({
    super.key,
    required this.currentPlayerName,
    this.players = const [],
  });

  final String currentPlayerName;
  final List<String> players;

  @override
  State<MafiaChatScreen> createState() => _MafiaChatScreenState();
}

class _MafiaChatScreenState extends State<MafiaChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final List<MafiaChatChannel> channels;
  late MafiaChatChannel selectedChannel;
  final List<MafiaChatMessage> messages = [];
  bool typing = false;

  @override
  void initState() {
    super.initState();
    final privatePlayers = widget.players.where((name) => name.trim().isNotEmpty && name != widget.currentPlayerName).toList();
    channels = [
      const MafiaChatChannel(id: 'general', name: 'ogólny', type: MafiaChatChannelType.general),
      const MafiaChatChannel(id: 'mafia', name: 'mafia', type: MafiaChatChannelType.mafia),
      ...privatePlayers.map((name) => MafiaChatChannel(
            id: 'private_$name',
            name: name,
            type: MafiaChatChannelType.private,
            targetPlayerName: name,
          )),
    ];
    selectedChannel = channels.first;
    messages.add(
      MafiaChatMessage(
        id: 'system_general',
        channelId: 'general',
        senderName: 'System',
        text: 'Kanał ogólny został uruchomiony.',
        createdAt: DateTime.now(),
        isSystem: true,
      ),
    );
    messages.add(
      MafiaChatMessage(
        id: 'system_mafia',
        channelId: 'mafia',
        senderName: 'System',
        text: 'Kanał mafii jest widoczny tylko dla mafii po podpięciu online.',
        createdAt: DateTime.now(),
        isSystem: true,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  List<MafiaChatMessage> get visibleMessages {
    return messages.where((message) => message.channelId == selectedChannel.id).toList();
  }

  void selectChannel(MafiaChatChannel channel) {
    setState(() {
      selectedChannel = channel;
      typing = false;
    });
    Future<void>.delayed(const Duration(milliseconds: 80), scrollToEnd);
  }

  void scrollToEnd() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void sendMessage() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(
        MafiaChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          channelId: selectedChannel.id,
          senderName: widget.currentPlayerName,
          text: text,
          createdAt: DateTime.now(),
          isMine: true,
        ),
      );
      controller.clear();
      typing = false;
    });
    Future<void>.delayed(const Duration(milliseconds: 80), scrollToEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ChannelRail(
          channels: channels,
          selected: selectedChannel,
          onSelected: selectChannel,
        ),
        Expanded(
          child: Column(
            children: [
              _DiscordHeader(channel: selectedChannel),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  itemCount: visibleMessages.length + (typing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (typing && index == visibleMessages.length) {
                      return const _TypingIndicator();
                    }
                    final message = visibleMessages[index];
                    return PremiumFadeSlide(
                      delay: Duration(milliseconds: 14 * index),
                      offset: const Offset(0, 10),
                      child: _DiscordMessage(message: message),
                    );
                  },
                ),
              ),
              _Composer(
                channel: selectedChannel,
                controller: controller,
                onChanged: (value) => setState(() => typing = value.trim().isNotEmpty),
                onSend: sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChannelRail extends StatelessWidget {
  const _ChannelRail({required this.channels, required this.selected, required this.onSelected});
  final List<MafiaChatChannel> channels;
  final MafiaChatChannel selected;
  final ValueChanged<MafiaChatChannel> onSelected;

  IconData iconOf(MafiaChatChannel channel) {
    switch (channel.type) {
      case MafiaChatChannelType.general:
        return Icons.tag_rounded;
      case MafiaChatChannelType.mafia:
        return Icons.local_fire_department_rounded;
      case MafiaChatChannelType.private:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.black.withValues(alpha: .26),
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: channels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final channel = channels[index];
              final active = selected.id == channel.id;
              return PressableScale(
                onTap: () => onSelected(channel),
                haptic: HapticFeedbackType.selection,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: active ? 54 : 48,
                      height: active ? 54 : 48,
                      decoration: BoxDecoration(
                        color: active ? AppColors.white : Colors.white.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(active ? 18 : 24),
                      ),
                      child: Icon(iconOf(channel), color: active ? AppColors.black : AppColors.white, size: 25),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 72,
                      child: Text(
                        channel.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? AppColors.white : AppColors.white.withValues(alpha: .58),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DiscordHeader extends StatelessWidget {
  const _DiscordHeader({required this.channel});
  final MafiaChatChannel channel;

  @override
  Widget build(BuildContext context) {
    final prefix = channel.type == MafiaChatChannelType.private ? '@' : '#';
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .20),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08))),
      ),
      child: Row(
        children: [
          Text(prefix, style: TextStyle(color: AppColors.white.withValues(alpha: .58), fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Icon(Icons.search_rounded, color: AppColors.white.withValues(alpha: .72)),
        ],
      ),
    );
  }
}

class _DiscordMessage extends StatelessWidget {
  const _DiscordMessage({required this.message});
  final MafiaChatMessage message;

  @override
  Widget build(BuildContext context) {
    final accent = message.isSystem ? Colors.lightBlueAccent : (message.isMine ? AppColors.cityGlowRed : AppColors.white);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withValues(alpha: .22),
            child: Text(
              message.senderName.isEmpty ? '?' : message.senderName.characters.first.toUpperCase(),
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        message.senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: AppColors.white.withValues(alpha: .38), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  message.text,
                  style: TextStyle(color: AppColors.white.withValues(alpha: .88), fontSize: 15, fontWeight: FontWeight.w600, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, bottom: 12),
      child: Text('pisze…', style: TextStyle(color: AppColors.white.withValues(alpha: .46), fontWeight: FontWeight.w800)),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.channel, required this.controller, required this.onChanged, required this.onSend});
  final MafiaChatChannel channel;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final prefix = channel.type == MafiaChatChannelType.private ? '@${channel.name}' : '#${channel.name}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.only(left: 12, right: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Icon(Icons.add_circle_rounded, color: AppColors.white.withValues(alpha: .58)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Napisz na $prefix',
                      hintStyle: TextStyle(color: AppColors.white.withValues(alpha: .42), fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                PressableScale(
                  onTap: onSend,
                  haptic: HapticFeedbackType.medium,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_upward_rounded, color: AppColors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
