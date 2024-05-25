import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class DealsCarousel extends StatefulWidget {
  const DealsCarousel({super.key});

  @override
  _DealsCarouselState createState() => _DealsCarouselState();
}

class _DealsCarouselState extends State<DealsCarousel> {
  final PageController _pageController = PageController(initialPage: 0);
  late Timer _timer;
  int _currentPage = 0;
  final List<String> _images = [
    'https://placehold.co/400x200/orange/white/jpg',
    'https://placehold.co/400x200/red/white/jpg',
    'https://placehold.co/400x200/yellow/blue/jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    });
    _pageController.addListener(() {
      int nextPage = _pageController.page!.round();
      if (_currentPage != nextPage) {
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(13.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: SizedBox(
              height: 200.0,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    _images[index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
        ),
        SmoothPageIndicator(
          controller: _pageController,  // PageController
          count: _images.length,
          effect: const ExpandingDotsEffect(
            activeDotColor: Colors.teal,
            dotColor: Colors.grey,
            dotHeight: 8.0,
            dotWidth: 8.0,
          ),
        ),
      ],
    );
  }
}
