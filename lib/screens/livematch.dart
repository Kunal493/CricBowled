import 'dart:convert';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'scoreboard.dart';
import 'package:cricbowled/utils/imageloading.dart';

const String rapidApiKey = '419e740854msh11018c704b8e93bp1d17a1jsn83dc5cc22859'; // RapidAPI key
const String baseUrl = 'https://cricbuzz-cricket.p.rapidapi.com/matches/v1/live';

class CricketMatch {
  final String matchId;
  final String seriesName;
  final String matchDesc;
  final String status;
  final String team1SName;
  final String team2SName;
  final Uint8List? team1LogoBytes; // Changed to Uint8List
  final Uint8List? team2LogoBytes; // Changed to Uint8List

  CricketMatch({
    required this.matchId,
    required this.seriesName,
    required this.matchDesc,
    required this.status,
    required this.team1SName,
    required this.team2SName,
    this.team1LogoBytes,
    this.team2LogoBytes,
  });

  factory CricketMatch.fromJson(Map<String, dynamic> json) {
    final matchInfo = json;
    return CricketMatch(
      matchId: matchInfo['matchId'] != null ? matchInfo['matchId'].toString() : '', // Provide default value if null
      seriesName: matchInfo['seriesName'] ?? '',
      matchDesc: matchInfo['matchDesc'] ?? '',
      status: matchInfo['status'] ?? '',
      team1SName: matchInfo['team1'] != null && matchInfo['team1']['teamSName'] != null ? matchInfo['team1']['teamSName'] as String : '', // Provide default value if null
      team2SName: matchInfo['team2'] != null && matchInfo['team2']['teamSName'] != null ? matchInfo['team2']['teamSName'] as String : '', // Provide default value if null
      team1LogoBytes: null, // Initially null, will be updated later
      team2LogoBytes: null, // Initially null, will be updated later
    );
  }
}

class LiveMatchesPage extends StatefulWidget {
  const LiveMatchesPage({super.key});

  @override
  _LiveMatchesPageState createState() => _LiveMatchesPageState();
}

class _LiveMatchesPageState extends State<LiveMatchesPage> {
  List<CricketMatch> matches = [];
  bool isLoading = true;
  String errorMessage = '';

  Future<List<dynamic>> fetchData() async {
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
      final matchesData = await fetchData();
      final fetchedMatches = (matchesData).map((matchJson) async {
        final match = CricketMatch.fromJson(matchJson);
        final team1LogoId = matchJson['team1']?['imageId']?.toString() ?? ''; // Convert to string and provide default value
        final team2LogoId = matchJson['team2']?['imageId']?.toString() ?? ''; // Convert to string and provide default value

        final team1LogoBytes = team1LogoId.isNotEmpty ? await ApiService.fetchMatchImage(team1LogoId).then((response) => response.bodyBytes) : null;
        final team2LogoBytes = team2LogoId.isNotEmpty ? await ApiService.fetchMatchImage(team2LogoId).then((response) => response.bodyBytes) : null;

        return CricketMatch(
          matchId: match.matchId,
          seriesName: match.seriesName,
          matchDesc: match.matchDesc,
          status: match.status,
          team1SName: match.team1SName,
          team2SName: match.team2SName,
          team1LogoBytes: team1LogoBytes,
          team2LogoBytes: team2LogoBytes,
        );
      }).toList();

      final resolvedMatches = await Future.wait(fetchedMatches);

      setState(() {
        matches = resolvedMatches;
        isLoading = false;
        errorMessage = '';
      });
    } catch (error) {
      setState(() {
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
            return LiveMatchCard(
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

class LiveMatchCard extends StatelessWidget {
  final CricketMatch match;
  final VoidCallback onTap;

  const LiveMatchCard({
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
                    color: match.status == " " || match.status == "Ongoing"
                        ? Colors.blue[300]
                        : Colors.orange[300], // Match status color
                  ),
                  child: Text(
                    match.status,
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
