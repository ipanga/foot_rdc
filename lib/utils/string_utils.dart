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
