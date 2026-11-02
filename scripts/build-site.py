from pathlib import Path
import os
from urllib.parse import urlparse

root = Path(__file__).resolve().parent.parent
site = root / 'docs'
(site / 'en').mkdir(exist_ok=True)
base = os.environ.get('CLIPCOPY_SITE_URL', 'https://clipcopy.pages.dev/').rstrip('/') + '/'
prefix = urlparse(base).path
repo = 'https://github.com/MediaPublishing/clipcopy-app'
download = repo + '/releases/download/v0.1.1/ClipCopy-0.1.1-arm64.zip'
translations = {
    'de': {
        'title': 'ClipCopy für Mac: Kopiertes wiederfinden',
        'description': 'Kopierte Texte aus der Menüleiste wiederverwenden. ClipCopy speichert deinen Verlauf lokal verschlüsselt. Kostenlose Beta für Apple Silicon.',
        'skip': 'Zum Inhalt', 'nav': ['So funktioniert’s', 'Lokaler Verlauf', 'Fragen'],
        'kicker': 'Ein kleines Werkzeug für deinen Mac',
        'headline': 'Schon kopiert.<br>Wieder zur Hand.',
        'lead': 'Links, Textstellen, kurze Notizen: ClipCopy hält kopierte Texte in deiner Menüleiste bereit. Wähle einen Eintrag und füge ihn mit Cmd+V wieder ein.',
        'download': 'Beta für Mac herunterladen', 'source': 'Quellcode ansehen',
        'caption': 'Die ClipCopy-Einstellungen mit künstlichen Beispieldaten. Native macOS-Bedienelemente, kein neues Fenster für jede Kopie.',
        'steps': [
            ('Kopieren wie immer.', 'Nach dem Einschalten der Aufnahme merkt sich ClipCopy neue kopierte Texte. Vertraulich markierte Kopien und bekannte Passwortmanager werden übersprungen.'),
            ('In der Menüleiste wählen.', 'Öffne die Büroklammer. Ein Klick auf einen Eintrag legt den Text wieder in deine Zwischenablage.'),
            ('Mit Cmd+V einfügen.', 'Zurück in dein Dokument, deine Nachricht oder deinen Browser. Du bestimmst, wo der Text landet.')],
        'local': 'Dein Verlauf.<br>Auf deinem Mac.',
        'localtext': 'ClipCopy speichert Texte lokal verschlüsselt. Der Schlüssel liegt im macOS-Schlüsselbund. Es gibt kein Konto, keine Cloud-Synchronisierung und keine Telemetrie.',
        'points': ['Speicher- und Anzeigelimit selbst festlegen. Standard: 1.000 Einträge.', 'Apps ausschließen und die Aufnahme pausieren.', 'Kein zeitlicher Ablauf. Das Mengenlimit entfernt die ältesten Einträge.'],
        'historyalt': 'ClipCopy-Verwaltung mit drei künstlichen Texteinträgen',
        'historycaption': 'Eigene ClipCopy-Demo. Alle gezeigten Texte sind künstlich.',
        'faqtitle': 'Vor dem ersten Start.',
        'faq': [
            ('Was speichert die Beta?', 'Text aus der Zwischenablage. Rich Text wird als Klartext übernommen, wenn die Quelle eine Textdarstellung anbietet. Bilder, Dateien, Cloud-Sync, automatisches Einfügen und ein globaler Tastaturkurzbefehl sind nicht enthalten.'),
            ('Wie schalte ich die Aufnahme ein?', 'Öffne Preferences… → General und aktiviere Record clipboard history. Erlaube den Zwischenablagezugriff in macOS, falls danach gefragt wird. Wähle bei Bedarf die dauerhafte Freigabe unter Systemeinstellungen → Datenschutz & Sicherheit → Zwischenablage und schalte die Aufnahme erneut ein. Erst die nächste neue Kopie wird erfasst. Beende andere Zwischenablage-Apps vor dem Einschalten der Aufnahme.'),
            ('Sind sensible Texte immer geschützt?', 'Bekannte Passwortmanager und vertraulich markierte Kopien werden übersprungen. ClipCopy kann nicht jeden sensiblen Text erkennen. Pausiere die Aufnahme oder schließe die jeweilige App aus, wenn du dort vertrauliche Texte kopierst.'),
            ('Was muss ich zur Beta wissen?', 'Apple Silicon und macOS 15.4 oder neuer. Version 0.1.1 ist mit einer Apple Developer ID signiert und von Apple notarisiert. Updates installierst du manuell. Bei Verlust des lokalen Schlüsselbundschlüssels ist der Verlauf nicht automatisch wiederherstellbar.')],
        'downloadtitle': 'Einmal kopiert.<br>Nochmal verwenden.', 'installtitle': 'So startest du die Beta.',
        'install': ['ZIP herunterladen, entpacken und ClipCopy.app nach „Programme“ ziehen.', 'ClipCopy öffnen und den macOS-Hinweis zum Download aus dem Internet bestätigen.', 'Unter Preferences… die Aufnahme einschalten und den Zwischenablagezugriff freigeben. Start bei Anmeldung ist optional.'],
        'apple': 'Apples Hinweise zum ersten Start', 'notes': 'Versionshinweise & Prüfsumme',
        'footer': 'Lokaler Textverlauf. Native Menüleiste.', 'github': 'Öffentliches Repository',
        'alt': 'ClipCopy General-Einstellungen: Speicherlimit, Anzeigelimit und Aufnahme'},
    'en': {
        'title': 'ClipCopy for Mac: find what you copied',
        'description': 'Reuse copied text from your Mac menu bar. ClipCopy keeps an encrypted local history. Free Apple Silicon beta.',
        'skip': 'Skip to content', 'nav': ['How it works', 'Local history', 'Questions'],
        'kicker': 'A small utility for your Mac', 'headline': 'Already copied.<br>Ready to reuse.',
        'lead': 'Links, passages, quick notes: ClipCopy keeps copied text in your menu bar. Choose an entry, then paste it again with Cmd+V.',
        'download': 'Download the Mac beta', 'source': 'View source',
        'caption': 'ClipCopy preferences with synthetic example data. Native macOS controls, without a new window for every copy.',
        'steps': [
            ('Copy as usual.', 'Once recording is enabled, ClipCopy remembers newly copied text. Copies marked as confidential and known password managers are skipped.'),
            ('Choose from your menu bar.', 'Open the paperclip. Select an entry to put that text back on your clipboard.'),
            ('Paste with Cmd+V.', 'Back in your document, message or browser. You decide where the text goes.')],
        'local': 'Your history.<br>On your Mac.',
        'localtext': 'ClipCopy encrypts text history locally. The key stays in macOS Keychain. No account, cloud sync or telemetry.',
        'points': ['Choose storage and display limits. The default is 1,000 entries.', 'Exclude apps from recording and pause when needed.', 'No time-based expiry. The count limit removes the oldest entries.'],
        'historyalt': 'ClipCopy history management with three synthetic text entries',
        'historycaption': 'Our ClipCopy demo. All text shown is synthetic.', 'faqtitle': 'Before you get started.',
        'faq': [
            ('What does the beta store?', 'Text from the clipboard. Rich text is captured as plain text when the source offers a text representation. Images, files, cloud sync, automatic pasting and a global keyboard shortcut are not included.'),
            ('How do I enable recording?', 'Open Preferences… → General and enable Record clipboard history. Allow clipboard access in macOS if prompted. If needed, choose persistent clipboard access under System Settings → Privacy & Security → Clipboard, then enable recording again. Recording begins with your next new copy. Quit other clipboard apps before enabling recording.'),
            ('Are sensitive copies always protected?', 'Known password managers and copies marked as confidential are skipped. ClipCopy cannot detect every sensitive text. Pause recording or exclude an app before copying confidential information there.'),
            ('What should I know about the beta?', 'Apple Silicon and macOS 15.4 or newer. Version 0.1.1 is Developer ID signed and notarized by Apple. Updates are manual. A lost local Keychain key cannot be automatically recovered.')],
        'downloadtitle': 'Copy it once.<br>Use it again.', 'installtitle': 'Getting started with the beta.',
        'install': ['Download and extract the ZIP, then move ClipCopy.app to Applications.', 'Open ClipCopy and confirm the macOS prompt for an app downloaded from the internet.', 'Enable recording in Preferences… and grant clipboard access. Launch at login is optional.'],
        'apple': 'Apple’s guide to opening apps', 'notes': 'Release notes & checksum',
        'footer': 'Local text history. Native menu bar.', 'github': 'Public repository',
        'alt': 'ClipCopy General preferences: history limit, display limit and recording'}
}
mark = '<svg viewBox="0 0 32 32" fill="none" aria-hidden="true"><path d="m23 9-11 12a4 4 0 0 1-6-6L19 2a6 6 0 0 1 9 9L13 27a8 8 0 0 1-12-10" transform="translate(2 1) scale(.9)" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/></svg>'

