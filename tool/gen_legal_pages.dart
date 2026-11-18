// Generates the static GitHub Pages site in /docs from the in-app legal text.
//
//   dart run tool/gen_legal_pages.dart
//
// Edit text in lib/features/legal/legal_content.dart, re-run, commit, push.
import 'dart:io';

import 'package:near_pro1/features/legal/legal_content.dart';

String esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

const css = '''
body{font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;line-height:1.6;color:#1b2a21;background:#f4f8f5;margin:0}
header{background:#1d3b27;color:#fff;padding:28px 20px}
header h1{margin:0;font-size:26px;max-width:760px;margin:0 auto}
main{max-width:760px;margin:0 auto;padding:24px 20px 60px;background:#fff}
h2{color:#1d3b27;margin-top:32px;font-size:19px}
li{margin:6px 0}
nav{margin-bottom:18px}
nav a{margin-right:14px;color:#38804f}
footer{max-width:760px;margin:0 auto;padding:20px;font-size:13px;color:#555}
''';

const nav = '<nav><a href="index.html">Home</a>'
    '<a href="privacy-policy.html">Privacy Policy</a>'
    '<a href="terms.html">Terms of Service</a>'
    '<a href="delete-account.html">Delete Account</a></nav>';

String page(String title, String body) => '''<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)} - ProNear</title><style>$css</style></head>
<body><header><h1>ProNear - ${esc(title)}</h1></header>
<main>$nav
$body
</main><footer>&copy; ProNear &middot; Contact: ${esc(kSupportEmail)}</footer></body></html>
''';

String render(LegalDocument d) {
  final b = StringBuffer('<p>${esc(d.intro)}</p>\n');
  for (final s in d.sections) {
    if (s.heading.isNotEmpty) b.writeln('<h2>${esc(s.heading)}</h2>');
    for (final p in s.paragraphs) {
      b.writeln('<p>${esc(p)}</p>');
    }
    if (s.bullets.isNotEmpty) {
      b.writeln('<ul>');
      for (final x in s.bullets) {
        b.writeln('<li>${esc(x)}</li>');
      }
      b.writeln('</ul>');
    }
  }
  return b.toString();
}

void main() {
  Directory('docs').createSync(recursive: true);
  final files = {
    'privacy-policy.html': privacyPolicy,
    'terms.html': termsOfService,
    'delete-account.html': accountDeletion,
  };
  files.forEach((name, doc) {
    File('docs/$name').writeAsStringSync(page(doc.title, render(doc)));
    stdout.writeln('wrote docs/$name');
  });

  File('docs/index.html').writeAsStringSync(page('Find trusted service providers near you', '''
<ul>
<li><a href="privacy-policy.html">Privacy Policy</a></li>
<li><a href="terms.html">Terms of Service</a></li>
<li><a href="delete-account.html">Delete your account</a></li>
</ul>
<p>Support: ${esc(kSupportEmail)}</p>'''));
  stdout.writeln('wrote docs/index.html');
}
