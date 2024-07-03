import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cricbowled/utils/imageloading.dart';
import 'dart:typed_data'; // For Uint8List
import 'scoreboard.dart';

class SeriesPage extends StatefulWidget {
  const SeriesPage({super.key});

  @override
  _SeriesPageState createState() => _SeriesPageState();
}

class _SeriesPageState extends State<SeriesPage> {
  String selectedCategory = 'international';
  Map<String, List<dynamic>> seriesMap = {};

  Future<void> _fetchSeries(String category) async {
    final url = Uri.parse('https://cricbuzz-cricket.p.rapidapi.com/schedule/v1/$category');
    final headers = {
      'X-RapidAPI-Key': '419e740854msh11018c704b8e93bp1d17a1jsn83dc5cc22859',
      'X-RapidAPI-Host': 'cricbuzz-cricket.p.rapidapi.com'
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body.toString());
        final List<dynamic> seriesList = data['matchScheduleMap'] ?? [];

        // Group matches by seriesName
        Map<String, List<dynamic>> groupedSeries = {};
        for (var schedule in seriesList) {
          var scheduleAdWrapper = schedule['scheduleAdWrapper'];
          if (scheduleAdWrapper == null) continue;
          var matchScheduleList = scheduleAdWrapper['matchScheduleList'] as List<dynamic>;

          for (var series in matchScheduleList) {
            var seriesName = series['seriesName'] ?? 'Unknown Series';
            if (!groupedSeries.containsKey(seriesName)) {
              groupedSeries[seriesName] = [];
            }
            groupedSeries[seriesName]!.add(series);
          }
        }

        setState(() {
          seriesMap[category] = groupedSeries.entries.toList();
        });
      } else {
        throw Exception('Data is temporarily unavailable. Please refresh the page in a few minutes.');
      }
    } catch (error) {
      print('Data is not available');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSeries(selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryButton('international'),
                  _buildCategoryButton('league'),
                  _buildCategoryButton('domestic'),
                  _buildCategoryButton('women'),
                ],
              ),
            ),
          ),
          Expanded(
            child: seriesMap[selectedCategory] == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: seriesMap[selectedCategory]!.length,
              itemBuilder: (context, index) {
                var entry = seriesMap[selectedCategory]![index];
                var seriesName = entry.key;
                var seriesList = entry.value;
                return ExpansionTile(
                  title: Text(seriesName),
                  children: seriesList.expand<Widget>((series) {
                    var matches = series['matchInfo'] as List<dynamic>;
                    return matches.map<Widget>((match) {
                      return FutureBuilder(
                        future: _buildMatchCard(match),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return snapshot.data as Widget;
                          }
                        },
                      );
                    }).toList();
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedCategory = category;
          if (seriesMap[category] == null) {
            _fetchSeries(category);
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedCategory == category ? Colors.orange : Colors.blue[900],

      ),
      child: Text(category.toUpperCase(),style: TextStyle(color: Colors.white)),
    );
  }

  Future<Widget> _buildMatchCard(dynamic match) async {
    var team1 = match['team1'] ?? {};
    var team2 = match['team2'] ?? {};
    // var venueInfo = match['venueInfo'] ?? {};
    var matchDesc = match['matchDesc'] ?? 'Unknown Match';

      final team1LogoId = match['team1']?['imageId']?.toString() ?? '';
      final team2LogoId = match['team2']?['imageId']?.toString() ?? '';


      final team1LogoBytes = team1LogoId.isNotEmpty ? await ApiService.fetchMatchImage(team1LogoId).then((response) => response.bodyBytes) : null;
      final team2LogoBytes = team2LogoId.isNotEmpty ? await ApiService.fetchMatchImage(team2LogoId).then((response) => response.bodyBytes) : null;

    return InkWell(
      onTap: () {
        // Handle match tap
      },
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
                matchDesc,
                style: const TextStyle(
                  fontSize: 14.0,
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
                            team1LogoBytes != null
                                ? Image.memory(
                              team1LogoBytes,
                              width: constraints.maxWidth * 0.2,
                              height: constraints.maxWidth * 0.2,
                            )
                                : Image.asset(
                              'assets/images/placeholder.jpg', // Local placeholder image
                              width: constraints.maxWidth * 0.2,
                              height: constraints.maxWidth * 0.2,
                            ),
                            Text(
                              team1['teamSName'] ?? 'Unknown',
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
                            team2LogoBytes != null
                                ? Image.memory(
                              team2LogoBytes,
                              width: constraints.maxWidth * 0.2,
                              height: constraints.maxWidth * 0.2,
                            )
                                : Image.asset(
                              'assets/images/placeholder.jpg', // Local placeholder image
                              width: constraints.maxWidth * 0.2,
                              height: constraints.maxWidth * 0.2,
                            ),
                            Text(
                              team2['teamSName'] ?? 'Unknown',
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
                    color: Colors.orange[300],
                  ),
                  child: Text(
                    _getFormattedTime(int.parse(match['startDate']) ?? 0),
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

  String _getFormattedTime(int startDate) {
    if (startDate == 0) return 'Unknown Time';
    final formatter = DateFormat('EEE, dd MMM, hh:mm a');
    return formatter.format(DateTime.fromMillisecondsSinceEpoch(startDate));
  }
}
