import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/settings_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatType; // 'owner_kasir' atau 'kasir_kasir'
  final String title;

  const ChatScreen({super.key, required this.chatType, required this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  // Fungsi Kirim Pesan
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
  
    try {
      final user = supabase.auth.currentUser;
      final storeId = context.read<SettingsProvider>().storeId;
  
      // 🟢 Cek apakah user atau storeId kosong (ini sering jadi penyebab senyap)
      debugPrint('DEBUG KIRIM CHAT -> UserID: ${user?.id}, StoreID: $storeId, Text: $text');
  
      if (user == null || storeId == null || storeId.isEmpty) {
        debugPrint('GAGAL KIRIM: User atau StoreID tidak valid!');
        return;
      }
  
      // Kosongkan teks dulu agar responsif di UI
      _messageController.clear();
  
      // Kirim ke database Supabase
      await supabase.from('chats').insert({
        'store_id': storeId,
        'sender_id': user.id,
        'chat_type': widget.chatType,
        'message': text,
      });
  
      debugPrint('BERHASIL KIRIM CHAT!');
  
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      // 🟢 Tangkap error aslinya agar tampil di log terminal Termux/konsol browser
      debugPrint('ERROR KIRIM PESAN EXCEPTION: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currentUserId = supabase.auth.currentUser?.id;
    final storeId = context.read<SettingsProvider>().storeId;

    return Scaffold(
      backgroundColor: settings.bgDark,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // LIST PESAN REALTIME DARI SUPABASE
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: supabase
                    .from('chats')
                    .stream(primaryKey: ['id'])
                    .eq('chat_type', widget.chatType)
                    .eq('store_id', storeId ?? '')
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                // 🟢 Jika masih error dari server, tampilkan pesan errornya
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  );
                }
             
                // 🟢 Ambil data, jika belum ada data sama sekali baru tampilkan loading mutar
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
              
                final messages = snapshot.data!;
              
                // 🟢 Jika data kosong, langsung tampilkan teks kosong tanpa muter-muter lagi
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada gosip hari ini. Mulai percakapan rahasia! 🤫',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['sender_id'] == currentUserId;
            
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? settings.accentColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['message'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white : settings.textColor,
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ),

            // INPUT CHAT DI BAWAH
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: widget.chatType == 'kasir_kasir' 
                            ? 'Ketik pesan rahasia kasir...' 
                            : 'Ketik pesan ke owner...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: settings.accentColor,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
