import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;

void main() {
  runApp(const StegoApp());
}

// تبدیل ۳۲ کاراکتر Hex به ۱۲۸ بیت باینری
String hexToBinary(String hex) {
  final buffer = StringBuffer();
  for (int i = 0; i < hex.length; i++) {
    final intVal = int.parse(hex[i], radix: 16);
    buffer.write(intVal.toRadixString(2).padLeft(4, '0'));
  }
  return buffer.toString();
}

// تبدیل ۱۲۸ بیت باینری به ۳۲ کاراکتر Hex
String binaryToHex(String binary) {
  final buffer = StringBuffer();
  for (int i = 0; i < binary.length; i += 4) {
    if (i + 4 <= binary.length) {
      final chunk = binary.substring(i, i + 4);
      final intVal = int.parse(chunk, radix: 2);
      buffer.write(intVal.toRadixString(16));
    }
  }
  return buffer.toString();
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
                    'نهان سازی',
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
                    'آشکار سازی',
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
          title: const Text('نهان سازی'),
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
  // ورودی نمونه ۳۲ کاراکتری هگز (معادل ۱۲۸ بیت)
  final TextEditingController _hexController = TextEditingController(text: "");

  final TextEditingController _coverTextController = TextEditingController();
  String _stegoResult = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    // متن کاور طولانی که هر ۱۲۸ کلمه پایه (مقدار index 0 جفت‌ها) را یکبار دارد
    _coverTextController.text =
        "The quick student built a big project with a smart start. "
        "He felt happy, not sad, even when tasks were hard and not easy. "
        "In a small office, rich with ideas, silent workers were strong. "
        "A bright light in the dark made a cold day feel hot and correct. "
        "Nothing was wrong; they would help to stop failure and finish the job. "
        "They choose to buy tools rather than sell or keep old items. "
        "Before they leave or arrive, they think and show how to hide plans. "
        "They build without a wish to destroy, keeping clean from dirty methods. "
        "Brave men are not afraid, remaining calm when others get angry. "
        "A famous man found strange things that were cheap and not costly. "
        "A deep lesson avoids shallow thoughts on heavy or light objects. "
        "Across broad roads and narrow paths, smooth surfaces become rough. "
        "A sharp mind avoids dull ideas, keeping neat instead of messy. "
        "Be polite and never rude; stay safe in dangerous places. "
        "A giant tree makes meager plants look ancient and not modern. "
        "Do not touch fragile items unless sturdy hands protect them. "
        "An honest man hates fake promises and cruel laws, staying kind and loyal. "
        "An eager worker is never lazy or busy with rare tasks. "
        "When plentiful resources exist, vague ideas become vivid. "
        "A brief talk is better than a long one; swift action beats a slow response. "
        "A bold person is not timid, facing grim days with cheerful hope. "
        "A rigid rule becomes flexible when valid reasons show it is void. "
        "From a lofty tower, a humble view shows the prime choice. "
        "Do not eat stale bread when fresh food is grand and plain. "
        "A noble purpose avoids base thoughts; tough problems require tender care. "
        "A fickle mood distracts a wise person from foolish mistakes. "
        "Be sincere and shrewd, avoiding indistinct signs to stay lucid. "
        "A fierce wolf becomes tame; a slender frame grows plump. "
        "An exalted leader stays meek and perceptive to blind critics. "
        "A graphic image clears dim views; a stout man gets lean. "
        "A magnificent result stops stern judges from rejecting authentic items. "
        "A bogus claim ruins optimal results from crude materials. "
        "A solid frame supports feeble structures when enthusiastic members are bored.";
  }

  void _encode() {
    setState(() {
      _error = '';
      _stegoResult = '';
    });

    final hexInput = _hexController.text.trim();
    if (hexInput.length != 32 ||
        !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexInput)) {
      setState(
        () =>
            _error = 'لطفاً دقیقاً ۳۲ کاراکتر هگزادسیمال (0-9, a-f) وارد کنید.',
      );
      return;
    }

    try {
      final bits = hexToBinary(hexInput); // تبدیل ۳۲ هگز به ۱۲۸ بیت
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
            controller: _hexController,
            maxLength: 32,
            decoration: const InputDecoration(
              labelText: 'ورودی ۳۲ کاراکتری (معادل ۱۲۸ بیت)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _coverTextController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'متن کاور ',
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
                'خروجی :',
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
// IMAGE ENCODING TAB (با قابلیت انتخاب از بین ۵ تصویر پیش‌فرض)
// -----------------------------------------------------------------------------
class ImageEncodingTab extends StatefulWidget {
  const ImageEncodingTab({super.key});

  @override
  State<ImageEncodingTab> createState() => _ImageEncodingTabState();
}

class _ImageEncodingTabState extends State<ImageEncodingTab> {
  final TextEditingController _hexController = TextEditingController(text: "");

  // لیست ۵ تصویر پیش‌فرض در پوشه assets
  final List<String> _defaultImagePaths = [
    'assets/images/dog.png',
    'assets/images/morning.png',
    'assets/images/sun.png',
    'assets/images/cat.png',
    'assets/images/night.png',
  ];

  int _selectedImageIndex = 0; // تصویر اول به‌صورت پیش‌فرض انتخاب شده است
  Uint8List? _selectedImageBytes;
  Uint8List? _stegoImageBytes;
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadSelectedImage();
  }

  // بارگذاری تصویر انتخاب‌شده از assets
  Future<void> _loadSelectedImage() async {
    try {
      final path = _defaultImagePaths[_selectedImageIndex];
      final ByteData data = await rootBundle.load(path);
      setState(() {
        _selectedImageBytes = data.buffer.asUint8List();
        _stegoImageBytes = null; // پاکسازی خروجی قبلی در صورت تغییر تصویر
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'خطا در بارگذاری تصویر';
      });
    }
  }

  Future<void> _encode() async {
    final hexInput = _hexController.text.trim();
    if (hexInput.length != 32 ||
        !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexInput)) {
      setState(() => _error = 'لطفاً دقیقاً ۳۲ کاراکتر هگزادسیمال وارد کنید.');
      return;
    }
    if (_selectedImageBytes == null) {
      setState(() => _error = 'تصویری انتخاب نشده است.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final bits = hexToBinary(hexInput);
      final resultBytes = await DctStego.encode(
        imageBytes: _selectedImageBytes!,
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

  Future<void> _saveImageToGallery() async {
    if (_stegoImageBytes == null) return;
    try {
      await Gal.putImageBytes(_stegoImageBytes!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تصویر با موفقیت در گالری ذخیره شد!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره تصویر: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _hexController,
            maxLength: 32,
            decoration: const InputDecoration(
              labelText: 'ورودی ۳۲ کاراکتری',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'تصویر کاور را انتخاب کنید (از بین ۵ تصویر):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // لیست افقی برای انتخاب تصاویر
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _defaultImagePaths.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedImageIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                    _loadSelectedImage();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Colors.indigo
                            : Colors.grey.shade300,
                        width: isSelected ? 3.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        _defaultImagePaths[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // پیش‌نمایش تصویر انتخاب‌شده
          if (_selectedImageBytes != null)
            Center(child: Image.memory(_selectedImageBytes!, height: 140))
          else
            const Center(child: CircularProgressIndicator()),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _encode,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('انجام نهان سازی '),
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_error, style: const TextStyle(color: Colors.red)),
          ],
          if (_stegoImageBytes != null) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'تصویر حاصل:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Image.memory(_stegoImageBytes!, height: 160)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveImageToGallery,
                icon: const Icon(Icons.download),
                label: const Text('ذخیره تصویر در گالری'),
              ),
            ),
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

  String _decodedHexFromText = '';
  String _decodedHexFromImage = '';
  bool _isLoading = false;

  Future<void> _decodeText() async {
    final text = _stegoTextController.text;
    if (text.isEmpty) return;

    // استخراج ۱۲۸ بیت و تبدیل به ۳۲ کاراکتر Hex
    final bits = SemanticStego.decode(stegoText: text, bitLength: 128);
    final hexResult = binaryToHex(bits);

    setState(() {
      _decodedHexFromText = hexResult;
    });
  }

  Future<void> _pickAndDecodeImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _isLoading = true;
      });

      final bytes = await file.readAsBytes();
      // استخراج ۱۲۸ بیت و تبدیل به ۳۲ کاراکتر Hex
      final bits = await DctStego.decode(imageBytes: bytes, bitLength: 128);
      final hexResult = binaryToHex(bits);

      setState(() {
        _decodedHexFromImage = hexResult;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آشکارسازی')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'آشکار سازی از متن',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stegoTextController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'متن را وارد کنید ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _decodeText,
              child: const Text('آشکارسازی متن'),
            ),
            if (_decodedHexFromText.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                'مقداراستخراج‌شده (۳۲ کاراکتر):\n$_decodedHexFromText',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
            const Divider(height: 40),
            const Text(
              'آشکارسازی از تصویر',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndDecodeImage,
              icon: const Icon(Icons.image_search),
              label: const Text('انتخاب تصویر از گالری'),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            if (_decodedHexFromImage.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                'مقدار استخراج‌شده (۳۲ کاراکتر):\n$_decodedHexFromImage',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
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
  // ۱۲۸ جفت کلمه مترادف مجزا (موقعیت 0 برای بیت '0' و موقعیت 1 برای بیت '1')
  static const Map<String, List<String>> synonymDict = {
    "pair0": ["quick", "fast"],
    "pair1": ["big", "large"],
    "pair2": ["smart", "clever"],
    "pair3": ["start", "begin"],
    "pair4": ["happy", "joyful"],
    "pair5": ["sad", "unhappy"],
    "pair6": ["hard", "difficult"],
    "pair7": ["easy", "simple"],
    "pair8": ["small", "tiny"],
    "pair9": ["rich", "wealthy"],
    "pair10": ["silent", "quiet"],
    "pair11": ["strong", "powerful"],
    "pair12": ["bright", "radiant"],
    "pair13": ["dark", "gloomy"],
    "pair14": ["cold", "chilly"],
    "pair15": ["hot", "warm"],
    "pair16": ["correct", "right"],
    "pair17": ["wrong", "incorrect"],
    "pair18": ["help", "assist"],
    "pair19": ["stop", "halt"],
    "pair20": ["finish", "complete"],
    "pair21": ["choose", "select"],
    "pair22": ["buy", "purchase"],
    "pair23": ["sell", "trade"],
    "pair24": ["keep", "hold"],
    "pair25": ["leave", "depart"],
    "pair26": ["arrive", "reach"],
    "pair27": ["think", "believe"],
    "pair28": ["show", "display"],
    "pair29": ["hide", "conceal"],
    "pair30": ["build", "create"],
    "pair31": ["destroy", "ruin"],
    "pair32": ["clean", "pure"],
    "pair33": ["dirty", "filthy"],
    "pair34": ["brave", "courageous"],
    "pair35": ["afraid", "scared"],
    "pair36": ["calm", "peaceful"],
    "pair37": ["angry", "furious"],
    "pair38": ["famous", "renowned"],
    "pair39": ["strange", "odd"],
    "pair40": ["cheap", "inexpensive"],
    "pair41": ["costly", "expensive"],
    "pair42": ["deep", "profound"],
    "pair43": ["shallow", "superficial"],
    "pair44": ["heavy", "weighty"],
    "pair45": ["light", "featherlight"],
    "pair46": ["broad", "wide"],
    "pair47": ["narrow", "slender"],
    "pair48": ["smooth", "even"],
    "pair49": ["rough", "coarse"],
    "pair50": ["sharp", "keen"],
    "pair51": ["dull", "blunt"],
    "pair52": ["neat", "tidy"],
    "pair53": ["messy", "untidy"],
    "pair54": ["polite", "courteous"],
    "pair55": ["rude", "impolite"],
    "pair56": ["safe", "secure"],
    "pair57": ["dangerous", "risky"],
    "pair58": ["giant", "huge"],
    "pair59": ["meager", "paltry"],
    "pair60": ["ancient", "old"],
    "pair61": ["modern", "new"],
    "pair62": ["fragile", "delicate"],
    "pair63": ["sturdy", "robust"],
    "pair64": ["honest", "truthful"],
    "pair65": ["fake", "false"],
    "pair66": ["cruel", "harsh"],
    "pair67": ["kind", "gentle"],
    "pair68": ["loyal", "faithful"],
    "pair69": ["eager", "keen"],
    "pair70": ["lazy", "idle"],
    "pair71": ["busy", "occupied"],
    "pair72": ["rare", "scarce"],
    "pair73": ["plentiful", "abundant"],
    "pair74": ["vague", "unclear"],
    "pair75": ["vivid", "clear"],
    "pair76": ["brief", "short"],
    "pair77": ["long", "extended"],
    "pair78": ["swift", "rapid"],
    "pair79": ["slow", "sluggish"],
    "pair80": ["bold", "daring"],
    "pair81": ["timid", "shy"],
    "pair82": ["grim", "bleak"],
    "pair83": ["cheerful", "lively"],
    "pair84": ["rigid", "stiff"],
    "pair85": ["flexible", "pliant"],
    "pair86": ["valid", "legitimate"],
    "pair87": ["void", "invalid"],
    "pair88": ["lofty", "tall"],
    "pair89": ["humble", "modest"],
    "pair90": ["prime", "chief"],
    "pair91": ["stale", "musty"],
    "pair92": ["fresh", "crisp"],
    "pair93": ["grand", "splendid"],
    "pair94": ["plain", "simple"],
    "pair95": ["noble", "dignified"],
    "pair96": ["base", "vile"],
    "pair97": ["tough", "durable"],
    "pair98": ["tender", "soft"],
    "pair99": ["fickle", "unstable"],
    "pair100": ["wise", "sagacious"],
    "pair101": ["foolish", "silly"],
    "pair102": ["sincere", "genuine"],
    "pair103": ["shrewd", "astute"],
    "pair104": ["indistinct", "obscure"],
    "pair105": ["lucid", "transparent"],
    "pair106": ["fierce", "ferocious"],
    "pair107": ["tame", "gentle"],
    "pair108": ["slender", "slim"],
    "pair109": ["plump", "chubby"],
    "pair110": ["exalted", "elevated"],
    "pair111": ["meek", "submissive"],
    "pair112": ["perceptive", "insightful"],
    "pair113": ["blind", "unseeing"],
    "pair114": ["graphic", "explicit"],
    "pair115": ["dim", "faint"],
    "pair116": ["stout", "stocky"],
    "pair117": ["lean", "thin"],
    "pair118": ["magnificent", "glorious"],
    "pair119": ["stern", "strict"],
    "pair120": ["authentic", "real"],
    "pair121": ["bogus", "spurious"],
    "pair122": ["optimal", "ideal"],
    "pair123": ["crude", "raw"],
    "pair124": ["solid", "firm"],
    "pair125": ["feeble", "weak"],
    "pair126": ["enthusiastic", "keen"],
    "pair127": ["bored", "uninterested"],
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

  static String decode({required String stegoText, int bitLength = 128}) {
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
