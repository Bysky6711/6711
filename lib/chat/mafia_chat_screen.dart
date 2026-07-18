import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../services/online_room_service.dart';
import '../widgets/shared_widgets.dart';
import 'chat_message.dart';

/// Realtime chat backed by Firestore (rooms/{code}/messages).
///
/// Channels: #ogólny for everyone, #mafia only for players who [canSeeMafia]
/// (mafia + host). Channel privacy is enforced on the client for this party
/// game; harden with Firestore rules if you need server-side guarantees.
class MafiaChatScreen extends StatefulWidget {
  const MafiaChatScreen({
    super.key,
    required this.service,
    required this.roomCode,
    required this.currentPlayerName,
    this.canSeeMafia = false,
    this.players = const [],
    this.amDead = false,
    this.isHost = false,
  });

  final OnlineRoomService service;
  final String roomCode;
  final String currentPlayerName;
  final bool canSeeMafia;
  final List<String> players;

  /// This player has been eliminated — spectator mode (writes only in #zmarli).
  final bool amDead;

  /// The host oversees every channel (including #zmarli) and can always write.
  final bool isHost;

  @override
  State<MafiaChatScreen> createState() => _MafiaChatScreenState();
}

class _MafiaChatScreenState extends State<MafiaChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final List<MafiaChatChannel> channels;
  late MafiaChatChannel selectedChannel;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    final isDeadPlayer = widget.amDead && !widget.isHost;
    channels = [
      const MafiaChatChannel(id: 'general', name: 'ogólny', type: MafiaChatChannelType.general),
      if (widget.canSeeMafia && !isDeadPlayer)
        const MafiaChatChannel(id: 'mafia', name: 'mafia', type: MafiaChatChannelType.mafia),
      if (widget.amDead || widget.isHost)
        const MafiaChatChannel(id: 'dead', name: 'zmarli', type: MafiaChatChannelType.dead),
      if (!isDeadPlayer)
        for (final name in widget.players.where((p) => p != widget.currentPlayerName))
          MafiaChatChannel(
            id: dmChannelId(widget.currentPlayerName, name),
            name: name,
            type: MafiaChatChannelType.private,
            targetPlayerName: name,
          ),
    ];
    selectedChannel = channels.first;
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void selectChannel(MafiaChatChannel channel) {
    setState(() => selectedChannel = channel);
  }

  bool _canWrite(MafiaChatChannel channel) {
    if (widget.isHost) return true;
    if (widget.amDead) return channel.type == MafiaChatChannelType.dead;
    return channel.type != MafiaChatChannelType.dead;
  }

  void scrollToEnd() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending || !_canWrite(selectedChannel)) return;
    setState(() => sending = true);
    controller.clear();
    try {
      await widget.service.sendMessage(
        code: widget.roomCode,
        channelId: selectedChannel.id,
        senderName: widget.currentPlayerName,
        text: text,
      );
    } catch (_) {
      // keep it quiet; the message simply won't appear if the write failed
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  /// Pick a photo, shrink it to a small JPG and send it as an inline sticker
  /// (base64 in the message doc — no Firebase Storage needed, stays free).
  Future<void> pickAndSendSticker() async {
    if (sending || !_canWrite(selectedChannel)) return;
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
      if (file == null) return;
      await _sendImageBytes(await file.readAsBytes());
    } catch (_) {
      // keep it quiet; a failed pick simply sends nothing
    }
  }

  /// Shrink arbitrary image bytes to a small JPG and send as an inline sticker.
  /// Used both by the gallery picker and by stickers/GIFs inserted straight from
  /// the phone's system keyboard (see [_Composer.onInsertImage]).
  Future<void> _sendImageBytes(Uint8List bytes) async {
    if (sending || !_canWrite(selectedChannel)) return;
    setState(() => sending = true);
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;
      final resized = decoded.width > 320 ? img.copyResize(decoded, width: 320) : decoded;
      final b64 = base64Encode(img.encodeJpg(resized, quality: 60));
      await widget.service.sendMessage(
        code: widget.roomCode,
        channelId: selectedChannel.id,
        senderName: widget.currentPlayerName,
        text: '',
        imageBase64: b64,
      );
    } catch (_) {
      // keep it quiet; a failed encode simply sends nothing
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ChannelRail(channels: channels, selected: selectedChannel, onSelected: selectChannel),
        Expanded(
          child: Column(
            children: [
              _DiscordHeader(channel: selectedChannel),
              Expanded(
                child: StreamBuilder<List<MafiaChatMessage>>(
                  stream: widget.service.watchMessages(widget.roomCode, myName: widget.currentPlayerName),
                  builder: (context, snapshot) {
                    final all = snapshot.data ?? const <MafiaChatMessage>[];
                    final visible = all.where((m) => m.channelId == selectedChannel.id).toList();
                    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToEnd());
                    if (visible.isEmpty) {
                      return Center(
                        child: Text(
                          selectedChannel.type == MafiaChatChannelType.private
                              ? 'Napisz pierwszą wiadomość do ${selectedChannel.name}.'
                              : 'Brak wiadomości na #${selectedChannel.name}.',
                          style: TextStyle(color: AppColors.white.withValues(alpha: .5), fontWeight: FontWeight.w700),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      itemCount: visible.length,
                      itemBuilder: (context, index) => _DiscordMessage(message: visible[index]),
                    );
                  },
                ),
              ),
              _Composer(channel: selectedChannel, controller: controller, onSend: sendMessage, onAddSticker: pickAndSendSticker, onInsertImage: _sendImageBytes, canWrite: _canWrite(selectedChannel)),
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
      case MafiaChatChannelType.dead:
        return Icons.person_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), bottomLeft: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          width: 82,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.black.withValues(alpha: .26),
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: channels.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .20),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08))),
      ),
      child: Row(
        children: [
          Text(channel.type == MafiaChatChannelType.private ? '@' : '#', style: TextStyle(color: AppColors.white.withValues(alpha: .58), fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          if (channel.type == MafiaChatChannelType.mafia)
            Icon(Icons.local_fire_department_rounded, color: AppColors.white.withValues(alpha: .72)),
          if (channel.type == MafiaChatChannelType.private)
            Icon(Icons.lock_rounded, color: AppColors.white.withValues(alpha: .72), size: 18),
          if (channel.type == MafiaChatChannelType.dead)
            Icon(Icons.person_off_rounded, color: AppColors.white.withValues(alpha: .72), size: 18),
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
                if (message.imageBase64 != null && message.imageBase64!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      base64Decode(message.imageBase64!),
                      width: 170,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Text('🖼️', style: TextStyle(fontSize: 40)),
                    ),
                  )
                else
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

class _Composer extends StatelessWidget {
  const _Composer({required this.channel, required this.controller, required this.onSend, required this.onAddSticker, required this.onInsertImage, this.canWrite = true});
  final MafiaChatChannel channel;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAddSticker;
  final ValueChanged<Uint8List> onInsertImage;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    if (!canWrite) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Icon(Icons.visibility_rounded, color: AppColors.white.withValues(alpha: .5), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text('Tylko podgląd — pisz na #zmarli.', style: TextStyle(color: AppColors.white.withValues(alpha: .5), fontWeight: FontWeight.w700))),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            padding: const EdgeInsets.only(left: 12, right: 5),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                GestureDetector(onTap: onAddSticker, child: Icon(Icons.add_circle_rounded, color: AppColors.white.withValues(alpha: .58))),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => onSend(),
                    textInputAction: TextInputAction.send,
                    // Lets the phone's system keyboard send stickers / GIFs / images
                    // straight into the chat (iOS & Android rich content).
                    // Advertise every image type keyboards commonly send, otherwise
                    // the OS refuses with "cannot insert content here". We decode &
                    // re-encode to JPEG on send, so all of these are handled.
                    contentInsertionConfiguration: ContentInsertionConfiguration(
                      allowedMimeTypes: const [
                        'image/png',
                        'image/jpeg',
                        'image/jpg',
                        'image/gif',
                        'image/webp',
                        'image/bmp',
                      ],
                      onContentInserted: (KeyboardInsertedContent content) {
                        final data = content.data;
                        if (data != null && data.isNotEmpty) onInsertImage(data);
                      },
                    ),
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: channel.type == MafiaChatChannelType.private ? 'Napisz do ${channel.name}' : 'Napisz na #${channel.name}',
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
