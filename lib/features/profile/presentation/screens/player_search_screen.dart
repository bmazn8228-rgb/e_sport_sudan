import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class PlayerSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const PlayerSearchScreen({super.key, this.initialQuery});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('البحث عن لاعبين', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن لاعب بالاسم...',
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(
                    child: Text(
                      'أدخل اسم اللاعب للبحث',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                    ),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firestoreService.searchPlayersStream(_searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('حدث خطأ: ${snapshot.error}', style: TextStyle(color: Colors.red)),
                        );
                      }

                      final players = snapshot.data ?? [];

                      if (players.isEmpty) {
                        return Center(
                          child: Text(
                            'لم يتم العثور على لاعبين بهذا الاسم',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: players.length,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final ign = player['ign'] ?? 'بدون اسم في اللعبة';
                          final displayName = player['displayName'] ?? 'لاعب';

                          return Card(
                            color: Theme.of(context).colorScheme.surface,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                child: Icon(Icons.person, color: AppTheme.primaryBlue),
                              ),
                              title: Text(displayName, style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(ign, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  // Implementation for sending an invite
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم إرسال دعوة إلى $displayName', style: TextStyle(color: Colors.black)),
                                      backgroundColor: AppTheme.primaryBlue,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  foregroundColor: AppTheme.primaryBlue,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
                                  ),
                                ),
                                child: Text('دعوة'),
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
