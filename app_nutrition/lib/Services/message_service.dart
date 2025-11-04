import '../Entites/message.dart';
import 'database_helper.dart';

class MessageService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> sendMessage(Message message) async {
    return await _db.insertMessage(message);
  }

  Future<List<Message>> fetchConversation(int userA, int userB) async {
    return await _db.getMessagesBetween(userA, userB);
  }

  Future<List<Message>> fetchAllForUser(int userId) async {
    return await _db.getMessagesForUser(userId);
  }

  Future<int> markAsRead(int messageId) async {
    return await _db.markMessageAsRead(messageId);
  }
}
