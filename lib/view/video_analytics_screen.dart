import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../controller/apis.dart'; // Optional for icons

class VideoAnalyticsScreen extends StatefulWidget {
  @override
  _VideoAnalyticsScreenState createState() => _VideoAnalyticsScreenState();
}

class _VideoAnalyticsScreenState extends State<VideoAnalyticsScreen> {
  final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
      .collection('videos')
      .where('uid', isEqualTo: Api.auth.currentUser!.uid)
      .snapshots();

  // UI state: which big chart to show
  String _selectedMetric =
      'likes_vs_dislikes'; // other options: 'comments', 'views'

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple.shade800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Analytics', style: TextStyle(color: purple)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: purple),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          // debug: connection state / snapshot status
          print('StreamBuilder connectionState: ${snapshot.connectionState}');
          if (snapshot.hasError) {
            print('Firestore error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('No video docs found for user ${Api.auth.currentUser!.uid}');
            return Center(child: Text('No data available.'));
          }

          // Arrays to plot
          final List<int> likesData = [];
          final List<int> dislikesData = [];
          final List<int> commentsData = [];
          final List<int> viewsData = [];

          // Also keep per-video meta for list
          final List<Map<String, dynamic>> videoMeta = [];

          for (var videoDoc in snapshot.data!.docs) {
            final data = videoDoc.data() as Map<String, dynamic>;
            // Print the raw doc for debugging. Paste this output back if you want me to refine handling.
            print('VIDEO DOC id=${videoDoc.id} rawData=$data');

            // Helper to parse possibly-many shapes (list, map, int)
            int parseCount(dynamic value) {
              if (value == null) return 0;
              if (value is int) return value;
              if (value is List) return value.length;
              if (value is Map) return value.length;
              // if stored as set-like structures or custom, attempt to convert
              try {
                return int.parse(value.toString());
              } catch (e) {
                print('parseCount fallback failed for value=$value: $e');
                return 0;
              }
            }

            final likesCount = parseCount(data['likes']);
            final dislikesCount = parseCount(data['dislikes']);
            final commentsCount = parseCount(data['comments']);
            final viewsCount = parseCount(data['views']);

            likesData.add(likesCount);
            dislikesData.add(dislikesCount);
            commentsData.add(commentsCount);
            viewsData.add(viewsCount);

            videoMeta.add({
              'id': videoDoc.id,
              'title': data['title'] ?? 'Untitled',
              'thumbnail': data['thumbnail'] ?? null,
              'createdAt': data['createdAt'] ?? null,
              'likes': likesCount,
              'dislikes': dislikesCount,
              'comments': commentsCount,
              'views': viewsCount,
              'raw': data,
            });
          }

          // Aggregates
          final totalLikes = likesData.fold(0, (a, b) => a + b);
          final totalDislikes = dislikesData.fold(0, (a, b) => a + b);
          final totalComments = commentsData.fold(0, (a, b) => a + b);
          final totalViews = viewsData.fold(0, (a, b) => a + b);
          final engagementRate =
              totalViews > 0 ? (totalLikes + totalComments) / totalViews : 0;

          return SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary cards
                  _buildSummaryRow(
                      purple,
                      totalLikes,
                      totalDislikes,
                      totalViews,
                      totalComments,
                      double.parse(engagementRate.toString())),

                  SizedBox(height: 20),

                  // Metric selector chips
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('Likes vs Dislikes'),
                        selected: _selectedMetric == 'likes_vs_dislikes',
                        onSelected: (_) => setState(
                            () => _selectedMetric = 'likes_vs_dislikes'),
                      ),
                      ChoiceChip(
                        label: Text('Comments'),
                        selected: _selectedMetric == 'comments',
                        onSelected: (_) =>
                            setState(() => _selectedMetric = 'comments'),
                      ),
                      ChoiceChip(
                        label: Text('Views'),
                        selected: _selectedMetric == 'views',
                        onSelected: (_) =>
                            setState(() => _selectedMetric = 'views'),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Main chart area
                  if (_selectedMetric == 'likes_vs_dislikes')
                    _buildBarChart(likesData, dislikesData, 'Likes', 'Dislikes')
                  else if (_selectedMetric == 'comments')
                    _buildLineChart(commentsData, 'Comments')
                  else
                    _buildLineChart(viewsData, 'Views'),

                  SizedBox(height: 24),

                  // Per-video list with micro-charts + debug toggles
                  Text('Your videos',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: purple)),
                  SizedBox(height: 12),
                  Column(
                    children: videoMeta.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final vm = entry.value;
                      return _buildVideoCard(vm, idx, purple);
                    }).toList(),
                  ),

                  SizedBox(height: 32),
                  // Debug hint
                  Text(
                    'Debug: Firestore raw doc for first video (printed to console). '
                    'If fields are missing or appear in a different shape, paste the console output here and I will adapt the parser.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(Color purple, int likes, int dislikes, int views,
      int comments, double engagementRate) {
    Widget card(String label, String value, {IconData? icon}) {
      return Expanded(
        child: Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Icon(icon, color: Colors.grey.shade700, size: 18),
              SizedBox(height: 6),
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: purple)),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card('Likes', likes.toString(), icon: Icons.thumb_up),
        card('Dislikes', dislikes.toString(), icon: Icons.thumb_down),
        card('Views', views.toString(), icon: Icons.remove_red_eye),
        card('Comments', comments.toString(), icon: Icons.comment),
        // Engagement small card (non-expanded)
      ],
    );
  }

  Widget _buildBarChart(
      List<int> data1, List<int> data2, String label1, String label2) {
    final maxLen = (data1.length > data2.length) ? data1.length : data2.length;
    final maxY = [
      if (data1.isNotEmpty) data1.reduce((a, b) => a > b ? a : b),
      if (data2.isNotEmpty) data2.reduce((a, b) => a > b ? a : b)
    ].fold<int>(0, (prev, e) => e > prev ? e : prev);
    final yAxisMax = (maxY * 1.2).clamp(10, double.infinity).toDouble();

    return Container(
      height: 320,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)]),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legendDot(Colors.purple.shade800, label1),
              SizedBox(width: 8),
              _legendDot(Colors.red.shade600, label2),
            ],
          ),
          SizedBox(height: 6),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: yAxisMax,
                groupsSpace: 18,
                barGroups: List.generate(maxLen, (index) {
                  final left =
                      index < data1.length ? data1[index].toDouble() : 0.0;
                  final right =
                      index < data2.length ? data2[index].toDouble() : 0.0;
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 6,
                    barRods: [
                      BarChartRodData(
                          toY: left,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.purple.shade800),
                      BarChartRodData(
                          toY: right,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.red.shade600),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('V ${idx + 1}',
                              style: TextStyle(fontSize: 11)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12))
      ],
    );
  }

  Widget _buildLineChart(List<int> data, String label) {
    final maxY = data.isNotEmpty
        ? data.reduce((a, b) => a > b ? a : b).toDouble()
        : 10.0;
    final yAxisMax = (maxY * 1.2).clamp(10, double.infinity);

    return Container(
      height: 320,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: yAxisMax.toDouble(),
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('V ${val.toInt() + 1}',
                              style: TextStyle(fontSize: 11)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                        data.length,
                        (index) =>
                            FlSpot(index.toDouble(), data[index].toDouble())),
                    isCurved: true,
                    color: Colors.purple.shade800,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> vm, int index, Color purple) {
    final title = vm['title'] ?? 'Untitled';
    final thumbnail = vm['thumbnail'];
    final likes = vm['likes'] ?? 0;
    final dislikes = vm['dislikes'] ?? 0;
    final comments = vm['comments'] ?? 0;
    final views = vm['views'] ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8)]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail (if available)
          if (thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(thumbnail,
                  width: 90,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _thumbPlaceholder()),
            )
          else
            _thumbPlaceholder(),

          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _miniStat(Icons.thumb_up, likes.toString()),
                    _miniStat(Icons.thumb_down, dislikes.toString()),
                    _miniStat(Icons.comment, comments.toString()),
                    _miniStat(Icons.remove_red_eye, views.toString()),
                  ],
                ),
              ],
            ),
          ),
          // index label
          Text('V${index + 1}', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 90,
      height: 56,
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Icon(Icons.play_arrow, color: Colors.grey.shade600),
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade700),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}
