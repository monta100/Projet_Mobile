class Message {
  int? id;
  int senderId;
  int receiverId;
  String content;
  String type; // 'message' or 'exercise'
  DateTime createdAt;
  bool read;

  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = 'message',
    DateTime? createdAt,
    this.read = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'read': read ? 1 : 0,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      senderId: map['sender_id'],
      receiverId: map['receiver_id'],
      content: map['content'],
      type: map['type'] ?? 'message',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      read: map['read'] == 1,
    );
  }
}
