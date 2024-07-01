import 'dart:convert';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // for formatting date and time
import 'package:http/http.dart' as http;
import 'scoreboard.dart';
import 'package:cricbowled/utils/imageloading.dart'; // Import the image loader service

const String rapidApiKey = '419e740854msh11018c704b8e93bp1d17a1jsn83dc5cc22859'; // RapidAPI key
const String baseUrl = 'https://cricbuzz-cricket.p.rapidapi.com/matches/v1/upcoming';

class UpcomingCricketMatch {
  final String matchId;
  final String seriesName;
  final String matchDesc;
  final int startDate;
  final String timezone;
  final String team1SName;
  final String team2SName;
  final Uint8List? team1LogoBytes; // Changed to Uint8List
  final Uint8List? team2LogoBytes; // Changed to Uint8List

  UpcomingCricketMatch({
    required this.matchId,
    required this.seriesName,
    required this.matchDesc,
    required this.startDate,
    required this.timezone,
    required this.team1SName,
    required this.team2SName,
    this.team1LogoBytes,
    this.team2LogoBytes,
  });

  factory UpcomingCricketMatch.fromJson(Map<String, dynamic> json) {
    final matchInfo = json;
    return UpcomingCricketMatch(
      matchId: matchInfo['matchId'] != null ? matchInfo['matchId'].toString() : '',
      seriesName: matchInfo['seriesName'] ?? '',
      matchDesc: matchInfo['matchDesc'] ?? '',
      startDate: matchInfo['startDate'] is int ? matchInfo['startDate'] as int : int.parse(matchInfo['startDate'] ?? '0'),
      timezone: matchInfo['timezone'] ?? '',
      team1SName: matchInfo['team1'] != null && matchInfo['team1']['teamSName'] != null ? matchInfo['team1']['teamSName'] as String : '',
      team2SName: matchInfo['team2'] != null && matchInfo['team2']['teamSName'] != null ? matchInfo['team2']['teamSName'] as String : '',
      team1LogoBytes: null, // Initially null, will be updated later
      team2LogoBytes: null, // Initially null, will be updated later
    );
  }

  String getFormattedTime() {
    final formatter = DateFormat('EEE, dd MMM, hh:mm a');
    return formatter.format(DateTime.fromMillisecondsSinceEpoch(startDate));
  }
}

class UpcomingMatchesPage extends StatefulWidget {
  const UpcomingMatchesPage({super.key});

  @override
  _UpcomingMatchesPageState createState() => _UpcomingMatchesPageState();
}

class _UpcomingMatchesPageState extends State<UpcomingMatchesPage> {
  List<UpcomingCricketMatch> matches = [];
  bool isLoading = true;
  String errorMessage = '';

  Future<List<dynamic>> fetchUpcomingMatches() async {
    final url = Uri.parse(baseUrl);
    final headers = {
      'X-RapidAPI-Key': rapidApiKey,
      'X-RapidAPI-Host': 'cricbuzz-cricket.p.rapidapi.com',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body.toString());
        final filteredData = {};
        int counter = 0;
        for (var typeMatch in data["typeMatches"]) {
          if (typeMatch.containsKey("seriesMatches") && typeMatch["seriesMatches"].isNotEmpty) {
            for (var seriesMatch in typeMatch["seriesMatches"]) {
              if (seriesMatch.containsKey("seriesAdWrapper")) {
                var matches = seriesMatch["seriesAdWrapper"]["matches"] ?? [];
                if (matches.isNotEmpty) {
                  filteredData[counter] = matches[0]["matchInfo"] ?? {};
                  counter++;
                }
              }
            }
          }
        }
        return filteredData.values.toList();
      } else {
        throw Exception('Data is temporarily unavailable. Please refresh the page in a few minutes.');
      }
    } catch (error) {
      rethrow; // Re-throw the error for further handling in _fetchMatches
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => isLoading = true);

    try {
      final matchesData = await fetchUpcomingMatches();
      final fetchedMatches = await Future.wait(
          matchesData.map((matchJson) async {
            final match = UpcomingCricketMatch.fromJson(matchJson);
            final team1LogoId = matchJson['team1']?['imageId']?.toString() ?? ''; // Convert to string and provide default value
            final team2LogoId = matchJson['team2']?['imageId']?.toString() ?? ''; // Convert to string and provide default value

            final team1LogoBytes = team1LogoId.isNotEmpty ? await ApiService.fetchMatchImage(team1LogoId).then((response) => response.bodyBytes) : null;
            final team2LogoBytes = team2LogoId.isNotEmpty ? await ApiService.fetchMatchImage(team2LogoId).then((response) => response.bodyBytes) : null;

            return UpcomingCricketMatch(
              matchId: match.matchId,
              seriesName: match.seriesName,
              matchDesc: match.matchDesc,
              startDate: match.startDate,
              timezone: match.timezone,
              team1SName: match.team1SName,
              team2SName: match.team2SName,
              team1LogoBytes: team1LogoBytes,
              team2LogoBytes: team2LogoBytes,
            );
          }).toList()
      );

      setState(() {
        matches = fetchedMatches;
        isLoading = false;
        errorMessage = '';
      });
    } catch (error) {
      setState(() {
        print(error);
        isLoading = false;
        errorMessage = 'Data is not available';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(child: Text(errorMessage))
            : ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return UpcomingMatchCard(
              match: match,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScoreboardPage(matchId: match.matchId,)),
                );
              },
            );
          },
        ),
      ),
      backgroundColor: Colors.blueGrey[100],
    );
  }
}

class UpcomingMatchCard extends StatelessWidget {
  final UpcomingCricketMatch match;
  final VoidCallback onTap;

  const UpcomingMatchCard({
    Key? key,
    required this.match,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        margin: const EdgeInsets.all(10.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.seriesName,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black54,
                ),
              ),
              Text(
                match.matchDesc,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10.0),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Column(
                          children: [
                            match.team1LogoBytes != null
                                ? Image.memory(
                              match.team1LogoBytes!,
                              width: constraints.maxWidth * 0.2,
                              height: constraints.maxWidth * 0.2,
                            )
                                : Image.asset(
                              'assets/placeholder.png', // Local placeholder image
                              width: constraints.maxWidth * 0.2,
                              height: constraints.maxWidth * 0.2,
                            ),
                            Text(
                              match.team1SName,
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      const Text(
                        'vs',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Flexible(
                        child: Column(
                          children: [
                            match.team2LogoBytes != null
                                ? Image.memory(
                              match.team2LogoBytes!,
                              width: constraints.maxWidth * 0.2,
                              height: constraints.maxWidth * 0.2,
                            )
                                : Image.asset(
                              'assets/placeholder.png', // Local placeholder image
                              width: constraints.maxWidth * 0.2,
                              height: constraints.maxWidth * 0.2,
                            ),
                            Text(
                              match.team2SName,
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10.0),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.orange[300], // Match status color
                  ),
                  child: Text(
                    match.getFormattedTime(),
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
