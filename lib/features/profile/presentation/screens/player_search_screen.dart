import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class PlayerSearchScreen extends StatefulWidget {
  const PlayerSearchScreen({super.key});

  @override
  State<PlayerSearchScreen> createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث عن لاعبين', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن لاعب بالاسم...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                ? const Center(
                    child: Text(
                      'أدخل اسم اللاعب للبحث',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firestoreService.searchPlayersStream(_searchQuery),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('حدث خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                        );
                      }

                      final players = snapshot.data ?? [];

                      if (players.isEmpty) {
                        return const Center(
                          child: Text(
                            'لم يتم العثور على لاعبين بهذا الاسم',
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: players.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final ign = player['ign'] ?? 'بدون اسم في اللعبة';
                          final displayName = player['displayName'] ?? 'لاعب';

                          return Card(
                            color: AppTheme.cardDark,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                child: const Icon(Icons.person, color: AppTheme.primaryBlue),
                              ),
                              title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(ign, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  // Implementation for sending an invite
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم إرسال دعوة إلى $displayName', style: const TextStyle(color: Colors.black)),
                                      backgroundColor: AppTheme.primaryBlue,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  foregroundColor: AppTheme.primaryBlue,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
                                  ),
                                ),
                                child: const Text('دعوة'),
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
