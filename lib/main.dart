import 'package:flutter/material.dart';
import 'package:cricbowled/screens/upcomingmatch.dart';
import 'package:cricbowled/screens/recentmatch.dart';
import 'package:cricbowled/screens/livematch.dart';
import 'package:cricbowled/screens/series.dart';
import 'package:cricbowled/screens/about.dart';

void main() {
  runApp(const MyCricketApp());
}

class MyCricketApp extends StatelessWidget {
  const MyCricketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 2;
  static final List<Widget> _widgetOptions = <Widget>[
    const SeriesPage(),
    const RecentMatchesPage(),
    const LiveMatchesPage(),
    const UpcomingMatchesPage(),
     AboutPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CrickBowled', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Series',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Recent Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_cricket),
            label: 'Live Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upcoming_rounded),
            label: 'Upcoming Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

