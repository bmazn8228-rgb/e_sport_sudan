import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';

class TeamSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const TeamSearchScreen({super.key, this.initialQuery});

  @override
  State<TeamSearchScreen> createState() => _TeamSearchScreenState();
}

class _TeamSearchScreenState extends State<TeamSearchScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!.toLowerCase();
    }
  }

  Future<void> _joinTeam(String teamId, String teamName, Map<String, dynamic> teamData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final playerRosterData = {
        'uid': user.uid,
        'displayName': user.displayName ?? 'لاعب مجهول',
        'email': user.email ?? '',
        'role': 'Member',
        'joinedAt': DateTime.now().toIso8601String(),
      };

      await _firestoreService.joinTeam(teamId, user.uid, playerRosterData);
      
      if (mounted) {
        NotificationService.showCustomToast(context, title: 'نجاح', message: 'تم الانضمام إلى فريق  بنجاح!', type: ToastType.success);
        Navigator.pop(context, true); // Return true to refresh parent
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showCustomToast(context, title: 'خطأ', message: 'فشل الانضمام للفريق: ', type: ToastType.urgent);
      }
    }
  }

  Future<void> _requestToJoin(String teamId, String teamName, Map<String, dynamic> teamData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final playerRosterData = {
        'uid': user.uid,
        'displayName': user.displayName ?? 'لاعب مجهول',
        'email': user.email ?? '',
        'role': 'Member',
        'status': 'pending',
        'requestedAt': DateTime.now().toIso8601String(),
      };

      await _firestoreService.requestToJoinTeam(teamId, playerRosterData);
      
      if (mounted) {
        NotificationService.showCustomToast(context, title: 'طلب انضمام', message: 'تم إرسال طلب الانضمام لقائد فريق  بنجاح! ⏳', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showCustomToast(context, title: 'خطأ', message: 'فشل إرسال الطلب: ', type: ToastType.urgent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('البحث عن فريق', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم الفريق...',
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getAllTeamsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }

                var teams = snapshot.data ?? [];
                
                if (_searchQuery.isNotEmpty) {
                  teams = teams.where((t) {
                    final name = (t['name'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();
                }

                if (teams.isEmpty) {
                  return Center(child: Text('لم يتم العثور على فرق.'));
                }

                return ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final memberCount = (team['roster'] as List?)?.length ?? 0;
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Theme.of(context).colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: Icon(Icons.shield, color: AppTheme.primaryBlue),
                        ),
                        title: Text(team['name'] ?? 'بدون اسم', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('اللعبة:  | الأعضاء: '),
                        trailing: Builder(
                          builder: (context) {
                            final joinType = team['joinType'] ?? 'public';
                            final pendingRequests = team['pendingRequests'] as List? ?? [];
                            final bool hasRequested = pendingRequests.any((req) => req['uid'] == _currentUid);
                            
                            if (hasRequested) {
                              return OutlinedButton(
                                onPressed: null,
                                child: Text('قيد الانتظار ⏳'),
                              );
                            }
                            
                            if (joinType == 'approval') {
                              return ElevatedButton(
                                onPressed: () => _requestToJoin(team['id'], team['name'] ?? 'بدون اسم', team),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text('طلب انضمام 🔒', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              );
                            }
                            
                            return ElevatedButton(
                              onPressed: () => _joinTeam(team['id'], team['name'] ?? 'بدون اسم', team),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('انضمام 🌍', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            );
                          }
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
