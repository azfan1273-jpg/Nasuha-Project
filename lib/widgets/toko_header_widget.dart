import 'package:flutter/material.dart';

class TokoHeaderWidget extends StatelessWidget {
  final String namaToko;
  final String userRole;
  final String emailToko;
  final bool isLoading;
  final VoidCallback onRefresh;

  const TokoHeaderWidget({
    super.key,
    required this.namaToko,
    required this.userRole,
    required this.emailToko,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE7F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_rounded, color: Color(0xFFEC4899), size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      namaToko,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        userRole,
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Text(
                  emailToko,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEC4899)),
                )
              : const Icon(Icons.refresh, color: Color(0xFF111827), size: 18),
          onPressed: onRefresh,
        ),
      ],
    );
  }
}
