import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/features/main/presentation/screens/root_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboarding_1.jpg',
      'tag': 'منصة الأبطال',
      'title': 'مرحباً بك في الساحة',
      'subtitle':
          'ادخل إلى عالم الرياضات الإلكترونية الأكبر في السودان. بطولات حية، تنافس مشتعل، ومجتمع احترافي بانتظارك.',
    },
    {
      'image': 'assets/images/onboarding_2.jpg',
      'tag': 'هوية اللاعب',
      'title': 'ابنِ أسطورتك',
      'subtitle':
          'أنشئ ملفك كلاعب محترف، انضم للفرق، وابدأ في جمع النقاط لتتصدر التصنيف الوطني.',
    },
    {
      'image': 'assets/images/onboarding_3.jpg',
      'tag': 'المنافسات القومية',
      'title': 'نافس وانتصر',
      'subtitle':
          'شارك في أقوى التصفيات المعتمدة، واصعد سلم المجد لتمثيل بلدك في المحافل الدولية.',
    },
    {
      'image': 'assets/images/onboarding_4.jpg',
      'tag': 'مجتمع إي سبورت',
      'title': 'انضم للنخبة',
      'subtitle':
          'تواصل مع آلاف اللاعبين، تابع البث المباشر للمباريات، وكن جزءاً من مجتمع لا يعرف المستحيل.',
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RootScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // خلفية الصور الترحيبية والتدرج المتناسق مع ألوان التطبيق
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _pages[index]['image']!,
                    fit: BoxFit.cover,
                  ),
                  // تدرج لوني عميق متطابق مع هوية التطبيق (AppTheme.backgroundDark)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.backgroundDark.withValues(alpha: 0.15),
                          AppTheme.backgroundDark.withValues(alpha: 0.75),
                          AppTheme.backgroundDark,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.55, 0.9],
                      ),
                    ),
                  ),
                  // بطاقة المحتوى النصي الأنيقة بتصميم متناسق مع كروت التطبيق
                  Positioned(
                    bottom: 140,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // وسم الهوية الرياضية
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.sports_esports,
                                  size: 14,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _pages[index]['tag']!,
                                  style: const TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // عنوان الصفحة
                          Text(
                            _pages[index]['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // الوصف التوضيحي
                          Text(
                            _pages[index]['subtitle']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // شريط التحكم السفلي ومؤشر الصفحات
          Positioned(
            bottom: 35,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // مؤشر الصفحات المتفاعل بألوان التطبيق
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 28 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.primaryBlue
                            : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _currentPage == index
                              ? AppTheme.primaryBlue
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: _currentPage == index
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // يظهر زر الدخول فقط عند الوصول لآخر صورة ترحيبية
                if (_currentPage == _pages.length - 1) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _finishOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 8,
                        shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'دخول',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.login_rounded, size: 22, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // أزرار التنقل بين الصفحات بالألوان المتناسقة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            backgroundColor: AppTheme.cardDark,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'السابق',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 80),

                      ElevatedButton.icon(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                          shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                        label: const Text(
                          'التالي',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
