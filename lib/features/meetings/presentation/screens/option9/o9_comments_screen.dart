import 'package:flutter/material.dart';

import '../../../../../../app/state/app_scope.dart';

class _O9Comment {
  _O9Comment({
    required this.id,
    required this.author,
    required this.area,
    required this.text,
    required this.timestamp,
    required this.isMine,
  });

  final int id;
  final String author;
  final String area;
  final String text;
  final DateTime timestamp;
  final bool isMine;
}

class O9CommentsScreen extends StatefulWidget {
  const O9CommentsScreen({
    super.key,
    this.agreementId,
    required this.agreementTitle,
    required this.agreementGroup,
    required this.groupColor,
  });

  final int? agreementId;
  final String agreementTitle;
  final String agreementGroup;
  final Color groupColor;

  @override
  State<O9CommentsScreen> createState() => _O9CommentsScreenState();
}

class _O9CommentsScreenState extends State<O9CommentsScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_O9Comment> _comments = [];
  bool _loaded = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _comments.addAll(_fallbackComments());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<_O9Comment> _fallbackComments() => [
    _O9Comment(
      id: 1,
      author: 'L. Torres',
      area: 'SST',
      text: 'Revision inicial del acuerdo registrada.',
      timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      isMine: false,
    ),
    _O9Comment(
      id: 2,
      author: 'C. Mendoza',
      area: 'Residente',
      text: 'Se requiere confirmar fecha de cierre.',
      timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
      isMine: false,
    ),
    _O9Comment(
      id: 3,
      author: 'Tu',
      area: 'Calidad',
      text: 'Seguimiento en curso.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isMine: true,
    ),
  ];

  Future<void> _loadComments() async {
    final agreementId = widget.agreementId;
    if (agreementId == null) return;
    setState(() => _loading = true);
    try {
      final controller = AppScope.of(context);
      final rows = await controller.loadActreuAgreementComments(agreementId);
      if (!mounted) return;
      final userEmail = (controller.user?.email ?? '').toLowerCase();
      final mapped = rows
          .map(
            (row) => _O9Comment(
              id: row.commentId,
              author: row.author,
              area: 'Participante',
              text: row.message,
              timestamp: row.createdAt ?? DateTime.now(),
              isMine:
                  userEmail.isNotEmpty &&
                  row.author.toLowerCase().contains(userEmail),
            ),
          )
          .toList();
      setState(() {
        _comments
          ..clear()
          ..addAll(mapped);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final agreementId = widget.agreementId;
    if (agreementId == null) return;
    final controller = AppScope.of(context);
    final createdId = await controller.createActreuAgreementComment(
      agreementId: agreementId,
      message: text,
    );
    if (!mounted) return;
    if (createdId == null) return;
    _ctrl.clear();
    await _loadComments();
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) {
      return 'Ayer ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE0EAF6)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comentarios',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.groupColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    widget.agreementTitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.groupColor,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.groupColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_comments.length} comentarios',
              style: TextStyle(
                fontSize: 11,
                color: widget.groupColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _comments.length,
                    itemBuilder: (_, i) {
                      final c = _comments[i];
                      return _CommentBubble(
                        comment: c,
                        formatTime: _formatTime,
                      );
                    },
                  ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE0EAF6)),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF0A66B7).withValues(alpha: 0.15),
                  child: const Text(
                    'Tu',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0A66B7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario o avance...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5FAFE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendComment(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A66B7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.formatTime,
  });

  final _O9Comment comment;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final isMine = comment.isMine;
    final initials = comment.author
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();
    final bubbleColor = isMine ? const Color(0xFF0A66B7) : Colors.white;
    final textColor = isMine ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF0A66B7).withValues(alpha: 0.12),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A66B7),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          comment.author,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0EAF6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            comment.area,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    comment.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    formatTime(comment.timestamp),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF0A66B7),
              child: Text(
                'Tu',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
