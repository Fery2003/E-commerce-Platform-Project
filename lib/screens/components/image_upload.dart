import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUpload extends StatefulWidget {
  final Function(String) onUploadComplete;

  const ImageUpload({super.key, required this.onUploadComplete});

  @override
  _ImageUploadState createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  File? _image;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;
    setState(() {
      _isUploading = true;
    });
    try {
      String filePath = 'product_images/${DateTime.now().millisecondsSinceEpoch}.png';
      UploadTask uploadTask = _storage.ref().child(filePath).putFile(_image!);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      widget.onUploadComplete(downloadUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _image = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _image == null
            ? const Text('No image selected.')
            : Image.file(_image!, height: 200, width: 200, fit: BoxFit.cover),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            if (_image != null && !_isUploading)
              ElevatedButton(
                onPressed: _uploadImage,
                child: const Text('Upload Image'),
              ),
          ],
        ),
        if (_isUploading) const CircularProgressIndicator(),
      ],
    );
  }
}
