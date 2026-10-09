import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../providers/flashcard_provider.dart';
import '../models/flashcard.dart';

class CreateFlashcardScreen extends ConsumerStatefulWidget {
  final String deckId;
  final Flashcard? cardToEdit;
  
  const CreateFlashcardScreen({super.key, required this.deckId, this.cardToEdit});

  @override
  ConsumerState<CreateFlashcardScreen> createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends ConsumerState<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  String _frontText = '';
  String _backText = '';
  
  Uint8List? _frontImageBytes;
  Uint8List? _backImageBytes;
  
  String? _existingFrontImageUrl;
  String? _existingBackImageUrl;
  
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.cardToEdit != null) {
      _frontText = widget.cardToEdit!.frontText;
      _backText = widget.cardToEdit!.backText;
      _existingFrontImageUrl = widget.cardToEdit!.frontImageUrl;
      _existingBackImageUrl = widget.cardToEdit!.backImageUrl;
    }
  }

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isFront) {
          _frontImageBytes = bytes;
          _existingFrontImageUrl = null;
        } else {
          _backImageBytes = bytes;
          _existingBackImageUrl = null;
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
        
        String? finalFrontImageUrl = _existingFrontImageUrl;
        if (_frontImageBytes != null) {
          finalFrontImageUrl = await service.uploadImage(widget.deckId, _frontImageBytes!, 'front.jpg');
        }

        String? finalBackImageUrl = _existingBackImageUrl;
        if (_backImageBytes != null) {
          finalBackImageUrl = await service.uploadImage(widget.deckId, _backImageBytes!, 'back.jpg');
        }

        if (widget.cardToEdit == null) {
          await service.addFlashcard(
            deckId: widget.deckId,
            frontText: _frontText,
            frontImageUrl: finalFrontImageUrl,
            backText: _backText,
            backImageUrl: finalBackImageUrl,
          );
        } else {
          await service.updateFlashcard(
            deckId: widget.deckId,
            flashcardId: widget.cardToEdit!.id,
            frontText: _frontText,
            frontImageUrl: finalFrontImageUrl,
            backText: _backText,
            backImageUrl: finalBackImageUrl,
          );
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.cardToEdit == null ? 'Carte ajoutée avec succès !' : 'Carte modifiée avec succès !')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
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
    final existingUrl = isFront ? _existingFrontImageUrl : _existingBackImageUrl;
    final label = isFront ? 'Photo Recto' : 'Photo Verso';
    
    if (bytes != null || (existingUrl != null && existingUrl.isNotEmpty)) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          if (bytes != null)
            Image.memory(bytes, height: 100, width: double.infinity, fit: BoxFit.cover)
          else
            Image.network(existingUrl!, height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Text('Erreur d\'image')),
            
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
            onPressed: () {
              setState(() {
                if (isFront) {
                  _frontImageBytes = null;
                  _existingFrontImageUrl = null;
                } else {
                  _backImageBytes = null;
                  _existingBackImageUrl = null;
                }
              });
            },
          )
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _pickImage(isFront),
      icon: const Icon(Icons.image),
      label: Text('Ajouter une $label'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cardToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la carte' : 'Nouvelle Carte'),
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
                initialValue: _frontText,
                decoration: const InputDecoration(
                  labelText: 'Texte du Recto',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => (value!.isEmpty && _frontImageBytes == null && (_existingFrontImageUrl == null || _existingFrontImageUrl!.isEmpty)) ? 'Ajoutez du texte ou une image.' : null,
                onSaved: (value) => _frontText = value ?? '',
              ),
              const SizedBox(height: 8),
              _buildImagePicker(true),
              
              const Divider(height: 48, thickness: 2),

              // VERSO
              const Text('VERSO (Réponse)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _backText,
                decoration: const InputDecoration(
                  labelText: 'Texte du Verso',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => (value!.isEmpty && _backImageBytes == null && (_existingBackImageUrl == null || _existingBackImageUrl!.isEmpty)) ? 'Ajoutez du texte ou une image.' : null,
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
                    : Text(
                        isEditing ? 'Enregistrer les modifications' : 'Ajouter la carte',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
