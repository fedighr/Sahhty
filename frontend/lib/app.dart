import 'package:flutter/material.dart';

class Sahhty extends StatelessWidget {
  const Sahhty({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CarouselScreen(),
    );
  }
}

class CarouselScreen extends StatefulWidget {
  const CarouselScreen({super.key});

  @override
  State<CarouselScreen> createState() => _CarouselScreenState();
}

class _CarouselScreenState extends State<CarouselScreen> {
  // Like useState(0) in React
  int _currentIndex = 0;

  // Your data — in real app this comes from API
  final List<Map<String, dynamic>> cards = [
    {"title": "Diabetes", "description": "Monitor your sugar levels daily", "color": Colors.blue},
    {"title": "Hypertension", "description": "Check your blood pressure regularly", "color": Colors.red},
    {"title": "Asthma", "description": "Keep your inhaler close", "color": Colors.green},
  ];

  // Controller — like a ref in React, controls the PageView
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();  // initialize controller
  }

  @override
  void dispose() {
    _pageController.dispose();  // cleanup — like useEffect return
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carousel Example")),
      body: Column(
        children: [

          // ── THE CAROUSEL ──
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: cards.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index); // re-render like setCurrentIndex()
              },
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cards[index]['color'],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cards[index]['title'],
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          cards[index]['description'],
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 16),

          // ── DOTS INDICATOR ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(cards.length, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 24 : 8,  // active dot is wider
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

        ],
      ),
    );
  }
}