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

  static const Color _cardDark = Color(0xFFFCE7F3);
  static const Color _goldAccent = Color(0xFFEC4899);
  static const Color _textBlack = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _cardDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: _goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        namaToko,
                        style: const TextStyle(
                          color: _textBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _goldAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          userRole,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    emailToko,
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _goldAccent,
                    ),
                  )
                : const Icon(Icons.refresh, color: _textBlack, size: 18),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
