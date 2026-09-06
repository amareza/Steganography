import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;

void main() {
  runApp(const StegoApp());
}

class StegoApp extends StatelessWidget {
  const StegoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Steganography DCT & Semantic',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('انتخاب عملیات')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EncodingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock),
                  label: const Text(
                    'Encoding (کدگذاری)',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DecodingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_open),
                  label: const Text(
                    'Decoding (رمزگشایی)',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EncodingScreen extends StatelessWidget {
  const EncodingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Encoding'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.text_fields), text: 'Text'),
              Tab(icon: Icon(Icons.image), text: 'Image'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [TextEncodingTab(), ImageEncodingTab()],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TEXT ENCODING TAB
// -----------------------------------------------------------------------------
class TextEncodingTab extends StatefulWidget {
  const TextEncodingTab({super.key});

  @override
  State<TextEncodingTab> createState() => _TextEncodingTabState();
}

class _TextEncodingTabState extends State<TextEncodingTab> {
  final TextEditingController _bitsController = TextEditingController(
    text:
        "101101001011010010110100101101001011010010110100"
        "101101001011010010110100101101001011010010110100"
        "101101001011010101100010",
  );

  final TextEditingController _coverTextController = TextEditingController();
  String _stegoResult = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    const baseSentences = [
      "The quick student was happy to start the smart project.",
      "He decided to walk to the small house near the big park.",
      "The good teacher asked him to look at the hard job carefully.",
      "Although the weather was cold, the team continued their work.",
      "They wanted to help the group and buy useful tools.",
      "At the end of the day everyone was happy with the result.",
      "The smart manager gave a good response to the quick progress.",
      "The small office became busy as people started to speak loudly.",
      "Even after the hard meeting they continued to walk calmly.",
      "The good engineer tried to help every new student.",
    ];
    _coverTextController.text = List.generate(
      20,
      (_) => baseSentences.join(" "),
    ).join(" ");
  }

  void _encode() {
    setState(() {
      _error = '';
      _stegoResult = '';
    });

    final bits = _bitsController.text.trim();
    if (bits.length != 120 || !RegExp(r'^[01]+$').hasMatch(bits)) {
      setState(() => _error = 'لطفاً دقیقاً ۱۲۰ بیت (۰ و ۱) وارد کنید.');
      return;
    }

    try {
      final result = SemanticStego.encode(
        text: _coverTextController.text,
        bits: bits,
      );
      setState(() => _stegoResult = result);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _bitsController,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'رشته ۱۲۰ بیتی (0 و 1)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _coverTextController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'متن کاور (Cover Text)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _encode,
            child: const Text('انجام استگانوگرافی متن'),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_error, style: const TextStyle(color: Colors.red)),
          ],
          if (_stegoResult.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'خروجی Stego Text:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _stegoResult,
                  showCursor: true,
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: editableTextState.contextMenuButtonItems,
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// IMAGE ENCODING TAB (با تصویر از پیش تعیین‌شده)
// -----------------------------------------------------------------------------
class ImageEncodingTab extends StatefulWidget {
  const ImageEncodingTab({super.key});

  @override
  State<ImageEncodingTab> createState() => _ImageEncodingTabState();
}

class _ImageEncodingTabState extends State<ImageEncodingTab> {
  final TextEditingController _bitsController = TextEditingController(
    text:
        "101101001011010010110100101101001011010010110100"
        "101101001011010010110100101101001011010010110100"
        "101101001011010101100010",
  );

  Uint8List? _defaultImageBytes;
  Uint8List? _stegoImageBytes;
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDefaultImage();
  }

  // بارگذاری تصویر پیش‌فرض از پوشه assets
  Future<void> _loadDefaultImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/dog.png');
      setState(() {
        _defaultImageBytes = data.buffer.asUint8List();
      });
    } catch (e) {
      setState(() {
        _error = 'خطا در بارگذاری تصویر پیش‌فرض: مسیر assets را بررسی کنید.';
      });
    }
  }

  Future<void> _encode() async {
    final bits = _bitsController.text.trim();
    if (bits.length != 120 || !RegExp(r'^[01]+$').hasMatch(bits)) {
      setState(() => _error = 'لطفاً دقیقاً ۱۲۰ بیت (۰ و ۱) وارد کنید.');
      return;
    }
    if (_defaultImageBytes == null) {
      setState(() => _error = 'تصویر پیش‌فرض بارگذاری نشده است.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final resultBytes = await DctStego.encode(
        imageBytes: _defaultImageBytes!,
        bits: bits,
      );
      setState(() {
        _stegoImageBytes = resultBytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _bitsController,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'رشته ۱۲۰ بیتی (0 و 1)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'تصویر کاور پیش‌فرض:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          if (_defaultImageBytes != null)
            Image.memory(_defaultImageBytes!, height: 150)
          else
            const CircularProgressIndicator(),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _encode,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('انجام استگانوگرافی DCT'),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_error, style: const TextStyle(color: Colors.red)),
          ],
          if (_stegoImageBytes != null) ...[
            const SizedBox(height: 16),
            const Text(
              'تصویر Stego حاصل:',
              // style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Image.memory(_stegoImageBytes!, height: 180),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DECODING SCREEN
// -----------------------------------------------------------------------------
class DecodingScreen extends StatefulWidget {
  const DecodingScreen({super.key});

  @override
  State<DecodingScreen> createState() => _DecodingScreenState();
}

class _DecodingScreenState extends State<DecodingScreen> {
  final TextEditingController _stegoTextController = TextEditingController();
  File? _stegoImageFile;

  String _decodedBitsFromText = '';
  String _decodedBitsFromImage = '';
  bool _isLoading = false;

  Future<void> _decodeText() async {
    final text = _stegoTextController.text;
    if (text.isEmpty) return;
    final bits = SemanticStego.decode(stegoText: text);
    setState(() {
      _decodedBitsFromText = bits;
    });
  }

  Future<void> _pickAndDecodeImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _stegoImageFile = File(file.path);
        _isLoading = true;
      });

      final bytes = await _stegoImageFile!.readAsBytes();
      final bits = await DctStego.decode(imageBytes: bytes);

      setState(() {
        _decodedBitsFromImage = bits;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decoding (رمزگشایی)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'رمزگشایی از متن (Semantic)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stegoTextController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'متن Stego را وارد کنید',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _decodeText,
              child: const Text('رمزگشایی متن'),
            ),
            if (_decodedBitsFromText.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                'بیت‌های استخراج‌شده متن (${_decodedBitsFromText.length} بیت):\n$_decodedBitsFromText',
              ),
            ],
            const Divider(height: 40),
            const Text(
              'رمزگشایی از تصویر (DCT)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndDecodeImage,
              icon: const Icon(Icons.image_search),
              label: const Text('انتخاب تصویر Stego از گالری'),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            if (_decodedBitsFromImage.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                'بیت‌های استخراج‌شده تصویر (${_decodedBitsFromImage.length} بیت):\n$_decodedBitsFromImage',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// LOGIC 1: SEMANTIC STEGANOGRAPHY
// =============================================================================
class SemanticStego {
  static const Map<String, List<String>> synonymDict = {
    "quick": ["quick", "fast"],
    "small": ["small", "tiny"],
    "smart": ["smart", "clever"],
    "happy": ["happy", "glad"],
    "big": ["big", "large"],
    "start": ["start", "begin"],
    "end": ["end", "finish"],
    "look": ["look", "see"],
    "speak": ["speak", "talk"],
    "walk": ["walk", "stroll"],
    "cold": ["cold", "chilly"],
    "good": ["good", "nice"],
    "hard": ["hard", "difficult"],
    "job": ["job", "task"],
    "house": ["house", "home"],
    "buy": ["buy", "purchase"],
    "help": ["help", "assist"],
  };

  static String encode({required String text, required String bits}) {
    final words = text.split(RegExp(r'\s+'));
    final positions = <MapEntry<int, String>>[];

    for (int i = 0; i < words.length; i++) {
      final clean = words[i].replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
      for (final entry in synonymDict.entries) {
        if (clean == entry.value[0] || clean == entry.value[1]) {
          positions.add(MapEntry(i, entry.key));
          break;
        }
      }
    }

    if (bits.length > positions.length) {
      throw Exception(
        'نیاز به ${bits.length} موقعیت جایگزینی است اما فقط ${positions.length} موقعیت پیدا شد.',
      );
    }

    for (int bitIndex = 0; bitIndex < bits.length; bitIndex++) {
      final pos = positions[bitIndex].key;
      final key = positions[bitIndex].value;
      final bitVal = int.parse(bits[bitIndex]);

      final pair = synonymDict[key]!;
      String replacement = pair[bitVal];
      final original = words[pos];

      String punctuation = '';
      if (RegExp(r'[.,!?;:]$').hasMatch(original)) {
        punctuation = original[original.length - 1];
      }

      if (original.isNotEmpty && original[0] == original[0].toUpperCase()) {
        replacement = replacement[0].toUpperCase() + replacement.substring(1);
      }

      words[pos] = replacement + punctuation;
    }

    return words.join(' ');
  }

  static String decode({required String stegoText, int bitLength = 120}) {
    final words = stegoText.split(RegExp(r'\s+'));
    final recovered = StringBuffer();

    for (final word in words) {
      final clean = word.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
      for (final entry in synonymDict.entries) {
        if (clean == entry.value[0]) {
          recovered.write('0');
          break;
        } else if (clean == entry.value[1]) {
          recovered.write('1');
          break;
        }
      }
      if (recovered.length >= bitLength) break;
    }

    final str = recovered.toString();
    return str.length > bitLength ? str.substring(0, bitLength) : str;
  }
}

// =============================================================================
// LOGIC 2: DCT STEGANOGRAPHY
// =============================================================================
class DctStego {
  static const double margin = 200.0;

  static Future<Uint8List> encode({
    required Uint8List imageBytes,
    required String bits,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception("امکان خواندن تصویر وجود ندارد.");

    final width = image.width;
    final height = image.height;

    // استخراج ماتریس کانال Blue (مشابه opencv img[:, :, 0])
    final blueMatrix = List.generate(
      height,
      (y) => List.generate(width, (x) => image.getPixel(x, y).b.toDouble()),
    );

    int bitIndex = 0;

    for (int i = 0; i <= height - 8; i += 8) {
      for (int j = 0; j <= width - 8; j += 8) {
        if (bitIndex >= bits.length) break;

        // بلاک 8x8
        final block = List.generate(
          8,
          (r) => List.generate(8, (c) => blueMatrix[i + r][j + c]),
        );
        final dctBlock = _applyDCT(block);

        double c1 = dctBlock[5][2];
        double c2 = dctBlock[2][5];

        final bit = bits[bitIndex];
        final temp = math.max(c1, c2);

        if (bit == '1') {
          c1 = temp + margin;
          c2 = temp - margin;
        } else {
          c2 = temp + margin;
          c1 = temp - margin;
        }

        dctBlock[5][2] = c1;
        dctBlock[2][5] = c2;

        final idctBlock = _applyIDCT(dctBlock);

        for (int r = 0; r < 8; r++) {
          for (int c = 0; c < 8; c++) {
            blueMatrix[i + r][j + c] = idctBlock[r][c].roundToDouble();
          }
        }

        bitIndex++;
      }
      if (bitIndex >= bits.length) break;
    }

    // اعمال کانال B تغییر یافته روی تصویر خروجی
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final newB = blueMatrix[y][x].clamp(0, 255).toInt();
        image.setPixel(
          x,
          y,
          img.ColorInt32.rgba(
            pixel.r.toInt(),
            pixel.g.toInt(),
            newB,
            pixel.a.toInt(),
          ),
        );
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  static Future<String> decode({
    required Uint8List imageBytes,
    int bitLength = 120,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception("امکان خواندن تصویر وجود ندارد.");

    final width = image.width;
    final height = image.height;

    final blueMatrix = List.generate(
      height,
      (y) => List.generate(width, (x) => image.getPixel(x, y).b.toDouble()),
    );

    final recoveredBits = StringBuffer();
    int count = 0;

    for (int i = 0; i <= height - 8; i += 8) {
      for (int j = 0; j <= width - 8; j += 8) {
        if (count >= bitLength) break;

        final block = List.generate(
          8,
          (r) => List.generate(8, (c) => blueMatrix[i + r][j + c]),
        );
        final dctBlock = _applyDCT(block);

        final c1 = dctBlock[5][2];
        final c2 = dctBlock[2][5];

        if (c1 > c2) {
          recoveredBits.write('1');
        } else {
          recoveredBits.write('0');
        }

        count++;
      }
      if (count >= bitLength) break;
    }

    return recoveredBits.toString();
  }

  // 2D DCT-II implementation for 8x8 block
  static List<List<double>> _applyDCT(List<List<double>> block) {
    final dct = List.generate(8, (_) => List.filled(8, 0.0));
    for (int u = 0; u < 8; u++) {
      for (int v = 0; v < 8; v++) {
        double sum = 0.0;
        final cu = (u == 0) ? 1 / math.sqrt(2) : 1.0;
        final cv = (v == 0) ? 1 / math.sqrt(2) : 1.0;

        for (int x = 0; x < 8; x++) {
          for (int y = 0; y < 8; y++) {
            sum +=
                block[x][y] *
                math.cos((2 * x + 1) * u * math.pi / 16) *
                math.cos((2 * y + 1) * v * math.pi / 16);
          }
        }
        dct[u][v] = 0.25 * cu * cv * sum;
      }
    }
    return dct;
  }

  // 2D IDCT-III implementation for 8x8 block
  static List<List<double>> _applyIDCT(List<List<double>> dct) {
    final block = List.generate(8, (_) => List.filled(8, 0.0));
    for (int x = 0; x < 8; x++) {
      for (int y = 0; y < 8; y++) {
        double sum = 0.0;
        for (int u = 0; u < 8; u++) {
          for (int v = 0; v < 8; v++) {
            final cu = (u == 0) ? 1 / math.sqrt(2) : 1.0;
            final cv = (v == 0) ? 1 / math.sqrt(2) : 1.0;
            sum +=
                cu *
                cv *
                dct[u][v] *
                math.cos((2 * x + 1) * u * math.pi / 16) *
                math.cos((2 * y + 1) * v * math.pi / 16);
          }
        }
        block[x][y] = 0.25 * sum;
      }
    }
    return block;
  }
}
