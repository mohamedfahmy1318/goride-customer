import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatInboxModel {
  String? userId;
  String? userName;
  String? userProfileImage;
  String? adminName;
  String? lastMessage;
  String? lastSenderId;
  String? lastSenderType;
  Timestamp? updatedAt;
  Timestamp? createdAt;
  int? userUnreadCount;
  int? adminUnreadCount;

  AdminChatInboxModel({
    this.userId,
    this.userName,
    this.userProfileImage,
    this.adminName,
    this.lastMessage,
    this.lastSenderId,
    this.lastSenderType,
    this.updatedAt,
    this.createdAt,
    this.userUnreadCount,
    this.adminUnreadCount,
  });

  factory AdminChatInboxModel.fromJson(Map<String, dynamic> json) {
    return AdminChatInboxModel(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfileImage: json['userProfileImage'] ?? '',
      adminName: json['adminName'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastSenderId: json['lastSenderId'] ?? '',
      lastSenderType: json['lastSenderType'] ?? '',
      updatedAt: json['updatedAt'],
      createdAt: json['createdAt'],
      userUnreadCount: json['userUnreadCount'] ?? 0,
      adminUnreadCount: json['adminUnreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'adminName': adminName,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'lastSenderType': lastSenderType,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
      'userUnreadCount': userUnreadCount,
      'adminUnreadCount': adminUnreadCount,
    };
  }
}

class AdminChatMessageModel {
  String? id;
  String? senderId;
  String? senderType;
  String? senderName;
  String? message;
  String? messageType;
  Timestamp? createdAt;

  AdminChatMessageModel({
    this.id,
    this.senderId,
    this.senderType,
    this.senderName,
    this.message,
    this.messageType,
    this.createdAt,
  });

  factory AdminChatMessageModel.fromJson(Map<String, dynamic> json) {
    return AdminChatMessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      messageType: json['messageType'] ?? 'text',
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderType': senderType,
      'senderName': senderName,
      'message': message,
      'messageType': messageType,
      'createdAt': createdAt,
    };
  }
}
