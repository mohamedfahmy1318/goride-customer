import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/admin_chat_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? userId;
  UserModel? userModel;

  @override
  void initState() {
    super.initState();
    userId = FireStoreUtils.getCurrentUid();
    _loadUserInfo();
    _resetUnreadCount();
  }

  Future<void> _loadUserInfo() async {
    if (userId != null && userId!.isNotEmpty) {
      userModel = await FireStoreUtils.getUserProfile(userId!);
      if (mounted) setState(() {});
    }
  }

  void _resetUnreadCount() {
    if (userId != null && userId!.isNotEmpty) {
      FireStoreUtils.resetUserUnreadCount(userId!);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    if (userId == null || userId!.isEmpty) {
      return Center(child: Text('Please login first'.tr));
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FireStoreUtils.fireStore
                .collection(CollectionName.clientAdminChat)
                .doc(userId)
                .collection("thread")
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Constant.loader());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No messages yet. Send a message to admin support!'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

              _resetUnreadCount();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController
                      .jumpTo(_scrollController.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(10),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  AdminChatMessageModel message =
                      AdminChatMessageModel.fromJson(
                    snapshot.data!.docs[index].data() as Map<String, dynamic>,
                  );
                  bool isMe = message.senderType == 'customer';
                  return _buildMessageBubble(message, isMe, themeChange);
                },
              );
            },
          ),
        ),
        _buildMessageInput(themeChange),
      ],
    );
  }

  Widget _buildMessageBubble(
      AdminChatMessageModel message, bool isMe, DarkThemeProvider themeChange) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 5, bottom: 5),
      child: Align(
        alignment: isMe ? Alignment.topRight : Alignment.topLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isMe
                    ? (themeChange.getThem()
                        ? AppColors.darkModePrimary
                        : AppColors.primary)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(10),
                  topRight: const Radius.circular(10),
                  bottomLeft: isMe ? const Radius.circular(10) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                message.message ?? '',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: isMe
                      ? (themeChange.getThem() ? Colors.black : Colors.white)
                      : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isMe ? 'Me'.tr : (message.senderName ?? 'Admin'),
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w400),
            ),
            Text(
              Constant.dateAndTimeFormatTimestamp(message.createdAt),
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(DarkThemeProvider themeChange) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: TextField(
            textInputAction: TextInputAction.send,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: _messageController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(left: 10),
              filled: true,
              disabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkModePrimary
                      : AppColors.primary,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(
                  color: themeChange.getThem()
                      ? AppColors.darkTextFieldBorder
                      : AppColors.textFieldBorder,
                  width: 1,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: () async {
                  if (_messageController.text.trim().isNotEmpty) {
                    _sendMessage(_messageController.text.trim());
                    _messageController.clear();
                  } else {
                    ShowToastDialog.showToast("Please enter text".tr);
                  }
                },
                icon: const Icon(Icons.send_rounded),
              ),
              hintText: 'Type a message...'.tr,
            ),
            onSubmitted: (value) async {
              if (_messageController.text.trim().isNotEmpty) {
                _sendMessage(_messageController.text.trim());
                _messageController.clear();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (userId == null || userId!.isEmpty) return;

    String msgId = Constant.getUuid();
    Timestamp now = Timestamp.now();

    String userName = userModel?.fullName ?? '';
    String userProfileImage = userModel?.profilePic ?? '';

    AdminChatMessageModel messageModel = AdminChatMessageModel(
      id: msgId,
      senderId: userId,
      senderType: 'customer',
      senderName: userName,
      message: message,
      messageType: 'text',
      createdAt: now,
    );

    await FireStoreUtils.addAdminChatMessage(userId!, messageModel);

    await FireStoreUtils.updateAdminChatInbox(userId!, {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'lastMessage': message,
      'lastSenderId': userId,
      'lastSenderType': 'customer',
      'updatedAt': now,
      'createdAt': now,
      'adminUnreadCount': FieldValue.increment(1),
    });
  }
}
