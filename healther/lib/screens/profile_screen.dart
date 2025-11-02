import 'dart:io';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/camera_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final CameraService _cameraService = CameraService();
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isEditing = false;
  
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _centreSanteController;

  Future<void> _changeProfilePicture() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null || user.id == null) return;

    // Demander à l'utilisateur de choisir la source
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (user.profilePicture != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteProfilePicture();
                },
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      setState(() => _isUploading = true);

      // Obtenir l'image
      final XFile? pickedFile = await _cameraService.pickImage(source: source);
      if (pickedFile == null) {
        setState(() => _isUploading = false);
        return;
      }

      final imageFile = File(pickedFile.path);
      
      // Upload vers le backend
      final result = await _apiService.uploadProfilePicture(user.id!, imageFile);

      // Mettre à jour l'utilisateur dans le provider
      final updatedUser = user.copyWith(
        profilePicture: result['profile_picture'] as String?,
        profilePictureUrl: result['profile_picture_url'] as String?,
      );
      
      authProvider.updateUser(updatedUser);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil mise à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteProfilePicture() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null || user.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: const Text('Êtes-vous sûr de vouloir supprimer votre photo de profil ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isUploading = true);

      await _apiService.deleteProfilePicture(user.id!);

      // Mettre à jour l'utilisateur dans le provider
      final updatedUser = user.copyWith(
        profilePicture: null,
        profilePictureUrl: null,
      );
      
      authProvider.updateUser(updatedUser);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil supprimée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    _nomController = TextEditingController(text: user?.nom ?? '');
    _prenomController = TextEditingController(text: user?.prenom ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _centreSanteController = TextEditingController(text: user?.centreSante ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _centreSanteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null || user.id == null) return;

    // Validation de l'email
    if (_emailController.text.isNotEmpty && !_emailController.text.contains('@')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un email valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedUser = await _apiService.updateUser(
        userId: user.id!,
        nom: _nomController.text.trim().isEmpty ? null : _nomController.text.trim(),
        prenom: _prenomController.text.trim().isEmpty ? null : _prenomController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        centreSante: _centreSanteController.text.trim().isEmpty ? null : _centreSanteController.text.trim(),
      );

      authProvider.updateUser(updatedUser);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Aucun utilisateur connecté')),
      );
    }

    // Mettre à jour les controllers si l'utilisateur change
    if (_nomController.text != (user.nom ?? '')) {
      _nomController.text = user.nom ?? '';
    }
    if (_prenomController.text != (user.prenom ?? '')) {
      _prenomController.text = user.prenom ?? '';
    }
    if (_emailController.text != user.email) {
      _emailController.text = user.email;
    }
    if (_centreSanteController.text != (user.centreSante ?? '')) {
      _centreSanteController.text = user.centreSante ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
              tooltip: 'Modifier le profil',
            )
          else
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              onPressed: _isSaving ? null : _saveProfile,
              tooltip: 'Enregistrer',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _isEditing = false;
                        // Restaurer les valeurs originales
                        _nomController.text = user.nom ?? '';
                        _prenomController.text = user.prenom ?? '';
                        _emailController.text = user.email;
                        _centreSanteController.text = user.centreSante ?? '';
                      });
                    },
              tooltip: 'Annuler',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar et nom
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _isUploading ? null : _changeProfilePicture,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: user.profilePictureUrl != null
                              ? NetworkImage(user.profilePictureUrl!)
                              : null,
                          child: user.profilePictureUrl == null
                              ? Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        ),
                      if (!_isUploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user.centreSante != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.centreSante!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _isUploading ? null : _changeProfilePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Changer la photo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            // Informations utilisateur
            _buildInfoTile(
              context,
              'Nom d\'utilisateur',
              user.username,
              Icons.person,
              editable: false,
            ),
            const SizedBox(height: 8),
            
            // Nom (éditable)
            if (_isEditing)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                      helperText: 'Optionnel',
                    ),
                  ),
                ),
              )
            else
              _buildInfoTile(
                context,
                'Nom',
                user.nom ?? 'Non défini',
                Icons.badge,
              ),
            const SizedBox(height: 8),
            
            // Prénom (éditable)
            if (_isEditing)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                      helperText: 'Optionnel',
                    ),
                  ),
                ),
              )
            else
              _buildInfoTile(
                context,
                'Prénom',
                user.prenom ?? 'Non défini',
                Icons.badge,
              ),
            const SizedBox(height: 8),
            
            // Email (éditable)
            if (_isEditing)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      helperText: 'Votre adresse email',
                    ),
                  ),
                ),
              )
            else
              _buildInfoTile(
                context,
                'Email',
                user.email,
                Icons.email,
              ),
            const SizedBox(height: 8),
            
            // Centre de santé (éditable)
            if (_isEditing)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _centreSanteController,
                    decoration: const InputDecoration(
                      labelText: 'Centre de Santé',
                      prefixIcon: Icon(Icons.local_hospital),
                      border: OutlineInputBorder(),
                      helperText: 'Optionnel',
                    ),
                  ),
                ),
              )
            else
              _buildInfoTile(
                context,
                'Centre de Santé',
                user.centreSante ?? 'Non défini',
                Icons.local_hospital,
              ),
            const SizedBox(height: 8),
            
            // Rôle (non éditable)
            _buildInfoTile(
              context,
              'Rôle',
              user.role.toUpperCase(),
              Icons.verified_user,
              editable: false,
            ),
            if (user.createdAt != null) ...[
              const SizedBox(height: 8),
              _buildInfoTile(
                context,
                'Membre depuis',
                _formatDate(user.createdAt!),
                Icons.calendar_today,
                editable: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool editable = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(value.isEmpty ? 'Non défini' : value),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: Colors.grey[100],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
