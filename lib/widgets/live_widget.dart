import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LivePage extends StatefulWidget {
  final String matchId;

  const LivePage({Key? key, required this.matchId}) : super(key: key);

  @override
  _LivePageState createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late Future<Map<String, dynamic>> liveData;

  @override
  void initState() {
    super.initState();
    liveData = fetchLiveData(widget.matchId);
  }

  Future<Map<String, dynamic>> fetchLiveData(String matchId) async {
    final response = await http.get(
      Uri.parse('https://cricbuzz-cricket.p.rapidapi.com/mcenter/v1/$matchId/leanback'),
      headers: {
        'X-RapidAPI-Key': '419e740854msh11018c704b8e93bp1d17a1jsn83dc5cc22859',
        'X-RapidAPI-Host': 'cricbuzz-cricket.p.rapidapi.com',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 204) {
      // Handle case where API returns no content (204)
      return {'matchStatus': 'Match data not available'};
    } else if (response.statusCode == 404) {
      // Handle case where match data is not found (match hasn't started)
      return {'matchStatus': 'Match not started yet'};
    } else {
      throw Exception('Failed to load data. Status code: ${response.statusCode}');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: liveData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!['matchStatus'] != null) {
            // Display message when data is not available or match hasn't started
            return Center(child: Text('Match not started yet'));
          } else {
            final data = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    _buildTopCard(data),
                    if (data['matchHeader']['playersOfTheMatch'] != null ||
                        data['matchHeader']['playersOfTheSeries'] != null)
                      _buildPlayerAwards(data['matchHeader']),
                    SizedBox(height: 16.0),
                    _buildStatsCard(data),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPlayerAwards(Map<String, dynamic> matchHeader) {
    final playersOfTheMatch = matchHeader['playersOfTheMatch'];
    final playersOfTheSeries = matchHeader['playersOfTheSeries'];

    return Column(
      children: [
        if (playersOfTheMatch != null && playersOfTheMatch.isNotEmpty)
          _buildAwardCard(playersOfTheMatch, 'Player of the Match'),
        if (playersOfTheSeries != null && playersOfTheSeries.isNotEmpty)
          _buildAwardCard(playersOfTheSeries, 'Player of the Series'),
      ],
    );
  }

  Widget _buildAwardCard(List<dynamic> players, String title) {
    return Container(
      width: double.infinity,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              ...players.map((player) => Text(player['name'])).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(Map<String, dynamic> data) {
    final innings = data['miniscore']['matchScoreDetails']['inningsScoreList'];
    final status = data['miniscore']['matchScoreDetails']['customStatus'];
    final lastWicket = data['miniscore']['lastWicket'];

    return Container(
      width: double.infinity,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (innings != null && innings.length >= 2)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInningScore(innings[1]), // First inning
                      _buildInningScore(innings[0]), // Second inning
                    ],
                  ),
                ),
              SizedBox(height: 8.0),
              Text(
                status ?? 'Match status not available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                _getLastWicketDescription(lastWicket),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLastWicketDescription(dynamic lastWicket) {
    if (lastWicket == null) {
      return 'Last wicket information not available';
    } else if (lastWicket is String && lastWicket.contains(' - ')) {
      return lastWicket.split(' - ')[0];
    } else {
      return 'Last wicket information not available';
    }
  }

  Widget _buildInningScore(Map<String, dynamic> inning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          inning['batTeamName'] ?? 'Team Name not available',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        Text(
          '${inning['score']}/${inning['wickets']} in ${inning['overs']} overs',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> data) {
    final miniscore = data['miniscore'];
    final lastWicketDescription = miniscore['lastWicket'] != null ? miniscore['lastWicket'].split(' - ')[0] : 'Last wicket information not available';
    final batsmanStriker = miniscore['batsmanStriker'];
    final batsmanNonStriker = miniscore['batsmanNonStriker'];
    final bowlerStriker = miniscore['bowlerStriker'];

    return Container(
      width: double.infinity,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Last Balls'),
                  Text(miniscore['recentOvsStats']),
                ],
              ),
              SizedBox(height: 16.0),
              _buildStatsRow('Target', miniscore['target'], 'Lead', miniscore['lead']),
              SizedBox(height: 8.0),
              _buildStatsRow('CRR', miniscore['currentRunRate'], 'RRR', miniscore['requiredRunRate']),
              SizedBox(height: 8.0),
              if (miniscore['remRunsToWin'] != null && miniscore['remRunsToWin'] > 0)
                _buildStatsRow('Runs to Win', miniscore['remRunsToWin'], '', 0),
              _buildSectionHeader('Batters'),
              _buildBattersTable([
                {...batsmanStriker, 'batName': '${batsmanStriker['batName']}*'},
                batsmanNonStriker
              ]),
              _buildSectionHeader('Bowlers'),
              _buildBowlersTable([bowlerStriker]),
              _buildSectionHeader('Last Wicket'),
              Text(lastWicketDescription),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildStatsRow(String leftLabel, dynamic leftValue, String rightLabel, dynamic rightValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (leftLabel.isNotEmpty)
          Text(
            '$leftLabel: $leftValue',
            style: TextStyle(fontSize: 16),
          ),
        if (rightLabel.isNotEmpty && rightValue != null && rightValue != 0)
          Text(
            '$rightLabel: $rightValue',
            style: TextStyle(fontSize: 16),
          ),
      ],
    );
  }

  Widget _buildBattersTable(List<Map<String, dynamic>> batsmen) {
    return Padding(
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
          TableRow(
            children: [
              Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('4s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('6s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('SR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          ...batsmen.map<TableRow>((batsman) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(batsman['batName']),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${batsman['batRuns']}', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${batsman['batBalls']}', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${batsman['batFours']}', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${batsman['batSixes']}', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${batsman['batStrikeRate']}', textAlign: TextAlign.center),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBowlersTable(List<Map<String, dynamic>> bowlers) {
    return Padding(
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
          TableRow(
            children: [
              Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('O', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('W', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              Text('ER', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          ...bowlers.map<TableRow>((bowler) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(bowler['bowlName']),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${bowler['bowlOvs']}', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${bowler['bowlMaidens']}', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${bowler['bowlRuns']}', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${bowler['bowlWkts']}', textAlign: TextAlign.center),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${bowler['bowlEcon']}', textAlign: TextAlign.center),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

