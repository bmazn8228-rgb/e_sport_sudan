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
    if (_userId.isEmpty) return;
    try {
      final user = await _firestoreService.getUser(_userId);
      if (user != null && user.teamId != null && user.teamId!.isNotEmpty) {
        final team = await _firestoreService.getTeam(user.teamId!);
        setState(() {
          _currentUser = user;
          _teamData = team;
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
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

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: const Text('إنشاء فريق جديد', style: TextStyle(color: Colors.white)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'اسم الفريق',
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryBlue)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'اللعبة (مثال: PUBG, Free Fire)',
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryBlue)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isCreating ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isCreating ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setStateDialog(() => isCreating = true);
                    try {
                      final leaderData = {
                        'uid': _userId,
                        'name': _currentUser?.displayName ?? '',
                        'ign': _currentUser?.ign ?? '',
                        'role': 'كابتن',
                        'isLeader': true,
                      };
                      final teamData = {
                        'name': nameController.text.trim(),
                        'game': gameController.text.trim(),
                        'points': 0,
                        'leaderId': _userId,
                        'roster': [leaderData],
                        'createdAt': DateTime.now().toIso8601String(),
                      };
                      
                      await _firestoreService.createTeam(teamData, _userId);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                      }
                      _loadData();
                    } catch (e) {
                      setStateDialog(() => isCreating = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إنشاء الفريق')));
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                child: isCreating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('إنشاء', style: TextStyle(color: Colors.black)),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء المغادرة')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إدارة الفريق التنافسي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_teamData != null)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardDark,
                    title: const Text('مغادرة الفريق', style: TextStyle(color: Colors.white)),
                    content: const Text('هل أنت متأكد أنك تريد مغادرة الفريق؟', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _leaveTeam();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('مغادرة', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.group_off_rounded, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('أنت لست منضماً لأي فريق', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('انضم إلى فريق موجود أو قم بإنشاء فريقك الخاص للمشاركة في البطولات.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _showCreateTeamDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('إنشاء فريق جديد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البحث عن فريق سيتوفر قريباً')));
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryBlue),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('البحث عن فريق', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryBlue.withOpacity(0.8), AppTheme.cardDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.black26,
                child: Icon(Icons.shield, size: 40, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 16),
              Text(teamName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text('لعبة: $game', style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('النقاط: $points', style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('أعضاء الفريق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...roster.map((player) => _buildPlayerCard(Map<String, dynamic>.from(player))),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerSearchScreen()),
            );
          },
          icon: const Icon(Icons.person_add, color: AppTheme.primaryBlue),
          label: const Text('البحث عن لاعبين', style: TextStyle(color: AppTheme.primaryBlue)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryBlue),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }



  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player['isLeader'] ? AppTheme.primaryBlue.withOpacity(0.4) : Colors.white10,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: player['isLeader'] ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.white10,
                child: Icon(
                  player['isLeader'] ? Icons.star : Icons.person,
                  color: player['isLeader'] ? AppTheme.primaryBlue : Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(player['ign'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (player['verified']) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 14),
                      ],
                    ],
                  ),
                  Text(player['name'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(player['role'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
