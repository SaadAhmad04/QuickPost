import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../controller/apis.dart'; // Optional for icons

class VideoAnalyticsScreen extends StatelessWidget {
  final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
      .collection('videos')
      .where('uid', isEqualTo: Api.auth.currentUser!.uid) // Replace with actual user UID
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Analytics', style: TextStyle(color: Colors.purple.shade800)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.purple.shade800),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data available.'));
          }

          List<int> likesData = [];
          List<int> dislikesData = [];
          List<int> commentsData = [];
          List<int> viewsData = []; // Add views if available

          for (var videoDoc in snapshot.data!.docs) {
            likesData.add(List.from(videoDoc['likes']).length);
            dislikesData.add(List.from(videoDoc['dislikes']).length);
            commentsData.add(videoDoc['comments'] ?? 0);
           // viewsData.add(videoDoc['views'] ?? 0);
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Likes vs Dislikes'),
                  SizedBox(height: 16),
                  _buildBarChart(likesData, dislikesData, 'Likes', 'Dislikes'),

                  SizedBox(height: 32),
                  _buildSectionTitle('Comments'),
                  SizedBox(height: 16),
                  _buildLineChart(commentsData, 'Comments'),

                  SizedBox(height: 32),
                  _buildSectionTitle('Views'),
                  SizedBox(height: 16),
                  _buildLineChart(viewsData, 'Views'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.purple.shade800,
      ),
    );
  }

  Widget _buildBarChart(List<int> data1, List<int> data2, String label1, String label2) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 10, spreadRadius: 2)
        ],
      ),
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          barGroups: List.generate(data1.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data1[index].toDouble(),
                  color: Colors.purple.shade800,
                  width: 10,
                ),
                BarChartRodData(
                  toY: data2[index].toDouble(),
                  color: Colors.red.shade600,
                  width: 10,
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Video ${value.toInt() + 1}', style: TextStyle(fontSize: 12)),
                  );
                },
              ),
            ),
          ),

          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<int> data, String label) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 10, spreadRadius: 2)
        ],
      ),
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Video ${value.toInt() + 1}',
                      style: TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),

          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(data.length, (index) {
                return FlSpot(index.toDouble(), data[index].toDouble());
              }),
              isCurved: true,
              color: Colors.purple.shade800,
              barWidth: 4,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
