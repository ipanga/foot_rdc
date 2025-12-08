String formatCategory(String category) {
  if (category.isEmpty) return '';

  const prefix = 'category-';
  String s = category;
  if (s.startsWith(prefix)) {
    s = s.substring(prefix.length);
  }

  s = s.replaceAll('-', ' ').trim();
  if (s.isEmpty) return '';

  return s[0].toUpperCase() + s.substring(1);
}

/// Decodes common HTML entities to their corresponding characters.
/// This is useful for displaying text that contains HTML entities
/// like &rsquo;, &lsquo;, &amp;, etc.
/// Handles double-encoded entities (e.g., &amp;rsquo; → &rsquo; → ')
String decodeHtmlEntities(String text) {
  if (text.isEmpty) return text;

  String result = text;

  // Run decoding multiple times to handle double-encoded entities
  // (e.g., &amp;rsquo; becomes &rsquo; after first pass, then ' after second)
  for (int i = 0; i < 3; i++) {
    final previousResult = result;
    result = _decodeHtmlEntitiesOnce(result);
    // Stop if no more changes
    if (result == previousResult) break;
  }

  return result;
}

String _decodeHtmlEntitiesOnce(String text) {
  // Map of common HTML entities to their character equivalents
  // Using straight apostrophe ' instead of curly quotes for better compatibility
  const htmlEntities = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&#39;': "'",
    '&rsquo;': "'",  // Right single quote → straight apostrophe
    '&lsquo;': "'",  // Left single quote → straight apostrophe
    '&rdquo;': '"',  // Right double quote → straight double quote
    '&ldquo;': '"',  // Left double quote → straight double quote
    '&ndash;': '–',
    '&mdash;': '—',
    '&hellip;': '…',
    '&copy;': '©',
    '&reg;': '®',
    '&trade;': '™',
    '&euro;': '€',
    '&pound;': '£',
    '&yen;': '¥',
    '&cent;': '¢',
    '&deg;': '°',
    '&plusmn;': '±',
    '&times;': '×',
    '&divide;': '÷',
    '&frac12;': '½',
    '&frac14;': '¼',
    '&frac34;': '¾',
    '&acute;': '´',
    '&cedil;': '¸',
    '&iexcl;': '¡',
    '&iquest;': '¿',
    '&laquo;': '«',
    '&raquo;': '»',
    '&sect;': '§',
    '&para;': '¶',
    '&bull;': '•',
    '&middot;': '·',
    '&prime;': '′',
    '&Prime;': '″',
    '&oline;': '‾',
    '&frasl;': '⁄',
  };

  String result = text;

  // Replace named entities
  htmlEntities.forEach((entity, char) {
    result = result.replaceAll(entity, char);
  });

  // Handle numeric entities (decimal) like &#39;
  result = result.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (match) {
      final code = int.tryParse(match.group(1) ?? '');
      if (code != null && code > 0 && code < 65536) {
        return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    },
  );

  // Handle numeric entities (hexadecimal) like &#x27;
  result = result.replaceAllMapped(
    RegExp(r'&#x([0-9a-fA-F]+);'),
    (match) {
      final code = int.tryParse(match.group(1) ?? '', radix: 16);
      if (code != null && code > 0 && code < 65536) {
        return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    },
  );

  return result;
}
