import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/services/storage_service.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/player_search_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isUploadingLogo = false;
  File? _localLogoPreviewFile;
  Map<String, dynamic>? _teamData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      UserModel? user;
      try {
        user = await _firestoreService
            .getUser(authUser.uid, forceRefresh: false)
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        user = await _firestoreService.getUser(authUser.uid);
      }

      if (user == null) {
        final fallbackName = (authUser.displayName != null && authUser.displayName!.trim().isNotEmpty)
            ? authUser.displayName!.trim()
            : (authUser.email != null && authUser.email!.isNotEmpty)
                ? authUser.email!.split('@').first
                : 'لاعب إلكتروني';

        user = UserModel(
          uid: authUser.uid,
          email: authUser.email ?? '',
          displayName: fallbackName,
          phone: '',
          role: UserRole.player,
        );
        try {
          await _firestoreService.saveUser(user);
        } catch (_) {}
      }

      if (user.teamId != null && user.teamId!.isNotEmpty) {
        final team = await _firestoreService.getTeam(user.teamId!).timeout(const Duration(seconds: 6));
        if (mounted) {
          setState(() {
            _currentUser = user;
            _teamData = team;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentUser = user;
            _teamData = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[TeamManagementScreen] Error in _loadData: $e');
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateTeamBio() async {
    final bioController = TextEditingController(text: _teamData?['bio'] ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('السيرة الذاتية للفريق', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: TextField(
          controller: bioController,
          maxLines: 3,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'اكتب وصفاً أو سيرة ذاتية للفريق...',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryBlue)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () async {
              final newBio = bioController.text.trim();
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('teams').doc(_teamData!['id']).update({
                  'bio': newBio,
                });
                if (mounted) {
                  setState(() {
                    _teamData?['bio'] = newBio;
                  });
                  NotificationService.showCustomToast(
                    context,
                    title: 'تم التحديث',
                    message: 'تم تحديث السيرة الذاتية بنجاح ✅',
                    type: ToastType.success,
                  );
                }
              } catch (e) {
                if (mounted) {
                  NotificationService.showCustomToast(
                    context,
                    title: 'خطأ',
                    message: 'حدث خطأ أثناء تحديث السيرة الذاتية',
                    type: ToastType.urgent,
                  );
                }
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTeamLogo() async {
    if (_teamData == null || _teamData!['id'] == null) return;
    if (_isUploadingLogo) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final currentLogo = _teamData?['logoUrl']?.toString() ?? '';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تحديث شعار الفريق',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library_rounded, color: AppTheme.primaryBlue),
                  ),
                  title: const Text('اختيار من المعرض'),
                  subtitle: const Text('اختر صورة من استوديو هاتفك', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadLogo(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: AppTheme.primaryBlue),
                  ),
                  title: const Text('التقاط بالكاميرا'),
                  subtitle: const Text('التقط صورة جديدة بالكاميرا', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadLogo(ImageSource.camera);
                  },
                ),
                if (currentLogo.isNotEmpty)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    ),
                    title: const Text('حذف الشعار الحالي', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _removeTeamLogo();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      final File file = File(pickedFile.path);

      // Instant optimistic local preview without blocking the screen
      setState(() {
        _localLogoPreviewFile = file;
        _isUploadingLogo = true;
      });

      if (mounted) {
        NotificationService.showCustomToast(
          context,
          title: 'جاري الرفع',
          message: 'يتم رفع شعار الفريق الآن...',
          type: ToastType.social,
        );
      }

      final String? logoUrl = await StorageService().uploadImage(file, 'teams_logos');

      if (logoUrl != null && logoUrl.isNotEmpty) {
        final teamId = _teamData!['id'];
        await FirebaseFirestore.instance.collection('teams').doc(teamId).update({
          'logoUrl': logoUrl,
        });

        if (mounted) {
          setState(() {
            _teamData?['logoUrl'] = logoUrl;
            _localLogoPreviewFile = null;
            _isUploadingLogo = false;
          });

          NotificationService.showCustomToast(
            context,
            title: 'نجاح',
            message: 'تم تحديث شعار الفريق بنجاح! 🛡️',
            type: ToastType.success,
          );
        }
      } else {
        throw Exception("Failed to upload image");
      }
    } catch (e) {
      debugPrint('[TeamManagementScreen] Error uploading logo: $e');
      if (mounted) {
        setState(() {
          _localLogoPreviewFile = null;
          _isUploadingLogo = false;
        });

        NotificationService.showCustomToast(
          context,
          title: 'فشل الرفع',
          message: 'حدث خطأ أثناء رفع الشعار. تحقق من الإنترنت وحاول ثانية.',
          type: ToastType.urgent,
        );
      }
    } finally {
      if (mounted && _isUploadingLogo) {
        setState(() => _isUploadingLogo = false);
      }
    }
  }

  Future<void> _removeTeamLogo() async {
    if (_teamData == null || _teamData!['id'] == null) return;
    try {
      setState(() => _isUploadingLogo = true);
      final teamId = _teamData!['id'];
      await FirebaseFirestore.instance.collection('teams').doc(teamId).update({
        'logoUrl': '',
      });

      if (mounted) {
        setState(() {
          _teamData?['logoUrl'] = '';
          _localLogoPreviewFile = null;
          _isUploadingLogo = false;
        });

        NotificationService.showCustomToast(
          context,
          title: 'تم الحذف',
          message: 'تم حذف شعار الفريق بنجاح',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
        NotificationService.showCustomToast(
          context,
          title: 'خطأ',
          message: 'فشل حذف الشعار',
          type: ToastType.urgent,
        );
      }
    }
  }

  Future<void> _showCreateTeamDialog() async {
    final nameController = TextEditingController();
    final gameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;
    File? newTeamLogoFile;
    String joinType = 'approval';
    String selectedState = 'الخرطوم';
    
    final List<String> sudanStates = [
      'الخرطوم', 'الجزيرة', 'البحر الأحمر', 'كسلا', 'القضارف', 
      'نهر النيل', 'الشمالية', 'شمال كردفان', 'جنوب كردفان', 'غرب كردفان', 
      'شمال دارفور', 'جنوب دارفور', 'غرب دارفور', 'شرق دارفور', 'وسط دارفور', 
      'سنار', 'النيل الأبيض', 'النيل الأزرق'
    ];

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً لإنشاء فريق')),
      );
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('إنشاء فريق جديد', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Team Logo Picker in dialog
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 600,
                          maxHeight: 600,
                          imageQuality: 75,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            newTeamLogoFile = File(picked.path);
                          });
                        }
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                            backgroundImage: newTeamLogoFile != null ? FileImage(newTeamLogoFile!) : null,
                            child: newTeamLogoFile == null
                                ? Icon(Icons.shield, size: 36, color: AppTheme.primaryBlue)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      newTeamLogoFile != null ? 'تم اختيار الشعار ✅' : 'إضافة شعار الفريق (اختياري)',
                      style: TextStyle(
                        fontSize: 11,
                        color: newTeamLogoFile != null ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: newTeamLogoFile != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'اسم الفريق',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryBlue)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم الفريق' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: gameController,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'اللعبة (مثال: PUBG, Free Fire)',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryBlue)),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم اللعبة' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: joinType,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'نوع الانضمام للفريق',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryBlue)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'approval', child: Text('بموافقة القائد فقط 🔒')),
                        DropdownMenuItem(value: 'public', child: Text('مفتوح للجميع 🌍')),
                      ],
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => joinType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedState,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'ولاية الفريق',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryBlue)),
                      ),
                      items: sudanStates.map((state) {
                        return DropdownMenuItem(value: state, child: Text(state));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => selectedState = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isCreating ? null : () => Navigator.pop(ctx),
                child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
              ),
              ElevatedButton(
                onPressed: isCreating ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setStateDialog(() => isCreating = true);
                    try {
                      String logoUrl = '';
                      if (newTeamLogoFile != null) {
                        try {
                          logoUrl = await StorageService().uploadImage(newTeamLogoFile!, 'teams_logos') ?? '';
                        } catch (e) {
                          debugPrint('Error uploading initial team logo: $e');
                        }
                      }

                      final leaderName = (_currentUser?.displayName != null && _currentUser!.displayName.isNotEmpty)
                          ? _currentUser!.displayName
                          : (authUser.displayName != null && authUser.displayName!.isNotEmpty)
                              ? authUser.displayName!
                              : (authUser.email != null && authUser.email!.isNotEmpty)
                                  ? authUser.email!.split('@').first
                                  : 'كابتن الفريق';

                      final leaderIgn = (_currentUser?.ign != null && _currentUser!.ign!.isNotEmpty)
                          ? _currentUser!.ign!
                          : '';

                      final leaderData = {
                        'uid': authUser.uid,
                        'name': leaderName,
                        'ign': leaderIgn,
                        'role': 'كابتن',
                        'isLeader': true,
                      };

                      final teamData = {
                        'name': nameController.text.trim(),
                        'game': gameController.text.trim(),
                        'logoUrl': logoUrl,
                        'points': 0,
                        'leaderId': authUser.uid,
                        'roster': [leaderData],
                        'joinType': joinType,
                        'state': selectedState,
                        'pendingRequests': [],
                        'createdAt': DateTime.now().toIso8601String(),
                      };
                      
                      await _firestoreService.createTeam(teamData, authUser.uid);
                      
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        NotificationService.showCustomToast(
                          context,
                          title: 'تم بنجاح',
                          message: 'تم إنشاء الفريق بنجاح! 🏆',
                          type: ToastType.success,
                        );
                      }
                      await _loadData();
                    } catch (e) {
                      debugPrint('Error creating team: $e');
                      setStateDialog(() => isCreating = false);
                      if (context.mounted) {
                        NotificationService.showCustomToast(
                          context,
                          title: 'خطأ',
                          message: 'حدث خطأ: ${e.toString()}',
                          type: ToastType.urgent,
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                ),
                child: isCreating
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onSurface))
                    : const Text('إنشاء', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _leaveTeam() async {
    if (_teamData == null || _userId.isEmpty) return;
    
    // Find my roster entry
    final roster = _teamData!['roster'] as List<dynamic>? ?? [];
    final myEntry = roster.firstWhere((r) => (r['uid'] == _userId || r['name'] == _currentUser?.displayName), orElse: () => null);
    
    if (myEntry == null) return;
    
    try {
      setState(() => _isLoading = true);
      await _firestoreService.leaveTeam(_teamData!['id'], _userId, Map<String, dynamic>.from(myEntry));
      setState(() {
        _teamData = null;
        if (_currentUser != null) {
          _currentUser = UserModel(
            uid: _currentUser!.uid,
            email: _currentUser!.email,
            displayName: _currentUser!.displayName,
            phone: _currentUser!.phone,
            teamId: null, // Clear teamId locally
            role: _currentUser!.role,
            gameId: _currentUser!.gameId,
            photoUrl: _currentUser!.photoUrl,
            settings: _currentUser!.settings,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء المغادرة')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('إدارة الفريق التنافسي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_teamData != null)
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: Text('مغادرة الفريق', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    content: Text('هل أنت متأكد أنك تريد مغادرة الفريق؟', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)))),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _leaveTeam();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: Text('مغادرة', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team Profile Banner
                  if (_teamData == null)
                    _buildNoTeamBanner()
                  else
                    _buildTeamDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildNoTeamBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.group_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
          SizedBox(height: 16),
          Text('أنت لست منضماً لأي فريق', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('انضم إلى فريق موجود أو قم بإنشاء فريقك الخاص للمشاركة في البطولات.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13)),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _showCreateTeamDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              minimumSize: Size(double.infinity, 48),
            ),
            child: Text('إنشاء فريق جديد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 12),
                    OutlinedButton(
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamSearchScreen()));
              if (result == true) {
                _loadData();
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryBlue),
              minimumSize: Size(double.infinity, 48),
            ),
            child: Text('البحث عن فريق', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDetails() {
    final teamName = _teamData?['name'] ?? 'فريق غير معروف';
    final points = _teamData?['points'] ?? 0;
    final game = _teamData?['game'] ?? 'غير محدد';
    final roster = _teamData?['roster'] as List<dynamic>? ?? [];
    final bio = _teamData?['bio']?.toString() ?? '';
    final logoUrl = _teamData?['logoUrl']?.toString() ?? '';
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    bool isLeader = _teamData?['leaderId'] == currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue.withValues(alpha: 0.8), Theme.of(context).colorScheme.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isUploadingLogo ? AppTheme.primaryBlue : AppTheme.primaryBlue.withValues(alpha: 0.4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.black38,
                          backgroundImage: _localLogoPreviewFile != null
                              ? FileImage(_localLogoPreviewFile!) as ImageProvider
                              : (logoUrl.isNotEmpty ? CachedNetworkImageProvider(logoUrl) : null),
                          child: (_localLogoPreviewFile == null && logoUrl.isEmpty)
                              ? Icon(Icons.shield, size: 42, color: AppTheme.primaryBlue)
                              : null,
                        ),
                        if (_isUploadingLogo)
                          Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.8,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isLeader)
                    GestureDetector(
                      onTap: _isUploadingLogo ? null : _updateTeamLogo,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _isUploadingLogo ? Colors.grey.shade700 : AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                        ),
                        child: Icon(
                          _isUploadingLogo ? Icons.hourglass_top_rounded : Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
              if (_isUploadingLogo) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'جاري رفع الشعار وحفظه...',
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16),
              Text(teamName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  final id = _teamData?['id'];
                  if (id != null) {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم نسخ معرف الفريق: $id'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _teamData?['id'] ?? 'بدون معرف',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 1.1),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryBlue),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Text('لعبة: $game', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
              if (bio.isNotEmpty) ...[
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    bio, 
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              if (isLeader) ...[
                SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _updateTeamBio,
                  icon: Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.primaryBlue),
                  label: Text(bio.isEmpty ? 'إضافة سيرة ذاتية' : 'تعديل السيرة الذاتية', style: TextStyle(color: AppTheme.primaryBlue)),
                ),
              ],
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('النقاط: $points', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildPendingRequests(),
        SizedBox(height: 24),
        Text('أعضاء الفريق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        ...roster.map((player) => _buildPlayerCard(Map<String, dynamic>.from(player))),
        SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlayerSearchScreen()),
            );
          },
          icon: Icon(Icons.person_add, color: AppTheme.primaryBlue),
          label: Text('البحث عن لاعبين', style: TextStyle(color: AppTheme.primaryBlue)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppTheme.primaryBlue),
            minimumSize: Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }




  Widget _buildPendingRequests() {
    final pendingRequests = _teamData?['pendingRequests'] as List<dynamic>? ?? [];
    if (pendingRequests.isEmpty) return SizedBox.shrink();

    // Check if current user is leader
    final roster = _teamData?['roster'] as List<dynamic>? ?? [];
    final currentUserData = roster.firstWhere((p) => p['uid'] == _userId, orElse: () => null);
    final isLeader = currentUserData != null && currentUserData['isLeader'] == true;
    
    if (!isLeader) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.mail_lock, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('طلبات الانضمام المعلقة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: Text('${pendingRequests.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...pendingRequests.map((req) {
          final requestMap = Map<String, dynamic>.from(req);
          return Card(
            color: Theme.of(context).colorScheme.surface,
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person, color: Colors.white70)),
              title: Text(requestMap['displayName'] ?? 'لاعب مجهول'),
              subtitle: Text(requestMap['email'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () async {
                      try {
                        await _firestoreService.acceptJoinRequest(_teamData!['id'], requestMap['uid'], requestMap);
                        _loadData();
                        if (mounted) NotificationService.showCustomToast(context, title: 'نجاح', message: 'تم قبول اللاعب بنجاح ✅', type: ToastType.success);
                      } catch (e) {
                        if (mounted) NotificationService.showCustomToast(context, title: 'خطأ', message: 'فشل قبول اللاعب', type: ToastType.urgent);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    onPressed: () async {
                      try {
                        await _firestoreService.rejectJoinRequest(_teamData!['id'], requestMap);
                        _loadData();
                        if (mounted) NotificationService.showCustomToast(context, title: 'مرفوض', message: 'تم رفض طلب الانضمام', type: ToastType.success);
                      } catch (e) {
                        if (mounted) NotificationService.showCustomToast(context, title: 'خطأ', message: 'فشل الرفض', type: ToastType.urgent);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (player['isLeader'] == true) ? AppTheme.primaryBlue.withValues(alpha: 0.4) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: (player['isLeader'] == true) ? AppTheme.primaryBlue.withValues(alpha: 0.2) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
                child: Icon(
                  (player['isLeader'] == true) ? Icons.star : Icons.person,
                  color: (player['isLeader'] == true) ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(player['ign'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (player['verified'] == true) ...[
                        SizedBox(width: 4),
                        Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 14),
                      ],
                    ],
                  ),
                  Text(player['name'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11)),
                  Text(player['role'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 10)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 18),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
