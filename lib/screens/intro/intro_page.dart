import 'package:flutter/material.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/screens/home_page.dart';
import 'package:harmoniglow/screens/intro/rgb_picker.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  IntroPageState createState() => IntroPageState();
}

class IntroPageState extends State<IntroPage> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PageView.builder(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe to change pages
          onPageChanged: (int page) {
            setState(() {
              _currentPage = page;
            });
          },
          itemCount: 9,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const WelcomePage();
            } else {
              return RGBPicker(
                partNumber: index,
              );
            }
          },
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedOpacity(
                opacity: _currentPage > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: TextButton(
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                  child: const Text('Back'),
                ),
              ),
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: TextButton(
                  onPressed: _currentPage < 8
                      ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : () async {
                          await StorageService.setSkipIntroPage(true);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                  child: Text(_currentPage < 8 ? 'Next' : 'Done'),
                ),
              ),
            ],
          ),
        ),
      );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Drum Light Setup!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Follow the steps to set RGB colors for each drum part.'),
          ],
        ),
      );
}
