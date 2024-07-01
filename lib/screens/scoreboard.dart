import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cricbowled/widgets/scoreboard_widget.dart';
import 'package:cricbowled/widgets/live_widget.dart';

class Player {
  final String name;
  final bool captain;
  final bool keeper;

  Player({required this.name, required this.captain, required this.keeper});

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] ?? '',
      captain: json['captain'] ?? false,
      keeper: json['keeper'] ?? false,
    );
  }
}

class Team {
  final String name;
  final List<Player> players;

  Team({required this.name, required this.players});

  factory Team.fromJson(Map<String, dynamic> json) {
    var list = json['playerDetails'] as List;
    List<Player> playersList = list.map((i) => Player.fromJson(i)).toList();

    return Team(
      name: json['name'] ?? '',
      players: playersList,
    );
  }
}

class MatchInfo {
  final String matchDescription;
  final String seriesName;
  final String tossResult;
  final String venueName;
  final String venueCity;
  final String venueCountry;
  final String status;
  final Team team1;
  final Team team2;
  final String umpire1;
  final String umpire2;
  final String umpire3;
  final String referee;

  MatchInfo({
    required this.matchDescription,
    required this.seriesName,
    required this.tossResult,
    required this.venueName,
    required this.venueCity,
    required this.venueCountry,
    required this.status,
    required this.team1,
    required this.team2,
    required this.umpire1,
    required this.umpire2,
    required this.umpire3,
    required this.referee,
  });

  factory MatchInfo.fromJson(Map<String, dynamic> json) {
    String tossWinner = json['tossResults']['tossWinnerName'] ?? '';
    String tossDecision = json['tossResults']['decision'] ?? '';
    String tossResult = '$tossWinner opt to $tossDecision';

    return MatchInfo(
      matchDescription: json['matchDescription'] ?? '',
      seriesName: json['series']['name'] ?? '',
      tossResult: tossResult,
      venueName: json['venue']['name'] ?? '',
      venueCity: json['venue']['city'] ?? '',
      venueCountry: json['venue']['country'] ?? '',
      status: json['status'] ?? '',
      team1: Team.fromJson(json['team1']),
      team2: Team.fromJson(json['team2']),
      umpire1: json['umpire1']['name'] ?? '',
      umpire2: json['umpire2']['name'] ?? '',
      umpire3: json['umpire3']['name'] ?? '',
      referee: json['referee']['name'] ?? '',
    );
  }
}

class ScoreboardPage extends StatefulWidget {
  final String matchId;

  const ScoreboardPage({Key? key, required this.matchId}) : super(key: key);

  @override
  _ScoreboardPageState createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  int _selectedIndex = 1; // 0: Info, 1: Live, 2: Scoreboard
  late Future<MatchInfo> matchInfo;

  @override
  void initState() {
    super.initState();
    matchInfo = fetchMatchInfo(widget.matchId);
    print(matchInfo);
  }

  Future<MatchInfo> fetchMatchInfo(String matchId) async {
    final response = await http.get(
      Uri.parse('https://cricbuzz-cricket.p.rapidapi.com/mcenter/v1/$matchId'),
      headers: {
        'X-RapidAPI-Key': '419e740854msh11018c704b8e93bp1d17a1jsn83dc5cc22859',
        'X-RapidAPI-Host': 'cricbuzz-cricket.p.rapidapi.com'
      },
    );

    if (response.statusCode == 200) {
      return MatchInfo.fromJson(json.decode(response.body)['matchInfo']);
    } else {
      throw Exception('Data is temporarily unavailable. Please refresh the page in a few minutes.');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildInfoPage(MatchInfo matchInfo) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ExpansionTile(
                title: Text(
                  '${matchInfo.team1.name} Squad',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                children: matchInfo.team1.players
                    .map((player) => ListTile(
                  title: Text(player.name),
                  subtitle: Text(
                      '${player.captain ? "Captain" : ""} ${player.keeper ? "Keeper" : ""}'),
                ))
                    .toList(),
              ),
            ),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ExpansionTile(
                title: Text(
                  '${matchInfo.team2.name} Squad',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                children: matchInfo.team2.players
                    .map((player) => ListTile(
                  title: Text(player.name),
                  subtitle: Text(
                      '${player.captain ? "Captain" : ""} ${player.keeper ? "Keeper" : ""}'),
                ))
                    .toList(),
              ),
            ),
            SizedBox(height: 16.0),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'INFO',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    Divider(),
                    _buildInfoRow('Match', matchInfo.matchDescription),
                    _buildInfoRow('Series', matchInfo.seriesName),
                    _buildInfoRow('Date', 'Mon, Jun 03'), // Replace with actual date
                    _buildInfoRow('Time', '08:00 pm, Your Time'), // Replace with actual time
                    _buildInfoRow('Toss', matchInfo.tossResult),
                    _buildInfoRow('Venue', '${matchInfo.venueName}, ${matchInfo.venueCity}'),
                    _buildInfoRow('Umpires', '${matchInfo.umpire1}, ${matchInfo.umpire2}'),
                    _buildInfoRow('3rd Umpire', matchInfo.umpire3),
                    _buildInfoRow('Referee', matchInfo.referee),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'VENUE GUIDE',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                    Divider(),
                    _buildInfoRow('Stadium', matchInfo.venueName),
                    _buildInfoRow('City', matchInfo.venueCity),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return FutureBuilder<MatchInfo>(
          future: matchInfo,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return _buildInfoPage(snapshot.data!);
            }
          },
        );
      case 1:
        return LivePage(matchId: widget.matchId);
      case 2:
        return ScoreboardWidget(matchId: widget.matchId);
      default:
        return LivePage(matchId: widget.matchId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match Details'),
        backgroundColor: Colors.blue[300],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv),
            label: 'Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.score),
            label: 'Scoreboard',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

