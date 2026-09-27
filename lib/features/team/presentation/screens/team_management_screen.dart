import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/player_search_screen.dart';

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
      UserModel? user = await _firestoreService.getUser(authUser.uid);
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
        final team = await _firestoreService.getTeam(user.teamId!);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateTeamDialog() async {
    final nameController = TextEditingController();
    final gameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;
    String _joinType = 'approval';

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يجب تسجيل الدخول أولاً لإنشاء فريق')),
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
            title: Text('إنشاء فريق جديد', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  SizedBox(height: 12),
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
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _joinType,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'نوع الانضمام للفريق',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24))),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryBlue)),
                    ),
                    items: [
                      DropdownMenuItem(value: 'approval', child: Text('بموافقة القائد فقط 🔒')),
                      DropdownMenuItem(value: 'public', child: Text('مفتوح للجميع 🌍')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => _joinType = val);
                    },
                  ),
                ],
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
                        'points': 0,
                        'leaderId': authUser.uid,
                        'roster': [leaderData],
                        'joinType': _joinType,
                        'pendingRequests': [],
                        'createdAt': DateTime.now().toIso8601String(),
                      };
                      
                      await _firestoreService.createTeam(teamData, authUser.uid);
                      
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم إنشاء الفريق بنجاح! 🏆'),
                            backgroundColor: AppTheme.primaryBlue,
                          ),
                        );
                      }
                      await _loadData();
                    } catch (e) {
                      debugPrint('Error creating team: $e');
                      setStateDialog(() => isCreating = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('حدث خطأ أثناء إنشاء الفريق. يرجى المحاولة مرة أخرى.'),
                            backgroundColor: Colors.redAccent,
                          ),
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
                    : Text('إنشاء', style: TextStyle(fontWeight: FontWeight.bold)),
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
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue.withOpacity(0.8), Theme.of(context).colorScheme.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.black26,
                child: Icon(Icons.shield, size: 40, color: AppTheme.primaryBlue),
              ),
              SizedBox(height: 16),
              Text(teamName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 4),
              Text('لعبة: $game', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
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
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: Text('', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
