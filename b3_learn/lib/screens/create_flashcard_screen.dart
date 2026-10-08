import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../providers/flashcard_provider.dart';

class CreateFlashcardScreen extends ConsumerStatefulWidget {
  final String deckId;
  const CreateFlashcardScreen({super.key, required this.deckId});

  @override
  ConsumerState<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends ConsumerState<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  String _frontText = '';
  String _backText = '';
  Uint8List? _frontImageBytes;
  Uint8List? _backImageBytes;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isFront) {
          _frontImageBytes = bytes;
        } else {
          _backImageBytes = bytes;
        }
      });
    }
  }

  Future<void> _saveFlashcard() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });

      try {
        final service = ref.read(flashcardServiceProvider);
        
        String? frontImageUrl;
        if (_frontImageBytes != null) {
          frontImageUrl = await service.uploadImage(widget.deckId, _frontImageBytes!, 'front.jpg');
        }

        String? backImageUrl;
        if (_backImageBytes != null) {
          backImageUrl = await service.uploadImage(widget.deckId, _backImageBytes!, 'back.jpg');
        }

        await service.addFlashcard(
          deckId: widget.deckId,
          frontText: _frontText,
          frontImageUrl: frontImageUrl,
          backText: _backText,
          backImageUrl: backImageUrl,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Carte ajoutée avec succès !')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de l\'ajout de la carte : $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildImagePicker(bool isFront) {
    final bytes = isFront ? _frontImageBytes : _backImageBytes;
    final label = isFront ? 'Photo Recto' : 'Photo Verso';
    
    return Column(
      children: [
        if (bytes != null)
          Stack(
            alignment: Alignment.topRight,
            children: [
              Image.memory(bytes, height: 100, width: double.infinity, fit: BoxFit.cover),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (isFront) {
                      _frontImageBytes = null;
                    } else {
                      _backImageBytes = null;
                    }
                  });
                },
              )
            ],
          ),
        if (bytes == null)
          OutlinedButton.icon(
            onPressed: () => _pickImage(isFront),
            icon: const Icon(Icons.image),
            label: Text('Ajouter une $label'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Carte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // RECTO
              const Text('RECTO (Question)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Texte du Recto',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty && _frontImageBytes == null ? 'Ajoutez du texte ou une image.' : null,
                onSaved: (value) => _frontText = value ?? '',
              ),
              const SizedBox(height: 8),
              _buildImagePicker(true),
              
              const Divider(height: 48, thickness: 2),

              // VERSO
              const Text('VERSO (Réponse)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Texte du Verso',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty && _backImageBytes == null ? 'Ajoutez du texte ou une image.' : null,
                onSaved: (value) => _backText = value ?? '',
              ),
              const SizedBox(height: 8),
              _buildImagePicker(false),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: _isLoading ? null : _saveFlashcard,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Ajouter la carte',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
