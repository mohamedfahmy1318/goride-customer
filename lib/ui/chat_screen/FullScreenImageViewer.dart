import 'dart:io';

import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final File? imageFile;

  const FullScreenImageViewer(
      {Key? key, required this.imageUrl, this.imageFile})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
        backgroundColor: themeChange.getThem()
            ? AppColors.darkBackground
            : AppColors.background,
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor:
              themeChange.getThem() ? AppColors.darkBackground : Colors.white,
          iconTheme: IconThemeData(
              color: themeChange.getThem() ? Colors.white : Colors.black),
        ),
        body: Container(
          color: Colors.black,
          child: Hero(
            tag: imageUrl,
            child: PhotoView(
              imageProvider: imageFile == null
                  ? NetworkImage(imageUrl)
                  : Image.file(imageFile!).image,
            ),
          ),
        ));
  }
}