def picture(name, alt):
    height = 230 if name == 'general' else 320
    loading = 'eager' if name == 'general' else 'lazy'
    return f'<picture><source media="(prefers-color-scheme: dark)" srcset="{prefix}assets/{name}-dark.png"><img src="{prefix}assets/{name}-light.png" alt="{alt}" width="420" height="{height}" loading="{loading}"></picture>'

for lang, c in translations.items():
    canonical = base + ('en/' if lang == 'en' else '')
    prefix = '../' if lang == 'en' else './'
    nav = ''.join(f'<a href="#{id}">{label}</a>' for id, label in zip(['workflow', 'local', 'questions'], c['nav']))
    langs = ''.join(f'<a href="{prefix + ("en/" if l == "en" else "")}" lang="{l}" hreflang="{l}" {"aria-current=page" if l == lang else ""}>{l.upper()}</a>' for l in ['de', 'en'])
    steps = ''.join(f'<li><span class="number">0{i+1}</span><h3>{a}</h3><p>{b}</p></li>' for i, (a, b) in enumerate(c['steps']))
    faq = ''.join(f'<details><summary>{a}</summary><p>{b}</p></details>' for a, b in c['faq'])
    points = ''.join(f'<li>{x}</li>' for x in c['points'])
    install = ''.join(f'<li>{x}</li>' for x in c['install'])
    html = f'''<!doctype html>
<html lang="{lang}"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{c['title']}</title><meta name="description" content="{c['description']}"><meta name="theme-color" content="#f4faf6"><meta property="og:title" content="{c['title']}"><meta property="og:description" content="{c['description']}"><meta property="og:type" content="website"><meta property="og:url" content="{canonical}"><meta property="og:image" content="{base}assets/general-light.png"><meta name="twitter:card" content="summary_large_image"><link rel="canonical" href="{canonical}"><link rel="alternate" hreflang="de" href="{base}"><link rel="alternate" hreflang="en" href="{base}en/"><link rel="alternate" hreflang="x-default" href="{base}"><link rel="icon" href="{prefix}favicon.ico" type="image/x-icon"><link rel="icon" href="{prefix}favicon.png" type="image/png"><link rel="apple-touch-icon" href="{prefix}apple-touch-icon.png"><link rel="stylesheet" href="{prefix}styles.css"></head>
<body><a class="skip" href="#main">{c['skip']}</a><header class="shell"><a class="brand" href="{prefix}">{mark}ClipCopy</a><nav aria-label="Navigation">{nav}</nav><div class="languages" aria-label="Language">{langs}</div></header>
<main id="main"><section class="hero shell"><div><p class="kicker">{c['kicker']}</p><h1>{c['headline']}</h1><p class="lead">{c['lead']}</p><div class="actions"><a class="button" href="{download}">{c['download']}</a><a class="minor" href="{repo}">{c['source']}</a></div><p class="compat">v0.1.1 Beta · Apple Silicon · macOS 15.4+</p><div class="keys" aria-hidden="true"><kbd>⌘ C</kbd><span>→</span><kbd>⌘ V</kbd></div></div><figure class="hero-visual">{picture('general', c['alt'])}<figcaption>{c['caption']}</figcaption></figure></section>
<section class="workflow shell" id="workflow" aria-label="{c['nav'][0]}"><ol class="steps">{steps}</ol></section>
<section class="local" id="local"><div class="shell local-grid"><div><p class="kicker">{c['nav'][1]}</p><h2>{c['local']}</h2><p>{c['localtext']}</p><ul>{points}</ul></div><figure>{picture('clips', c['historyalt'])}<figcaption>{c['historycaption']}</figcaption></figure></div></section>
<section class="faq shell" id="questions"><div><p class="kicker">ClipCopy Beta</p><h2>{c['faqtitle']}</h2></div><div class="faq-list">{faq}</div></section>
<section class="download" id="download"><div class="shell download-grid"><div><p class="kicker">ClipCopy 0.1.1</p><h2>{c['downloadtitle']}</h2><a class="button" href="{download}">{c['download']}</a><p class="compat">v0.1.1 Beta · Apple Silicon · macOS 15.4+</p><p class="compat"><a href="{repo}/releases/tag/v0.1.1">{c['notes']}</a></p></div><div class="install"><h3>{c['installtitle']}</h3><ol>{install}</ol><p><a href="https://support.apple.com/102445">{c['apple']}</a></p></div></div></section></main>
<footer class="shell"><a class="brand" href="{prefix}">{mark}ClipCopy</a><p>{c['footer']}</p><a href="{repo}">{c['github']}</a></footer></body></html>'''
    (site / ('en/index.html' if lang == 'en' else 'index.html')).write_text(html)
print('Static DE/EN pages generated. No JavaScript required.')
