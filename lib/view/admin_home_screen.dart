// lib/view/admin_home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quickpost/controller/apis.dart';
import 'package:quickpost/model/user_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:quickpost/view/user_video_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final videoRef = Api.videoRef;
  final userRef = Api.userRef;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ACTIONS: Approve, Remove video, Ban user
  Future<void> _approveVideo(String videoId) async {
    try {
      await videoRef.doc(videoId).update({'status': 'approved', 'flagged': false});
      print('[Admin] Approved video $videoId');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video approved')));
    } catch (e) {
      print('[Admin] approve error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to approve')));
    }
  }

  Future<void> _removeVideo(String videoId, String uploaderUid) async {
    final confirm = await _confirmDialog('Remove video', 'Are you sure you want to remove this video?');
    if (!confirm) return;
    try {
      await videoRef.doc(videoId).update({'status': 'removed', 'flagged': true});
      // Optionally increment strike count on user doc (if you store strikes)
      try {
        await userRef.doc(uploaderUid).set({'strikes': FieldValue.increment(1)}, SetOptions(merge: true));
      } catch (e) {
        print('[Admin] failed to increment strike for $uploaderUid: $e');
      }
      print('[Admin] Removed video $videoId and incremented strike for $uploaderUid');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video removed')));
    } catch (e) {
      print('[Admin] remove error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove')));
    }
  }

  Future<void> _banUser(String uid) async {
    final confirm = await _confirmDialog('Ban user', 'Are you sure you want to ban this user? This will prevent login.');
    if (!confirm) return;
    try {
      await userRef.doc(uid).update({'banned': true});
      print('[Admin] Banned user $uid');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User banned')));
    } catch (e) {
      print('[Admin] ban error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to ban user')));
    }
  }

  Future<bool> _confirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Confirm')),
        ],
      ),
    );
    return result ?? false;
  }

  // Show video detail bottom sheet
  void _showVideoDetail(Map<String, dynamic> docData, String docId) {
    final title = docData['title'] ?? 'Untitled';
    final uploaderUid = docData['uid'] ?? '';
    final thumbnail = docData['thumbnail'] ?? '';
    final description = docData['description'] ?? '';
    final flaggedReason = docData['flagReason'] ?? docData['report_reason'] ?? 'N/A';
    final views = docData['views'] ?? 0;
    final likes = (docData['likes'] is List) ? (docData['likes'] as List).length : (docData['likes'] ?? 0);
    final dislikes = (docData['dislikes'] is List) ? (docData['dislikes'] as List).length : (docData['dislikes'] ?? 0);
    print('[Admin] open video detail id=$docId raw=$docData');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets.add(EdgeInsets.all(16)),
          child: Wrap(
            children: [
              ListTile(
                leading: thumbnail != '' ? Image.network(thumbnail, width: 56, height: 56, fit: BoxFit.cover) : Icon(Icons.play_circle_fill),
                title: Text(title),
                subtitle: Text('Uploader: $uploaderUid'),
              ),
              ListTile(title: Text('Description'), subtitle: Text(description)),
              ListTile(title: Text('Flagged reason'), subtitle: Text(flaggedReason.toString())),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  children: [
                    _statChip(Icons.remove_red_eye, views.toString()),
                    SizedBox(width: 8),
                    _statChip(Icons.thumb_up, likes.toString()),
                    SizedBox(width: 8),
                    _statChip(Icons.thumb_down, dislikes.toString()),
                  ],
                ),
              ),
              ButtonBar(
                alignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _approveVideo(docId);
                    },
                    icon: Icon(Icons.check),
                    label: Text('Approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _removeVideo(docId, uploaderUid);
                    },
                    icon: Icon(Icons.delete),
                    label: Text('Remove'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _banUser(uploaderUid);
                    },
                    icon: Icon(Icons.block),
                    label: Text('Ban user'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(text, style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.purple.shade700,
    );
  }

  // Moderation tab: list flagged/pending videos
  Widget _buildModerationTab() {
    // Assumes you have a 'flagged' boolean or 'status' field to filter pending videos.
    // If your schema differs, change the query accordingly.
    final stream = videoRef.where('flagged', isEqualTo: true).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snap.hasData || snap.data!.docs.isEmpty) return Center(child: Text('No flagged videos'));

        return ListView.separated(
          padding: EdgeInsets.all(12),
          itemCount: snap.data!.docs.length,
          separatorBuilder: (_, __) => Divider(),
          itemBuilder: (ctx, i) {
            final doc = snap.data!.docs[i];
            final data = doc.data() as Map<String, dynamic>;
            // debug print each raw doc so admin can paste if shape differs
            print('[Admin] flagged video doc id=${doc.id} raw=$data');

            final title = data['title'] ?? 'Untitled';
            final thumbnail = data['thumbnail'] ?? '';
            final uploader = data['uid'] ?? 'unknown';
            final reason = data['flagReason'] ?? data['report_reason'] ?? '';

            return ListTile(
              leading: thumbnail != '' ? Image.network(thumbnail, width: 80, fit: BoxFit.cover) : Icon(Icons.play_circle_fill, size: 48),
              title: Text(title),
              subtitle: Text('By: $uploader\nReason: ${reason.toString()}'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'approve') await _approveVideo(doc.id);
                  if (v == 'remove') await _removeVideo(doc.id, uploader);
                  if (v == 'ban') await _banUser(uploader);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'approve', child: Text('Approve')),
                  PopupMenuItem(value: 'remove', child: Text('Remove')),
                  PopupMenuItem(value: 'ban', child: Text('Ban user')),
                ],
              ),
              onTap: () => _showVideoDetail(data, doc.id),
            );
          },
        );
      },
    );
  }

  // Analytics tab: client-side aggregation of users and videos
  Widget _buildAnalyticsTab() {
    // We'll load users and videos and compute aggregates client-side.
    // This is OK for small/medium datasets; for large scale use Cloud Functions / BigQuery.
    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        userRef.get(),
        videoRef.get(),
      ]),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return Center(child: Text('No data'));

        final usersSnap = snap.data![0];
        final videosSnap = snap.data![1];

        // Build user map
        final Map<String, Map<String, dynamic>> usersMap = {};
        for (var d in usersSnap.docs) {
          usersMap[d.id] = d.data() as Map<String, dynamic>;
        }

        // Build video list and compute per-user aggregates
        final List<Map<String, dynamic>> videos = [];
        final Map<String, int> userVideoCount = {};
        final Map<String, int> userViews = {};
        final Map<String, int> userLikes = {};
        final Map<String, int> userDislikes = {};

        int parseCount(dynamic value) {
          if (value == null) return 0;
          if (value is int) return value;
          if (value is List) return value.length;
          if (value is Map) return value.length;
          // fallback: try parse numeric string, otherwise 0
          try {
            final parsed = num.parse(value.toString());
            return parsed.toInt();
          } catch (e) {
            return 0;
          }
        }

        for (var v in videosSnap.docs) {
          final data = v.data() as Map<String, dynamic>;
          videos.add({'id': v.id, ...data});

          final uid = data['uid'] ?? 'unknown';
          userVideoCount[uid] = (userVideoCount[uid] ?? 0) + 1;

          final views = (data['views'] is int) ? data['views'] as int : int.tryParse('${data['views']}') ?? 0;
          userViews[uid] = (userViews[uid] ?? 0) + views;

          final likesInt = parseCount(data['likes']);       // <<< guaranteed int
          final dislikesInt = parseCount(data['dislikes']); // <<< guaranteed int

          userLikes[uid] = (userLikes[uid] ?? 0) + likesInt; // safe: int + int -> int
          // optionally track dislikes too
          userDislikes[uid] = (userDislikes[uid] ?? 0) + dislikesInt;
        }

        // Top users by videos
        final topUsersByVideos = userVideoCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topVideosByViews = videos.toList()
          ..sort((a, b) {
            final av = (a['views'] is int) ? a['views'] as int : int.tryParse('${a['views']}') ?? 0;
            final bv = (b['views'] is int) ? b['views'] as int : int.tryParse('${b['views']}') ?? 0;
            return bv.compareTo(av);
          });

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // summary cards
              Row(
                children: [
                  _summaryCard('Total users', usersSnap.docs.length.toString()),
                  SizedBox(width: 8),
                  _summaryCard('Total videos', videosSnap.docs.length.toString()),
                  SizedBox(width: 8),
                  _summaryCard('Flagged', videos.where((v) => (v['flagged'] == true)).length.toString()),
                ],
              ),
              SizedBox(height: 12),

              // Top users list
              // Expanded(
              //   child: ListView(
              //     children: [
              //       Text('Top users by number of videos', style: TextStyle(fontWeight: FontWeight.bold)),
              //       SizedBox(height: 8),
              //       ...topUsersByVideos.take(10).map((e) {
              //         final uid = e.key;
              //         final count = e.value;
              //         final userData = usersMap[uid];
              //         final name = userData?['name'] ?? uid;
              //         final email = userData?['email'] ?? '';
              //         final views = userViews[uid] ?? 0;
              //         final likes = userLikes[uid] ?? 0;
              //         return ListTile(
              //           title: Text(name),
              //           subtitle: Text('$email\nVideos: $count  Views: $views  Likes: $likes'),
              //           isThreeLine: true,
              //         );
              //       }).toList(),
              //
              //       SizedBox(height: 16),
              //       Text('Top videos by views', style: TextStyle(fontWeight: FontWeight.bold)),
              //       SizedBox(height: 8),
              //       ...topVideosByViews.take(10).map((v) {
              //         return ListTile(
              //           leading: v['thumbnail'] != null ? Image.network(v['thumbnail'], width: 80, fit: BoxFit.cover) : null,
              //           title: Text(v['title'] ?? 'Untitled'),
              //           subtitle: Text('Views: ${v['views'] ?? 0}  Likes: ${v['likes'] is List ? (v['likes'] as List).length : v['likes'] ?? 0}'),
              //         );
              //       }).toList(),
              //
              //       SizedBox(height: 24),
              //
              //       // Small chart example (videos per top-5 users)
              //       Text('Videos count (top 5 users)', style: TextStyle(fontWeight: FontWeight.bold)),
              //       SizedBox(height: 200, child: _buildBarChartForTopUsers(topUsersByVideos.take(5).toList(), usersMap)),
              //       SizedBox(height: 24),
              //     ],
              //   ),
              // ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Top users by number of videos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    SizedBox(height: 8),

                    // Users list: cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: topUsersByVideos.take(10).map((e) {
                          final uid = e.key;
                          final count = e.value;
                          final userData = usersMap[uid];
                          final name = userData?['name'] ?? uid;
                          final email = userData?['email'] ?? '';
                          final views = userViews[uid] ?? 0;
                          final likes = userLikes[uid] ?? 0;

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // Open user videos screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => UserVideosScreen(uid: uid, userName: name)),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // avatar placeholder
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.purple.shade100,
                                      child: Text(
                                        (name.isNotEmpty ? name[0].toUpperCase() : 'U'),
                                        style: TextStyle(color: Colors.purple.shade800, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          SizedBox(height: 4),
                                          Text(email, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                          SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              _smallStat(Icons.videocam, '$count videos'),
                                              _smallStat(Icons.remove_red_eye, '$views views'),
                                              _smallStat(Icons.thumb_up, '$likes likes'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Top videos by views', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    SizedBox(height: 8),

                    // Top videos list — clickable to open video detail sheet
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        children: topVideosByViews.take(10).map((v) {
                          final thumb = v['thumbnail'];
                          final title = v['title'] ?? 'Untitled';
                          final views = (v['views'] is int) ? v['views'] : int.tryParse('${v['views']}') ?? 0;
                          final likes = (v['likes'] is List) ? (v['likes'] as List).length : (v['likes'] ?? 0);
                          final uploader = v['uid'] ?? 'unknown';
                          final vidId = v['id'] ?? '';

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ListTile(
                              onTap: () {
                                // open video detail bottom sheet (reuse the admin detail modal if present)
                                // If in same file, you had a _showVideoDetail method — call it; otherwise show simple details:
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (ctx) {
                                    return Padding(
                                      padding: MediaQuery.of(ctx).viewInsets.add(EdgeInsets.all(16)),
                                      child: Wrap(children: [
                                        ListTile(
                                          leading: thumb != null ? Image.network(thumb, width: 80, height: 56, fit: BoxFit.cover) : Icon(Icons.play_circle_fill),
                                          title: Text(title),
                                          subtitle: Text('Views: $views  Likes: $likes\nUploader: $uploader'),
                                        ),
                                        SizedBox(height: 8),
                                        ButtonBar(
                                          alignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                Navigator.of(ctx).pop();
                                                await FirebaseFirestore.instance.collection('videos').doc(vidId).update({'status':'approved','flagged':false});
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved')));
                                              },
                                              icon: Icon(Icons.check),
                                              label: Text('Approve'),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                Navigator.of(ctx).pop();
                                                await FirebaseFirestore.instance.collection('videos').doc(vidId).update({'status':'removed','flagged':true});
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Removed')));
                                              },
                                              icon: Icon(Icons.delete),
                                              label: Text('Remove'),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                      ]),
                                    );
                                  },
                                );
                              },
                              leading: thumb != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(thumb, width: 80, fit: BoxFit.cover)) : null,
                              title: Text(title),
                              subtitle: Text('Views: $views  Likes: $likes'),
                              trailing: Icon(Icons.chevron_right),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Videos count (top 5 users)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 8),
                    SizedBox(height: 200, child: _buildBarChartForTopUsers(topUsersByVideos.take(5).toList(), usersMap)),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade700)),
            SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _smallStat(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBarChartForTopUsers(List<MapEntry<String, int>> entries, Map<String, Map<String, dynamic>> usersMap) {
    if (entries.isEmpty) return Center(child: Text('No data'));
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < entries.length; i++) {
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: entries[i].value.toDouble(), color: Colors.purple.shade800, width: 12),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: BarChart(BarChartData(
        barGroups: bars,
        // inside _buildBarChartForTopUsers when building FlTitlesData:
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double val, TitleMeta meta) {
                final idx = val.toInt();
                if (idx < entries.length) {
                  final uid = entries[idx].key;
                  final name = usersMap[uid]?['name'] ?? uid.substring(0, 6);
                  return SideTitleWidget(
                    meta: meta, // 👈 REQUIRED in new fl_chart
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return SideTitleWidget(
                  meta: meta,
                  child: const Text(''),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = Api.user?.name ?? 'admin';
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Admin Dashboard' , style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.purple.shade800,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: Text('Moderation' , style: TextStyle(color: Colors.white),),),
            Tab(child: Text('Analytics' , style: TextStyle(color: Colors.white),)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: (){
              Api.isAdmin = false;
              Api.logout(context);
            },
            icon: Icon(Icons.logout , color: Colors.red,)
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModerationTab(),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // quick refresh action
          setState(() {});
        },
        label: Text('Refresh'),
        icon: Icon(Icons.refresh),
      ),
    );
  }
}
