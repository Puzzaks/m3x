/// Preprocesses raw GitHub Markdown content to properly format HTML tags
/// (such as <div align="center">, <h1>..</h1>, <br>, <img>, <a>) commonly found
/// in GitHub repository READMEs and issue descriptions.
String preprocessGitHubMarkdown(String raw) {
  var md = raw;

  // 1. Remove HTML comments
  md = md.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

  // 2. Convert HTML headers
  md = md.replaceAllMapped(
    RegExp(r'<h1[^>]*>([\s\S]*?)<\/h1>', caseSensitive: false),
    (m) => '\n\n# ${m.group(1)?.trim()}\n\n',
  );
  md = md.replaceAllMapped(
    RegExp(r'<h2[^>]*>([\s\S]*?)<\/h2>', caseSensitive: false),
    (m) => '\n\n## ${m.group(1)?.trim()}\n\n',
  );
  md = md.replaceAllMapped(
    RegExp(r'<h3[^>]*>([\s\S]*?)<\/h3>', caseSensitive: false),
    (m) => '\n\n### ${m.group(1)?.trim()}\n\n',
  );
  md = md.replaceAllMapped(
    RegExp(r'<h4[^>]*>([\s\S]*?)<\/h4>', caseSensitive: false),
    (m) => '\n\n#### ${m.group(1)?.trim()}\n\n',
  );

  // 3. Convert line breaks
  md = md.replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n\n');

  // 4. Convert linked badges/images: <a href="url"><img src="imgUrl" alt="alt"></a>
  md = md.replaceAllMapped(
    RegExp(
      r'<a\s+href="([^"]+)"[^>]*>\s*<img\s+src="([^"]+)"[^>]*alt="([^"]*)"[^>]*>\s*<\/a>',
      caseSensitive: false,
    ),
    (m) => ' [![${m.group(3) ?? ""}](${m.group(2)})](${m.group(1)}) ',
  );

  // 5. Convert standalone images: <img src="url" alt="alt">
  md = md.replaceAllMapped(
    RegExp(
      r'<img\s+[^>]*src="([^"]+)"[^>]*alt="([^"]*)"[^>]*>',
      caseSensitive: false,
    ),
    (m) => '\n\n![${m.group(2) ?? ""}](${m.group(1)})\n\n',
  );

  // 6. Convert standalone images without alt
  md = md.replaceAllMapped(
    RegExp(r'<img\s+[^>]*src="([^"]+)"[^>]*>', caseSensitive: false),
    (m) => '\n\n![](${m.group(1)})\n\n',
  );

  // 7. Strip container tags keeping content
  md = md.replaceAll(RegExp(r'<\/?(?:div|p|center|span)[^>]*>', caseSensitive: false), '\n');

  // 8. Replace common HTML entities
  md = md
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');

  // 9. Normalize excessive newlines
  md = md.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return md.trim();
}
