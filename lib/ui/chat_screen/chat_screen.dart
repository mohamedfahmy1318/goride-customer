import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/ChatVideoContainer.dart';
import 'package:customer/model/conversation_model.dart';
import 'package:customer/model/inbox_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/ui/chat_screen/FullScreenImageViewer.dart';
import 'package:customer/ui/chat_screen/FullScreenVideoViewer.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/firebase_pagination/src/firestore_pagination.dart';
import 'package:customer/widget/firebase_pagination/src/models/view_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ChatScreens extends StatefulWidget {
  final String? orderId;
  final String? customerId;
  final String? customerName;
  final String? customerProfileImage;
  final String? driverId;
  final String? driverName;
  final String? driverProfileImage;
  final String? token;

  const ChatScreens(
      {super.key,
      this.orderId,
      this.customerId,
      this.customerName,
      this.driverName,
      this.driverId,
      this.customerProfileImage,
      this.driverProfileImage,
      this.token});

  @override
  State<ChatScreens> createState() => _ChatScreensState();
}

class _ChatScreensState extends State<ChatScreens> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _controller = ScrollController();

  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    if (_controller.hasClients) {
      Timer(const Duration(milliseconds: 500),
          () => _controller.jumpTo(_controller.position.maxScrollExtent));
    }
    _loadBlockState();
  }

  Future<void> _loadBlockState() async {
    final driverId = widget.driverId;
    if (driverId == null || driverId.isEmpty) return;
    final blocked = await FireStoreUtils.isUserBlocked(driverId);
    if (mounted && blocked != _isBlocked) {
      setState(() => _isBlocked = blocked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeChange.getThem()
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        elevation: 2,
        backgroundColor:
            themeChange.getThem() ? AppColors.darkBackground : Colors.white,
        title: Text(
            "${widget.driverName.toString()}\n#${widget.orderId.toString()}",
            maxLines: 2,
            style: GoogleFonts.poppins(
                color: themeChange.getThem() ? Colors.white : Colors.black,
                fontSize: 14)),
        leading: InkWell(
            onTap: () {
              Get.back();
            },
            child: Icon(
              Icons.arrow_back,
              color: themeChange.getThem() ? Colors.white : Colors.black,
            )),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: themeChange.getThem() ? Colors.white : Colors.black),
            onSelected: (value) {
              if (value == 'report') {
                _showReportDriverSheet();
              } else if (value == 'block') {
                _confirmBlockDriver();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'report',
                child: Text('Report driver'.tr),
              ),
              PopupMenuItem(
                value: 'block',
                enabled: !_isBlocked,
                child: Text(_isBlocked ? 'Driver blocked'.tr : 'Block driver'.tr),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
        child: Column(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    // currentRecordingState = RecordingState.HIDDEN;
                  });
                },
                child: FirestorePagination(
                  controller: _controller,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, documentSnapshots, index) {
                    ConversationModel inboxModel = ConversationModel.fromJson(
                        documentSnapshots[index].data()
                            as Map<String, dynamic>);
                    return chatItemView(
                        inboxModel.senderId == FireStoreUtils.getCurrentUid(),
                        inboxModel);
                  },
                  onEmpty: Center(child: Text("No Conversion found".tr)),
                  // orderBy is compulsory to enable pagination
                  query: FireStoreUtils.fireStore
                      .collection('chat')
                      .doc(widget.orderId)
                      .collection("thread")
                      .orderBy('createdAt', descending: false),
                  //Change types customerId
                  viewType: ViewType.list,
                  // to fetch real-time data
                  isLive: true,
                ),
              ),
            ),
            if (_isBlocked)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.block, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You blocked this driver. Messages and calls are disabled."
                              .tr,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
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
                          borderRadius:
                              const BorderRadius.all(Radius.circular(30)),
                          borderSide: BorderSide(
                              color: themeChange.getThem()
                                  ? AppColors.darkTextFieldBorder
                                  : AppColors.textFieldBorder,
                              width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(30)),
                          borderSide: BorderSide(
                              color: themeChange.getThem()
                                  ? AppColors.darkModePrimary
                                  : AppColors.primary,
                              width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(30)),
                          borderSide: BorderSide(
                              color: themeChange.getThem()
                                  ? AppColors.darkTextFieldBorder
                                  : AppColors.textFieldBorder,
                              width: 1),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(30)),
                          borderSide: BorderSide(
                              color: themeChange.getThem()
                                  ? AppColors.darkTextFieldBorder
                                  : AppColors.textFieldBorder,
                              width: 1),
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(30)),
                          borderSide: BorderSide(
                              color: themeChange.getThem()
                                  ? AppColors.darkTextFieldBorder
                                  : AppColors.textFieldBorder,
                              width: 1),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () async {
                            if (_messageController.text.isNotEmpty) {
                              if (!await _ensureEulaAccepted()) return;
                              _sendMessage(
                                  _messageController.text, null, '', 'text');
                              _messageController.clear();
                              setState(() {});
                            } else {
                              ShowToastDialog.showToast(
                                  "Please enter text".tr);
                            }
                          },
                          icon: const Icon(Icons.send_rounded),
                        ),
                        prefixIcon: IconButton(
                          onPressed: () async {
                            if (!await _ensureEulaAccepted()) return;
                            _onCameraClick();
                          },
                          icon: const Icon(Icons.camera_alt),
                        ),
                        hintText: 'Start typing ...'.tr,
                      ),
                      onSubmitted: (value) async {
                        if (_messageController.text.isNotEmpty) {
                          if (!await _ensureEulaAccepted()) return;
                          _sendMessage(
                              _messageController.text, null, '', 'text');
                          Timer(
                              const Duration(milliseconds: 500),
                              () => _controller.jumpTo(
                                  _controller.position.maxScrollExtent));
                          _messageController.clear();
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget chatItemView(bool isMe, ConversationModel data) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GestureDetector(
      // Long-press incoming messages to report (Apple App Review 1.2 — UGC moderation)
      onLongPress: isMe ? null : () => _showReportMessageSheet(data),
      child: Container(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
      child: isMe
          ? Align(
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  data.messageType == "text"
                      ? Container(
                          decoration: BoxDecoration(
                            color: themeChange.getThem()
                                ? AppColors.darkModePrimary
                                : AppColors.primary,
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Text(
                            data.message.toString(),
                            style: TextStyle(
                                color: data.senderId ==
                                        FireStoreUtils.getCurrentUid()
                                    ? themeChange.getThem()
                                        ? Colors.black
                                        : Colors.white
                                    : Colors.black),
                          ),
                        )
                      : data.messageType == "image"
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: 50,
                                maxWidth: 200,
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                    bottomLeft: Radius.circular(10)),
                                child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Get.to(FullScreenImageViewer(
                                            imageUrl: data.url?.url ?? '',
                                          ));
                                        },
                                        child: Hero(
                                          tag: data.url?.url ?? data.id ?? '',
                                          child: CachedNetworkImage(
                                            imageUrl: Constant.safeImageUrl(
                                                data.url?.url),
                                            placeholder: (context, url) =>
                                                Constant.loader(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                    ]),
                              ))
                          : _buildVideoPlayButton(data),
                  const SizedBox(
                    height: 2,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Me".tr,
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w400)),
                      Text(Constant.dateAndTimeFormatTimestamp(data.createdAt),
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    data.messageType == "text"
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10)),
                              color: Colors.grey.shade300,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Text(
                              data.message.toString(),
                              style: GoogleFonts.poppins(
                                  color: data.senderId ==
                                          FireStoreUtils.getCurrentUid()
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          )
                        : data.messageType == "image"
                            ? ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 50,
                                  maxWidth: 200,
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10)),
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Get.to(FullScreenImageViewer(
                                              imageUrl: data.url?.url ?? '',
                                            ));
                                          },
                                          child: Hero(
                                            tag: data.url?.url ?? data.id ?? '',
                                            child: CachedNetworkImage(
                                              imageUrl: Constant.safeImageUrl(
                                                  data.url?.url),
                                              placeholder: (context, url) =>
                                                  Constant.loader(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                      ]),
                                ))
                            : _buildVideoPlayButton(data),
                  ],
                ),
                const SizedBox(
                  height: 2,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.driverName.toString(),
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w400)),
                    Text(Constant.dateAndTimeFormatTimestamp(data.createdAt),
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildVideoPlayButton(ConversationModel data) {
    final String heroTag =
        data.id != null && data.id!.isNotEmpty ? data.id! : data.url!.url;

    return SizedBox(
      height: 36,
      width: 36,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            Get.to(FullScreenVideoViewer(
              heroTag: heroTag,
              videoUrl: data.url!.url,
            ));
          },
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  _sendMessage(String message, Url? url, String videoThumbnail,
      String messageType) async {
    InboxModel inboxModel = InboxModel(
        lastSenderId: widget.customerId,
        customerId: widget.customerId,
        customerName: widget.customerName,
        driverId: widget.driverId,
        driverName: widget.driverName,
        driverProfileImage: widget.driverProfileImage,
        createdAt: Timestamp.now(),
        orderId: widget.orderId,
        customerProfileImage: widget.customerProfileImage,
        lastMessage: _messageController.text);

    await FireStoreUtils.addInBox(inboxModel);

    ConversationModel conversationModel = ConversationModel(
        id: const Uuid().v4(),
        message: message,
        senderId: FireStoreUtils.getCurrentUid(),
        receiverId: widget.driverId,
        createdAt: Timestamp.now(),
        url: url,
        orderId: widget.orderId,
        messageType: messageType,
        videoThumbnail: videoThumbnail);

    if (url != null) {
      if (url.mime.contains('image')) {
        conversationModel.message = "sent an image";
      } else if (url.mime.contains('video')) {
        conversationModel.message = "sent an Video";
      } else if (url.mime.contains('audio')) {
        conversationModel.message = "Sent a voice message";
      }
    }

    await FireStoreUtils.addChat(conversationModel);

    Map<String, dynamic> playLoad = <String, dynamic>{
      "type": "chat",
      "driverId": widget.driverId,
      "customerId": widget.customerId,
      "orderId": widget.orderId,
    };

    SendNotification.sendOneNotification(
        title:
            "${widget.customerName} ${messageType == "image" ? "sent image to you" : messageType == "video" ? "sent video to you" : "sent message to you"}",
        titleAr:
            "${widget.customerName} ${messageType == "image" ? "\u0623\u0631\u0633\u0644 \u0644\u0643 \u0635\u0648\u0631\u0629" : messageType == "video" ? "\u0623\u0631\u0633\u0644 \u0644\u0643 \u0641\u064a\u062f\u064a\u0648" : "\u0623\u0631\u0633\u0644 \u0644\u0643 \u0631\u0633\u0627\u0644\u0629"}",
        body: conversationModel.message.toString(),
        token: widget.token.toString(),
        recipientId: widget.driverId,
        recipientType: 'driver',
        payload: playLoad);
  }

  final ImagePicker _imagePicker = ImagePicker();

  _onCameraClick() {
    final action = CupertinoActionSheet(
      message: Text(
        'Send Media'.tr,
        style: const TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Get.back();
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              Url url = await Constant()
                  .uploadChatImageToFireStorage(File(image.path));
              _sendMessage('', url, '', 'image');
            }
          },
          child: Text("Choose image from gallery".tr),
        ),
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? galleryVideo =
                await _imagePicker.pickVideo(source: ImageSource.gallery);
            if (galleryVideo != null) {
              ChatVideoContainer? videoContainer = await Constant()
                  .uploadChatVideoToFireStorage(File(galleryVideo.path));
              if (videoContainer != null) {
                _sendMessage('', videoContainer.videoUrl,
                    videoContainer.thumbnailUrl, 'video');
              } else {
                ShowToastDialog.showToast("Message sent failed");
              }
            }
          },
          child: Text("Choose video from gallery".tr),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? image =
                await _imagePicker.pickImage(source: ImageSource.camera);
            if (image != null) {
              Url url = await Constant()
                  .uploadChatImageToFireStorage(File(image.path));
              _sendMessage('', url, '', 'image');
            }
          },
          child: Text("Take a Photo".tr),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Navigator.pop(context);
            XFile? recordedVideo =
                await _imagePicker.pickVideo(source: ImageSource.camera);
            if (recordedVideo != null) {
              ChatVideoContainer? videoContainer = await Constant()
                  .uploadChatVideoToFireStorage(File(recordedVideo.path));
              if (videoContainer != null) {
                _sendMessage('', videoContainer.videoUrl,
                    videoContainer.thumbnailUrl, 'video');
              } else {
                ShowToastDialog.showToast("Message sent failed");
              }
            }
          },
          child: Text("Record video".tr),
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          'Cancel'.tr,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  /// Shows a one-time community-guidelines acceptance sheet before the user's
  /// first chat send. Required for App Review Guideline 1.2 (UGC EULA).
  Future<bool> _ensureEulaAccepted() async {
    if (Preferences.getBoolean(Preferences.chatEulaAcceptedKey)) return true;

    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Community Guidelines".tr,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                "Messages and shared media must follow our zero-tolerance policy on harassment, hate speech, threats, sexually explicit content, and other objectionable behaviour. Reports are reviewed within 24 hours and offending accounts are removed."
                    .tr,
                style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text("Cancel".tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text("I Agree".tr),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (accepted == true) {
      await Preferences.setBoolean(Preferences.chatEulaAcceptedKey, true);
      return true;
    }
    return false;
  }

  Future<void> _confirmBlockDriver() async {
    final driverId = widget.driverId;
    if (driverId == null || driverId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Block driver".tr),
        content: Text(
            "${widget.driverName ?? "This driver"} will no longer be able to message or call you. You can unblock from your profile."
                .tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("Block".tr,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ShowToastDialog.showLoader("Blocking...".tr);
    final ok = await FireStoreUtils.blockUser(
      blockedUserId: driverId,
      blockedUserType: 'driver',
    );
    ShowToastDialog.closeLoader();

    if (!mounted) return;
    if (ok) {
      setState(() => _isBlocked = true);
      ShowToastDialog.showToast("Driver blocked".tr);
    } else {
      ShowToastDialog.showToast(
          "Could not block. Please try again.".tr);
    }
  }

  Future<void> _showReportDriverSheet() {
    return _showReportSheet(
      title: "Report driver".tr,
      reportedUserId: widget.driverId ?? '',
      reportedUserType: 'driver',
    );
  }

  Future<void> _showReportMessageSheet(ConversationModel msg) {
    return _showReportSheet(
      title: "Report message".tr,
      reportedUserId: msg.senderId ?? widget.driverId ?? '',
      reportedUserType: 'driver',
      messageId: msg.id,
      messageSnapshot: msg.messageType == 'text' ? msg.message : msg.messageType,
    );
  }

  Future<void> _showReportSheet({
    required String title,
    required String reportedUserId,
    required String reportedUserType,
    String? messageId,
    String? messageSnapshot,
  }) async {
    if (reportedUserId.isEmpty) return;

    final reasons = <String>[
      "Harassment or hateful language".tr,
      "Threats or unsafe behaviour".tr,
      "Sexually explicit content".tr,
      "Spam or scam".tr,
      "Other".tr,
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...reasons.map(
                  (r) => ListTile(
                    title: Text(r,
                        style: GoogleFonts.poppins(fontSize: 14)),
                    onTap: () => Navigator.of(ctx).pop(r),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    ShowToastDialog.showLoader("Submitting report...".tr);
    final ok = await FireStoreUtils.reportContent(
      reportedUserId: reportedUserId,
      reportedUserType: reportedUserType,
      orderId: widget.orderId,
      messageId: messageId,
      messageSnapshot: messageSnapshot,
      reason: selected,
    );
    ShowToastDialog.closeLoader();

    if (!mounted) return;
    ShowToastDialog.showToast(ok
        ? "Reported. Our team will review within 24 hours.".tr
        : "Could not submit report. Please try again.".tr);
  }
}
