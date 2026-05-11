import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _brailleController = TextEditingController();
  String _textResult = '';
  String _brailleResult = '';

  // Braille mapping (Grade 1 - letter by letter)
  static const Map<String, String> _textToBraille = {
    'a': '⠁', 'b': '⠃', 'c': '⠉', 'd': '⠙', 'e': '⠑',
    'f': '⠋', 'g': '⠛', 'h': '⠓', 'i': '⠊', 'j': '⠚',
    'k': '⠅', 'l': '⠇', 'm': '⠍', 'n': '⠝', 'o': '⠕',
    'p': '⠏', 'q': '⠟', 'r': '⠗', 's': '⠎', 't': '⠞',
    'u': '⠥', 'v': '⠧', 'w': '⠺', 'x': '⠭', 'y': '⠽',
    'z': '⠵', ' ': '⠀', ',': '⠂', '.': '⠲', '?': '⠦',
    '!': '⠖', ';': '⠆', ':': '⠒', '-': '⠤',
    '0': '⠴', '1': '⠂', '2': '⠆', '3': '⠒', '4': '⠲',
    '5': '⠢', '6': '⠖', '7': '⠶', '8': '⠦', '9': '⠔',
  };

  static final Map<String, String> _brailleToText = {
    for (var entry in _textToBraille.entries) entry.value: entry.key,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _brailleController.dispose();
    super.dispose();
  }

  String _convertTextToBraille(String text) {
    return text
        .toLowerCase()
        .split('')
        .map((char) => _textToBraille[char] ?? char)
        .join('');
  }

  String _convertBrailleToText(String braille) {
    // Split by Braille characters (each is one Unicode character)
    final result = braille.split('').map((char) {
      return _brailleToText[char] ?? char;
    }).join('');
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Convertisseur Braille',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5B6BE8),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF5B6BE8),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Texte → Braille'),
            Tab(text: 'Braille → Texte'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTextToBraille(),
          _buildBrailleToText(),
        ],
      ),
    );
  }

  Widget _buildTextToBraille() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF5B6BE8).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF5B6BE8).withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF5B6BE8), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saisissez votre texte pour le convertir instantanément en Braille Grade 1.',
                    style: TextStyle(color: Color(0xFF5B6BE8), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Entrez votre texte',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              controller: _textController,
              maxLines: 5,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                hintText: 'Tapez votre texte ici...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _textController.clear();
                    setState(() => _brailleResult = '');
                  },
                )
                    : null,
              ),
              onChanged: (text) {
                setState(() {
                  _brailleResult = _convertTextToBraille(text);
                });
              },
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _brailleResult = _convertTextToBraille(_textController.text);
                });
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text(
                'Convertir en Braille',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B6BE8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          if (_brailleResult.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Résultat Braille',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _brailleResult));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copié dans le presse-papiers !'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16, color: Color(0xFF5B6BE8)),
                  label: const Text(
                    'Copier',
                    style: TextStyle(color: Color(0xFF5B6BE8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF5B6BE8).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SelectableText(
                _brailleResult,
                style: const TextStyle(
                  fontSize: 28,
                  letterSpacing: 4,
                  color: Color(0xFF5B6BE8),
                  fontFamily: 'monospace',
                ),
              ),
            ),

            // Letter-by-letter breakdown
            const SizedBox(height: 20),
            const Text(
              'Correspondances lettre par lettre',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _textController.text.toLowerCase().split('').map((char) {
                final braille = _textToBraille[char] ?? char;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B6BE8).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF5B6BE8).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        char == ' ' ? '⎵' : char.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        braille,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF5B6BE8),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBrailleToText() {
    final quickLetters = _textToBraille.entries
        .where((e) => RegExp(r'^[a-z]$').hasMatch(e.key))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF4CAF50), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Collez des caractères Braille Unicode pour les convertir en texte lisible.',
                    style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Entrez les caractères Braille',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              controller: _brailleController,
              maxLines: 5,
              style: const TextStyle(
                fontSize: 28,
                color: Color(0xFF5B6BE8),
                letterSpacing: 3,
              ),
              decoration: InputDecoration(
                hintText: '⠓⠑⠇⠇⠕...',
                hintStyle: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 28,
                  letterSpacing: 3,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (text) {
                setState(() {
                  _textResult = _convertBrailleToText(text);
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // Quick Braille keyboard
          const Text(
            'Clavier Braille rapide',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickLetters
                .map((entry) => GestureDetector(
              onTap: () {
                final current = _brailleController.text;
                _brailleController.text = current + entry.value;
                setState(() {
                  _textResult = _convertBrailleToText(_brailleController.text);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B6BE8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF5B6BE8).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF5B6BE8),
                      ),
                    ),
                    Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ))
                .toList(),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _textResult = _convertBrailleToText(_brailleController.text);
                });
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text(
                'Convertir en texte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          if (_textResult.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Texte converti',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _textResult));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copié !')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16, color: Color(0xFF4CAF50)),
                  label: const Text(
                    'Copier',
                    style: TextStyle(color: Color(0xFF4CAF50)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: SelectableText(
                _textResult.toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
