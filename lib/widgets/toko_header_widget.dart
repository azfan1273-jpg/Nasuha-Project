import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';

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
	  final currentUser = Supabase.instance.client.auth.currentUser;
	  final String emailUser = currentUser?.email ?? 'owner@lndr.com';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         // KIRI: icon 7 detail toko
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          userRole.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    emailToko,
                    style: TextStyle(color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ], // <-- Menutup children dari Column
            ),
          ], // <-- Menutup children dari Row Kiri
        ),
           
          // KANAN: TOMBOL REFRESH & LOGOUT        
          Row(
           children: [ // <-- Menambahkan children: [] yang sempat terlewat 
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: _textBlack),
                onPressed: onRefresh,
           		),       
	          ],
           	),
		  ],
		),
      );
    }
  }
	    	

