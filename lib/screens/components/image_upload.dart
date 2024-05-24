// components/image_upload.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ImageUpload extends StatefulWidget {
  final Function(String) onUploadComplete;

  const ImageUpload({required this.onUploadComplete, super.key});

  @override
  _ImageUploadState createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  File? _image;
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
      String fileName = path.basename(_image!.path);
      Reference storageReference = FirebaseStorage.instance.ref().child('product_images/$fileName');
      UploadTask uploadTask = storageReference.putFile(_image!);

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      widget.onUploadComplete(downloadURL);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _image == null
            ? const Text('No image selected.')
            : Container(
                constraints: const BoxConstraints(
                  maxWidth: 200,
                  maxHeight: 200,
                ),
                child: Image.file(
                  _image!,
                  fit: BoxFit.cover,
                ),
              ),
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text('Pick Image'),
        ),
        if (_image != null)
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadImage,
            child: _isUploading ? const CircularProgressIndicator() : const Text('Upload Image'),
          ),
      ],
    );
  }
}
