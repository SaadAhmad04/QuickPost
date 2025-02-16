import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../main.dart';

class PlayVideo extends StatefulWidget {
  final String videoUrl;
  final String id;

  const PlayVideo({Key? key, required this.videoUrl, required this.id})
      : super(key: key);

  @override
  State<PlayVideo> createState() => _PlayVideoState();
}


class _PlayVideoState extends State<PlayVideo> {
  late IconData _floatingButtonIcon;
  late VideoPlayerController _controller;
  bool showIcon = false;
  double _sliderValue = 0.0;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();

    _floatingButtonIcon = Icons.play_arrow; // Set the default icon as play

    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {}); // Refresh UI after initialization

        _totalDuration = _controller.value.duration;

        _controller.addListener(() {
          setState(() {
            _currentPosition = _controller.value.position;
            _sliderValue = _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;

            if (_controller.value.position >= _controller.value.duration) {
              _floatingButtonIcon = Icons.replay;
            } else if (_controller.value.isPlaying) {
              _floatingButtonIcon = Icons.pause;
            } else {
              _floatingButtonIcon = Icons.play_arrow;
            }
          });
        });

        // Auto-play video once initialized
        _controller.play();
        _floatingButtonIcon = Icons.pause; // Update icon after auto-play
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? Stack(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  showIcon = !showIcon;
                });
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          if (showIcon)
            Positioned(
              top: MediaQuery.of(context).size.height / 2.5,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(_floatingButtonIcon, color: Colors.white, size: 40),
                    onPressed: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                          _floatingButtonIcon = Icons.play_arrow;
                        } else {
                          _controller.play();
                          _floatingButtonIcon = Icons.pause;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Slider for video progress
                Slider(
                  value: _sliderValue,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      _sliderValue = value;
                      final position = Duration(
                        milliseconds: (value * _totalDuration.inMilliseconds).toInt(),
                      );
                      _controller.seekTo(position);
                      _currentPosition = position; // Update only the current position
                    });
                  },
                ),
                // Display elapsed time and remaining time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Elapsed time (left side)
                    Text(
                      _formatDuration(_currentPosition),
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    // Remaining time (right side)
                    Text(
                      _formatDuration(_totalDuration - _currentPosition),
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      )
          : Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
      bottomNavigationBar: InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.purple.shade800,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Center(
            child: Text(
              'Back',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to format the duration into minutes:seconds
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}


