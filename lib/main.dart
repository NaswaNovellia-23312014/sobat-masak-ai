import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  runApp(const SobatMasakProApp());
}

class SobatMasakProApp extends StatelessWidget {
  const SobatMasakProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chef AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          secondary: Colors.orange,
        ),
        useMaterial3: true,
      ),
      home: const ChatChefScreen(),
    );
  }
}

class ChatChefScreen extends StatefulWidget {
  const ChatChefScreen({super.key});

  @override
  State<ChatChefScreen> createState() => _ChatChefScreenState();
}

class _ChatChefScreenState extends State<ChatChefScreen> {
  // API Key ini sengaja saya biarkan tertulis di sini (hardcode) agar
  // bisa langsung menjalankan aplikasi ini tanpa perlu repot
  // membuat atau memasukkan API Key baru.
  static const String _apiKey = 'AIzaSyD4gbdFKAW9O8rITgmEJ5abhOGhc6IadMo';

  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

    _chatSession = _model.startChat(
      history: [
        Content.text(
          'Kamu adalah Chef profesional bernama "Sobat Masak". '
          'Kamu ramah, pintar masak, dan hemat. '
          'Tugasmu menjawab pertanyaan seputar resep, tips dapur, dan ide makanan. '
          'Gunakan format yang rapi (bold, list) dalam Bahasa Indonesia.',
        ),
      ],
    );
  }

  Future<void> _kirimPesan() async {
    final text = _textController.text;
    if (text.isEmpty) return;

    // 1. Tampilkan pesan user di layar
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      // 2. Kirim ke Gemini
      final response = await _chatSession.sendMessage(Content.text(text));
      final textResponse =
          response.text ?? 'Maaf, saya sedang bingung resepnya.';

      // 3. Tampilkan balasan AI di layar
      setState(() {
        _messages.add(ChatMessage(text: textResponse, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Gagal terhubung. Pastikan API Key benar dan internet lancar.\nError: $e',
            isUser: false,
            isError: true,
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.soup_kitchen, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Sobat Masak',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Hapus Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Area Chat List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 100,
                            color: Colors.teal.withOpacity(0.3),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Halo! Mau masak apa hari ini?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Coba tanya:\n"Resep nasi goreng abang-abang"\n"Tips agar daging empuk"',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(message: _messages[index]);
                    },
                  ),
          ),

          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(
                color: Colors.orange,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),

          // Area Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ketik bahan atau pertanyaan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _kirimPesan(),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _kirimPesan,
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({required this.text, required this.isUser, this.isError = false});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: message.isError
              ? Colors.red.shade50
              : message.isUser
              ? Colors.teal.shade100
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 5),
            bottomRight: Radius.circular(message.isUser ? 5 : 20),
          ),
          boxShadow: [
            if (!message.isUser)
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
          ],
          border: message.isUser
              ? null
              : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              const Text(
                '👨‍🍳 Chef AI',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
            // Menggunakan MarkdownBody agar teks tebal & list terlihat rapi
            message.isUser
                ? Text(message.text, style: const TextStyle(fontSize: 15))
                : MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 15, height: 1.5),
                      strong: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
