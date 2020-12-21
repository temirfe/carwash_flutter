import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carwash/resources/endpoints.dart';

class MyPhotoView extends StatelessWidget {
  final url;
  final bool local;
  MyPhotoView(this.url, {this.local});
  @override
  Widget build(BuildContext context) {
    ImageProvider img;
    if (local != null && local) {
      img = FileImage(File(url));
    } else {
      img = CachedNetworkImageProvider(Endpoints.baseUrl + url);
    }
    return Material(
      child: Stack(
        children: [
          Container(
            child: PhotoView(
              imageProvider: img,
              minScale: PhotoViewComputedScale.contained * 0.8,
            ),
          ),
          Align(
            alignment: Alignment(1.0, -0.9),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white70,
              ),
              onPressed: () {
                Navigator.maybePop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
