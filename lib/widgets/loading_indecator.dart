import 'package:flutter/material.dart';

class BuildLoadingIndecator extends StatelessWidget {
  const BuildLoadingIndecator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.2),
      child: Center(
        child: Container(
            height: 100.0,
            width: 100.0,
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(25))),
            child: const Center(
              child: SizedBox(
                  height: 30.0,
                  width: 30.0,
                  child: CircularProgressIndicator(color: Colors.red)),
            )),
      ),
    );
  }
}
