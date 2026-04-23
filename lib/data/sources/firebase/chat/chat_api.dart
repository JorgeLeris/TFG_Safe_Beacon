import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/data/sources/firebase/chat/dto/chat_dto.dart';
import 'package:safe_beacon/data/sources/firebase/chat/dto/message_dto.dart';

class ChatApi {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  // ==============================================
  // MARK: - Chat management
  // ==============================================

  /// Finds an existing chat between [uid1] and [uid2].
  ///
  /// Uses sorted participant UIDs.
  Future<({String id, ChatDto dto})?> findChat(
    String uid1,
    String uid2,
  ) async {
    final sorted = [uid1, uid2]..sort();

    final snap = await _chats
        .where('participantUids', isEqualTo: sorted)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    return (id: doc.id, dto: ChatDto.fromFirestore(doc.data()));
  }

  /// Creates a new chat between the two participants.
  ///
  /// The participant UIDs are stored sorted for consistent querying.
  /// Returns the document ID of the newly created chat.
  Future<String> createChat(String uid1, String uid2) async {
    final sorted = [uid1, uid2]..sort();
    final ref = _chats.doc();

    await ref.set({
      'participantUids': sorted,
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount_${sorted[0]}': 0,
      'unreadCount_${sorted[1]}': 0,
    });

    return ref.id;
  }

  /// Returns a chat by its document ID.
  Future<({String id, ChatDto dto})?> findChatById(String chatId) async {
    final doc = await _chats.doc(chatId).get();
    if (!doc.exists) return null;
    return (id: doc.id, dto: ChatDto.fromFirestore(doc.data()!));
  }

  // ==============================================
  // MARK: - Real-time streams
  // ==============================================

  /// Returns a real-time stream of all chats where [uid] is a participant,
  /// ordered by the most recent message.
  Stream<List<({String id, ChatDto dto})>> watchChats(String uid) {
    return _chats
        .where('participantUids', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final results = snap.docs.map((doc) {
        return (id: doc.id, dto: ChatDto.fromFirestore(doc.data()));
      }).toList();

      // Sort locally by lastMessageAt descending (most recent first).
      results.sort((a, b) {
        final aTime = a.dto.lastMessageAt ?? a.dto.createdAt;
        final bTime = b.dto.lastMessageAt ?? b.dto.createdAt;
        return bTime.compareTo(aTime);
      });

      return results;
    });
  }

  /// Returns a real-time stream of messages in [chatId],
  /// ordered by creation time ascending.
  Stream<List<({String id, MessageDto dto})>> watchMessages(String chatId) {
    return _messages(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) {
        return (id: doc.id, dto: MessageDto.fromFirestore(doc.data()));
      }).toList();
    });
  }

  // ==============================================
  // MARK: - Send message
  // ==============================================

  /// Sends a message and updates the parent chat document atomically.
  ///
  /// Increments the unread counter for the other participant.
  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
    required String otherUid,
  }) async {
    final batch = _firestore.batch();

    // Add message to subcollection.
    final msgRef = _messages(chatId).doc();
    batch.set(msgRef, {
      'senderUid': senderUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [senderUid],
    });

    // Update chat metadata.
    batch.update(_chats.doc(chatId), {
      'lastMessage': text,
      'lastMessageSenderUid': senderUid,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount_$otherUid': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // ==============================================
  // MARK: - Mark as read
  // ==============================================

  /// Marks all unread messages in [chatId] as read for [uid]
  /// and resets that user's unread counter.
  Future<void> markAsRead({
    required String chatId,
    required String uid,
  }) async {
    // Reset the unread counter.
    await _chats.doc(chatId).update({'unreadCount_$uid': 0});

    // Mark individual messages as read.
    final unreadSnap = await _messages(chatId)
        .where('senderUid', isNotEqualTo: uid)
        .get();

    if (unreadSnap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadSnap.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] as List? ?? []);
      if (!readBy.contains(uid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([uid]),
        });
      }
    }
    await batch.commit();
  }
}
