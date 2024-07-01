import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> fetchScoreboard(String matchId) async {
  final response = await http.get(
    Uri.parse('https://cricbuzz-cricket.p.rapidapi.com/mcenter/v1/$matchId/scard'),
    headers: {
      'X-RapidAPI-Key': '419e740854msh11018c704b8e93bp1d17a1jsn83dc5cc22859',
      'X-RapidAPI-Host': 'cricbuzz-cricket.p.rapidapi.com',
    },
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Data is temporarily unavailable. Please refresh the page in a few minutes.');
  }
}

class ScoreboardWidget extends StatefulWidget {
  final String matchId;

  ScoreboardWidget({required this.matchId});

  @override
  _ScoreboardWidgetState createState() => _ScoreboardWidgetState();
}

class _ScoreboardWidgetState extends State<ScoreboardWidget> {
  late Future<Map<String, dynamic>> scoreboardFuture;

  @override
  void initState() {
    super.initState();
    scoreboardFuture = fetchScoreboard(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: scoreboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final scoreCard = snapshot.data!['scoreCard'];
          return ListView.builder(
            itemCount: scoreCard.length,
            itemBuilder: (context, index) {
              final innings = scoreCard[index];
              final batTeamName = innings['batTeamDetails']['batTeamName'];
              final score = innings['scoreDetails']['runs'];
              final overs = innings['scoreDetails']['overs'];
              final wickets = innings['scoreDetails']['wickets'];
              final batsmenData = innings['batTeamDetails']['batsmenData'];
              final bowlersData = innings['bowlTeamDetails']['bowlersData'];

              return ExpansionTile(
                backgroundColor: Colors.blueGrey[100],
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(batTeamName, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$score/$wickets ($overs)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                children: [
                  // Batters Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Batters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            SizedBox(width: 30, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 30, child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 30, child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 30, child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 30, child: Text('SR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Batters Data
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Table(
                      columnWidths: {
                        0: FlexColumnWidth(3),
                        1: FixedColumnWidth(30),
                        2: FixedColumnWidth(30),
                        3: FixedColumnWidth(30),
                        4: FixedColumnWidth(30),
                        5: FixedColumnWidth(30),
                      },
                      children: [
                        ...batsmenData.values.map<TableRow>((batter) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(batter['batName']),
                                    Text(batter['outDesc'], style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${batter['runs']}', textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${batter['balls']}', textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${batter['fours']}', textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${batter['sixes']}', textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${batter['strikeRate']}', textAlign: TextAlign.center),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  // Bowlers Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bowlers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            SizedBox(width: 30, child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 30, child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 30, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 30, child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                            SizedBox(width: 30, child: Text('ER', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bowlers Data
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Table(
                      columnWidths: {
                        0: FlexColumnWidth(3),
                        1: FixedColumnWidth(30),
                        2: FixedColumnWidth(30),
                        3: FixedColumnWidth(30),
                        4: FixedColumnWidth(30),
                        5: FixedColumnWidth(30),
                      },
                      children: [
                        ...bowlersData.values.map<TableRow>((bowler) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(bowler['bowlName']),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${bowler['overs']}', textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${bowler['maidens']}', textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${bowler['runs']}', textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${bowler['wickets']}', textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text('${bowler['economy']}', textAlign: TextAlign.center),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }
}
