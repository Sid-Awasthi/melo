import 'package:flutter/material.dart';

class MyPostButton extends StatelessWidget {
  final void Function()? onPressed;

  const MyPostButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(left: 10),
        child: Center(
          child: Icon(
            Icons.done,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
