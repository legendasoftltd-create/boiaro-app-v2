class BijoyConverter {
  // A standard SutonnyMJ to Unicode mapping (partial/core)
  static final Map<String, String> _bijoyMap = {
    // Vowels
    'A': 'অ', 'Av': 'আ', 'B': 'ই', 'C': 'ঈ', 'D': 'উ', 'E': 'ঊ', 'F': 'ঋ',
    'G': 'এ', 'H': 'ঐ', 'I': 'ও', 'J': 'ঔ',
    // Consonants
    'K': 'ক', 'L': 'খ', 'M': 'গ', 'N': 'ঘ', 'O': 'ঙ',
    'P': 'চ', 'Q': 'ছ', 'R': 'জ', 'S': 'ঝ', 'T': 'ঞ',
    'U': 'ট', 'V': 'ঠ', 'W': 'ড', 'X': 'ঢ', 'Y': 'ণ',
    'Z': 'ত', '_': 'থ', '`': 'দ', 'a': 'ধ', 'b': 'ন',
    'c': 'প', 'd': 'ফ', 'e': 'ব', 'f': 'ভ', 'g': 'ম',
    'h': 'য', 'i': 'র', 'j': 'ল', 'k': 'শ', 'l': 'ষ',
    'm': 'স', 'n': 'হ', 'o': 'ড়', 'p': 'ঢ়', 'q': 'য়',
    'r': 'ৎ', 's': 'ং', 't': 'ঃ', 'u': 'ঁ',
    // Vowel Signs
    'v': 'া', 'w': 'ি', 'x': 'ী', 'y': 'ু', 'z': 'ূ', '"': 'ৃ',
    '†': 'ে', '‡': 'ে', 'ˆ': 'ৈ', '†v': 'ো', '†Š': 'ৌ',
    // Numbers
    // Numbers
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪', '5': '৫', '6': '৬',
    '7': '৭', '8': '৮', '9': '৯',
    // Conjuncts/Others (simplified)
    '&': 'ক্ষ',
    // Add many more conjuncts ideally...
  };

  static String convert(String text, {bool preProcess = true}) {
    if (text.isEmpty) return text;
    print('BijoyConverter: Original: $text'); // Debug Log

    String converted = text;

    final preKars = ['w', '†', '‡', 'ˆ'];
    final chars = converted.split('');
    final length = chars.length;

    StringBuffer sb = StringBuffer();

    for (int i = 0; i < length; i++) {
      String c = chars[i];

      // Handle Pre-Kars
      if (preKars.contains(c)) {
        if (i + 1 < length) {
          String next = chars[i + 1];
          sb.write(_mapChar(next));
          sb.write(_mapChar(c));
          i++; // skip next since we moved it
          continue;
        }
      }

      sb.write(_mapChar(c));
    }

    String res = sb.toString();
    res = res.replaceAll('ো', 'ো');
    res = res.replaceAll('ৌ', 'ৌ');

    print('BijoyConverter: Converted: $res'); // Debug Log
    return res;
  }

  static String _mapChar(String c) {
    return _bijoyMap[c] ?? c;
  }

  // Simplified Unicode to Bijoy converter
  static String convertToBijoy(String text) {
    if (text.isEmpty) return text;

    // Simple character-by-character mapping for common cases
    // টাকা -> UvKv
    final Map<String, String> unicodeToBijoy = {
      'ট': 'U', 'া': 'v', 'ক': 'K',
      'ল': 'j', 'ে': '†', 'খ': 'L',
      'ম': 'g', 'ন': 'b', 'র': 'i',
      'স': 'm', 'হ': 'n', 'য': 'h',
      'প': 'c', 'ব': 'e', 'ত': 'Z',
      'দ': '`', 'ধ': 'a', 'ভ': 'f',
      'শ': 'k', 'ষ': 'l', 'জ': 'R',
      'চ': 'P', 'গ': 'M', 'ঠ': 'V',
      'ড': 'W', 'ঢ': 'X', 'ণ': 'Y',
      'থ': '_', 'ফ': 'd', 'ঘ': 'N',
      'ছ': 'Q', 'ঝ': 'S', 'ঞ': 'T',
      'ড়': 'o', 'ঢ়': 'p', 'য়': 'q',
      'ং': 's', 'ঃ': 't', 'ঁ': 'u',
      'ি': 'w', 'ী': 'x', 'ু': 'y', 'ূ': 'z',
      'ৃ': '"', 'ৈ': 'ˆ',
      // Independent vowels
      'অ': 'A', 'আ': 'Av', 'ই': 'B', 'ঈ': 'C',
      'উ': 'D', 'ঊ': 'E', 'ঋ': 'F',
      'এ': 'G', 'ঐ': 'H', 'ও': 'I', 'ঔ': 'J',
      // Numbers
      '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
      '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
    };

    StringBuffer result = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      String? bijoyChar = unicodeToBijoy[char];

      if (bijoyChar != null) {
        result.write(bijoyChar);
      } else {
        result.write(char); // Keep original if no mapping
      }
    }

    return result.toString();
  }
}
