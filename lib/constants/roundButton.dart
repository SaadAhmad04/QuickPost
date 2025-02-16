import 'package:flutter/material.dart';
import '../../main.dart';

class RoundButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool loading;

  const RoundButton(
      {super.key,
        required this.title,
        required this.onTap,
        this.loading = false});

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: mq.height * .07,
        width: mq.width * .8,
        decoration: BoxDecoration(
            color: Colors.purple.shade800, borderRadius: BorderRadius.circular(23)),
        child: Center(
          child: loading
              ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,),
              )
              : Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}
