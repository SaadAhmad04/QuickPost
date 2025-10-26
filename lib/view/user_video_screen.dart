import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quickpost/controller/apis.dart';

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quickpost/controller/apis.dart';
import 'package:intl/intl.dart';

import 'admin_video_player_screen.dart'; // add intl to pubspec.yaml if not present

class UserVideosScreen extends StatelessWidget {
  final String uid;
  final String userName;
  const UserVideosScreen({required this.uid, required this.userName, super.key});

  // parseCount helper (ensure int)
  int parseCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is List) return value.length;
    if (value is Map) return value.length;
    try {
      return num.parse(value.toString()).toInt();
    } catch (e) {
      return 0;
    }
  }

  String _formatPostedOn(dynamic postedOn) {
    try {
      // your sample shows a millisecond epoch number such as 1738509611976
      final ms = (postedOn is int) ? postedOn : int.tryParse(postedOn?.toString() ?? '') ?? 0;
      if (ms <= 0) return 'Unknown date';
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat.yMMMd().add_jm().format(dt);
    } catch (e) {
      return 'Unknown date';
    }
  }

  Future<void> _approveVideo(BuildContext context, String videoId) async {
    await Api.videoRef.doc(videoId).update({'status':'approved','flagged':false});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video approved')));
  }

  Future<void> _removeVideo(BuildContext context, String videoId, String uploaderUid) async {
    await Api.videoRef.doc(videoId).update({'status':'removed','flagged':true});
    await Api.userRef.doc(uploaderUid).set({'strikes': FieldValue.increment(1)}, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video removed and strike added')));
  }

  Future<void> _banUser(BuildContext context, String uid) async {
    await Api.userRef.doc(uid).update({'banned': true});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User banned')));
  }

  Widget _fieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName\'s Videos'),
        backgroundColor: Colors.purple.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Api.videoRef.where('uid', isEqualTo: uid).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No videos'));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: snap.data!.docs.length,
            itemBuilder: (ctx, i) {

              final docs = snap.data!.docs.toList();

              // sort by posted_on descending (handle missing or non-int values)
              docs.sort((a, b) {
                final ma = (a.data() as Map<String, dynamic>)['posted_on'];
                final mb = (b.data() as Map<String, dynamic>)['posted_on'];
                final inta = (ma is int) ? ma : int.tryParse(ma?.toString() ?? '') ?? 0;
                final intb = (mb is int) ? mb : int.tryParse(mb?.toString() ?? '') ?? 0;
                return intb.compareTo(inta); // descending
              });


              final doc = snap.data!.docs[i];
              final data = doc.data() as Map<String, dynamic>;

              // Fields present in your sample doc
              final title = data['title'] ?? 'Untitled';
              final description = data['description'] ?? '';
              final url = data['url'] ?? '';
              final postedOn = data['posted_on'];
              final views = parseCount(data['views']);
              final likes = parseCount(data['likes']);
              final dislikes = parseCount(data['dislikes']);
              final comments = parseCount(data['comments']);
              final viewedByCount = parseCount(data['viewedBy']);
              final categories = (data['category'] is List) ? (data['category'] as List).map((e) => e.toString()).join(', ') : (data['category']?.toString() ?? '');
              final latitude = data['latitude']?.toString() ?? '';
              final longitude = data['longitude']?.toString() ?? '';

              final vidId = doc.id;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      if (description.isNotEmpty) Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        Chip(label: Text('Views: $views')),
                        Chip(label: Text('Likes: $likes')),
                        Chip(label: Text('Dislikes: $dislikes')),
                        Chip(label: Text('Comments: $comments')),
                        Chip(label: Text('Seen by: $viewedByCount')),
                      ]),
                      const SizedBox(height: 8),
                      Text('Posted: ${_formatPostedOn(postedOn)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'approve') await _approveVideo(context, vidId);
                      if (v == 'remove') await _removeVideo(context, vidId, uid);
                      if (v == 'ban') await _banUser(context, uid);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'approve', child: Text('Approve')),
                      const PopupMenuItem(value: 'remove', child: Text('Remove')),
                      const PopupMenuItem(value: 'ban', child: Text('Ban user')),
                    ],
                  ),
                  onTap: () {
                    // show detail bottom sheet with only available fields
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminVideoPlayerScreen(
                          videoId: vidId,
                          videoUrl: url,
                          uploaderUid: uid,
                          title: title,
                          description: description,
                          raw: data, // optional
                        ),
                      ),
                    );

                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
