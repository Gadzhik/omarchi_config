# -*- coding: utf-8 -*-
# ЙЦУКЕН: латинская буква -> кириллический символ на той же физической клавише
M = {
 'a':'ф','b':'и','c':'с','d':'в','e':'у','f':'а','g':'п','h':'р','i':'ш',
 'j':'о','k':'л','l':'д','m':'ь','n':'т','o':'щ','p':'з','q':'й','r':'к',
 's':'ы','t':'е','u':'г','v':'м','w':'ц','x':'ч','y':'н','z':'я',
}
NOTE = {
 'a':'начало строки','b':'назад','c':'прервать','d':'EOF','e':'конец строки',
 'f':'вперёд','h':'backspace','i':'tab','k':'убить до конца','l':'очистить экран',
 'm':'return','n':'следующая команда','p':'предыдущая команда','r':'поиск по истории',
 'u':'убить строку','w':'убить слово','y':'вставить убитое','z':'в фон',
}
out = []
out.append('')
out.append('# ' + '-'*74)
out.append('# Раскладко-независимые сочетания (kb_layout = us,ru).')
out.append('#')
out.append('# Alacritty сопоставляет биндинги с символом активной раскладки. В русской')
out.append('# Ctrl+A -> Ctrl+ф, а из не-ASCII символа управляющий код не выводится, и в')
out.append('# шелл не уходит ничего. Ниже явные биндинги для кириллицы по позиции ЙЦУКЕН.')
out.append('#')
out.append('# Ctrl+<буква> -> управляющий код ^A..^Z')
out.append('# ' + '-'*74)
for i, lat in enumerate('abcdefghijklmnopqrstuvwxyz'):
    code = i + 1
    cyr = M[lat]
    note = ('  # Ctrl+%s  %s' % (lat.upper(), NOTE[lat])) if lat in NOTE else ('  # Ctrl+%s' % lat.upper())
    out.append('{ key = "%s", mods = "Control", chars = "\\u%04X" },%s' % (cyr, code, note))
# Ctrl+[ и Ctrl+] на позициях х и ъ
out.append('{ key = "х", mods = "Control", chars = "\\u001B" },  # Ctrl+[  Escape (важно для vim)')
out.append('{ key = "ъ", mods = "Control", chars = "\\u001D" },  # Ctrl+]')
out.append('')
out.append('# Alt+<буква> -> ESC + латинская буква (readline: перемещение по словам)')
ALTNOTE = {'b':'слово назад','d':'убить слово вперёд','f':'слово вперёд','.':'последний аргумент'}
for lat in 'abcdefghijklmnopqrstuvwxyz':
    cyr = M[lat]
    note = ('  # Alt+%s  %s' % (lat.upper(), ALTNOTE[lat])) if lat in ALTNOTE else ''
    out.append('{ key = "%s", mods = "Alt", chars = "\\u001B%s" },%s' % (cyr, lat, note))
out.append('')
out.append('# Собственные сочетания Alacritty')
out.append('{ key = "с", mods = "Control|Shift", action = "Copy" },            # Ctrl+Shift+C')
out.append('{ key = "м", mods = "Control|Shift", action = "Paste" },           # Ctrl+Shift+V')
out.append('{ key = "а", mods = "Control|Shift", action = "SearchForward" },   # Ctrl+Shift+F')
out.append('{ key = "и", mods = "Control|Shift", action = "SearchBackward" }   # Ctrl+Shift+B')

print('\n'.join(out))
