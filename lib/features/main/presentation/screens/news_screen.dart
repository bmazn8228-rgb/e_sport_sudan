import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/models/news_model.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class NewsListScreen extends StatelessWidget {
  const NewsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('آخر الأخبار والمقالات', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: FirestoreService().getNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ أثناء تحميل الأخبار'));
          }
          final newsList = snapshot.data ?? [];
          if (newsList.isEmpty) {
            return Center(child: Text('لا توجد أخبار حالياً', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))));
          }

          return ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(16),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return _buildNewsCard(context, news);
            },
          );
        },
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsModel news) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailsScreen(news: news)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  news.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildPlaceholder(),
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      news.category,
                      style: TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    news.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    news.content,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        news.authorName,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11),
                      ),
                      Text(
                        '//',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.blueAccent.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.newspaper, size: 50, color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
    );
  }
}

class NewsDetailsScreen extends StatelessWidget {
  final NewsModel news;
  const NewsDetailsScreen({Key? key, required this.news}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.category, style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl != null && news.imageUrl!.isNotEmpty)
              Image.network(
                news.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => SizedBox(height: 0),
              ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      SizedBox(width: 4),
                      Text(news.authorName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                      SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      SizedBox(width: 4),
                      Text('//', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ),
                  Divider(height: 32, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                  Text(
                    news.content,
                    style: TextStyle(fontSize: 15, height: 1.6, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
