import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:quickpost/controller/apis.dart';

class AdminVideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String videoUrl;
  final String uploaderUid;
  final String? title;
  final String? description;
  final Map<String, dynamic>? raw; // optional full doc if you have it

  const AdminVideoPlayerScreen({
    required this.videoId,
    required this.videoUrl,
    required this.uploaderUid,
    this.title,
    this.description,
    this.raw,
    super.key,
  });

  @override
  State<AdminVideoPlayerScreen> createState() => _AdminVideoPlayerScreenState();
}

class _AdminVideoPlayerScreenState extends State<AdminVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isBuffering = false;
  bool _autoPlay = true;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
          if (_autoPlay) _controller.play();
        });
      }).catchError((e) {
        debugPrint('[AdminVideoPlayer] initialize error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load video')));
      });

    _controller.addListener(() {
      final buffering = _controller.value.isBuffering;
      if (buffering != _isBuffering) {
        setState(() => _isBuffering = buffering);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _confirmDialog(String title, String message) async {
    final r = await showDialog<bool>(
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
    return r ?? false;
  }

  Future<void> _approveVideo() async {
    final ok = await _confirmDialog('Approve video', 'Mark this video as approved?');
    if (!ok) return;
    try {
      await Api.videoRef.doc(widget.videoId).update({'status': 'approved', 'flagged': false});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video approved')));
      debugPrint('[Admin] Approved video ${widget.videoId}');
    } catch (e) {
      debugPrint('[Admin] approve error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to approve')));
    }
  }

  Future<void> _removeVideo({bool deleteStorageFile = false}) async {
    final ok = await _confirmDialog('Remove video', 'Remove this video and mark uploader with a strike?');
    if (!ok) return;
    try {
      await Api.videoRef.doc(widget.videoId).update({'status': 'removed', 'flagged': true});
      await Api.userRef.doc(widget.uploaderUid).set({'strikes': FieldValue.increment(1)}, SetOptions(merge: true));
      debugPrint('[Admin] Removed video ${widget.videoId} and incremented strike for ${widget.uploaderUid}');

      // optionally delete file from Firebase Storage:
      if (deleteStorageFile) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(widget.videoUrl);
          await ref.delete();
          debugPrint('[Admin] Deleted storage file for ${widget.videoId}');
        } catch (e) {
          debugPrint('[Admin] failed to delete storage file: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video removed')));
    } catch (e) {
      debugPrint('[Admin] remove error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove')));
    }
  }

  Future<void> _banUser() async {
    final ok = await _confirmDialog('Ban user', 'Ban this user (prevent login)?');
    if (!ok) return;
    try {
      await Api.userRef.doc(widget.uploaderUid).update({'banned': true});
      debugPrint('[Admin] Banned user ${widget.uploaderUid}');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User banned')));
    } catch (e) {
      debugPrint('[Admin] ban error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to ban user')));
    }
  }

  Widget _buildControls() {
    if (!_initialized) {
      return const SizedBox.shrink();
    }
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    return Column(
      children: [
        // playback controls
        Row(
          children: [
            IconButton(
              icon: Icon(_controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle),
              iconSize: 36,
              color: Colors.white,
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  _muted = !_muted;
                  _controller.setVolume(_muted ? 0.0 : 1.0);
                });
              },
            ),
            Expanded(
              child: Slider(
                value: (position.inMilliseconds > 0 && duration.inMilliseconds > 0)
                    ? position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble()
                    : 0,
                max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1,
                onChanged: (value) {
                  final pos = Duration(milliseconds: value.toInt());
                  _controller.seekTo(pos);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        // action buttons
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            spacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _approveVideo,
                icon: Icon(Icons.check),
                label: Text('Approve'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              ElevatedButton.icon(
                onPressed: () => _removeVideo(deleteStorageFile: false),
                icon: Icon(Icons.delete),
                label: Text('Remove'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              ElevatedButton.icon(
                onPressed: _banUser,
                icon: Icon(Icons.block),
                label: Text('Ban user'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? widget.raw?['title'] ?? 'Untitled';
    final description = widget.description ?? widget.raw?['description'] ?? '';
    final views = (widget.raw != null && widget.raw!['views'] != null) ? widget.raw!['views'] : null;
    final likes = (widget.raw != null && widget.raw!['likes'] != null)
        ? (widget.raw!['likes'] is List ? (widget.raw!['likes'] as List).length : (widget.raw!['likes']))
        : null;
    final dislikes = (widget.raw != null && widget.raw!['dislikes'] != null)
        ? (widget.raw!['dislikes'] is List ? (widget.raw!['dislikes'] as List).length : (widget.raw!['dislikes']))
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.purple.shade800,
      ),
      body: Column(
        children: [
          // video area
          AspectRatio(
            aspectRatio: _initialized ? _controller.value.aspectRatio : 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_initialized)
                  VideoPlayer(_controller)
                else
                  Container(color: Colors.black, child: Center(child: CircularProgressIndicator())),
                if (_isBuffering) const Center(child: CircularProgressIndicator()),
                // big center play button overlay
                if (_initialized && !_controller.value.isPlaying)
                  GestureDetector(
                    onTap: () => setState(() => _controller.play()),
                    child: Icon(Icons.play_circle, size: 80, color: Colors.white54),
                  ),
              ],
            ),
          ),

          // video info
          Container(
            width: double.infinity,
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 6),
                  Text(description, style: TextStyle(color: Colors.white70)),
                ],
                SizedBox(height: 8),
                Row(
                  children: [
                    if (views != null) Chip(label: Text('Views: $views')),
                    SizedBox(width: 8),
                    if (likes != null) Chip(label: Text('Likes: $likes')),
                    SizedBox(width: 8),
                    if (dislikes != null) Chip(label: Text('Dislikes: $dislikes')),
                  ],
                ),
              ],
            ),
          ),

          // controls & actions
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(child: _buildControls()),
            ),
          ),
        ],
      ),
    );
  }
}
