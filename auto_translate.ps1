$key  = "sk-a1801578688e46d7a5a105998c366c13"
$file = "ce_src.tsv"
$batch = 60
$rules = @"
Ты переводчик игры OneShot (англ->рус). Получишь нумерованные строки.
Верни СТРОГО по одной строке на вход: "<номер><TAB><перевод>", тот же порядок, без markdown и пояснений.
1. Теги портретов в начале (@niko_speak, @menderbot, @ed, @desktop и т.п.) копировать как есть, с пробелом после.
2. Коды \\> \\| \\. \\n \\\\ \\c[N] \\v[N] \\p сохранять побуквенно.
3. Фрагменты EdText.info(" / EdText.err(" / EdText.yesno(" без закрывающей кавычки — перевод с той же обёрткой и БЕЗ закрывающей кавычки; если строка кончается на ") — перевод тоже кончается на ").
4. Строки только из тегов/кодов/[...], начинающиеся с ":", кракозябры — верни "<номер><TAB>" (пусто).
5. Тон: Нико — ребёнок; роботы — КАПСом в [ ]; George — просторечно; Ed — сухо.
6. Глоссарий: Niko=Нико, Calamus=Каламус, Alula=Алула, Cedric=Седрик, Silver=Сильвер, Menderbot=Мендербот, Rowbot=Роубот, Prophetbot=Пророфбот, George=Джордж, Author=Автор, messiah=мессия, the squares=квадраты, the Sun=Солнце, the Tower=Башня.
7. Пробелы в начале/конце строки сохранять.
"@
function Invoke-DS($text) {
  $body = @{ model = "deepseek-chat"; messages = @(@{role="system";content=$rules}, @{role="user";content=$text}); temperature = 0.3; max_tokens = 8192 } | ConvertTo-Json -Depth 10
  $r = Invoke-WebRequest -Uri "https://api.deepseek.com/chat/completions" -Method Post -ContentType "application/json; charset=utf-8" -Headers @{ Authorization = "Bearer $key" } -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -UseBasicParsing
  $j = [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) | ConvertFrom-Json
  if (-not $j.choices) { throw "Пустой ответ API" }
  return $j.choices[0].message.content
}
$src = Get-Content $file -Encoding UTF8
$cnt = @(); $orig = @(); $have = @{}
for ($i = 0; $i -lt $src.Count; $i++) {
  if ($src[$i] -match '^#') { continue }
  $p = $src[$i] -split "`t"
  $cnt += $p[0]; $orig += $p[1]
  if ($p.Count -ge 3 -and $p[2]) { $have[$cnt.Count] = $p[2] }
}
$tr = @{}
function Save-Progress {
  $out = @(); $n = 0
  foreach ($l in $src) {
    if ($l -match '^#') { $out += $l; continue }
    $n++
    $t = ""; if ($tr[$n]) { $t = $tr[$n] } elseif ($have[$n]) { $t = $have[$n] }
    $out += "$($cnt[$n-1])`t$($orig[$n-1])`t$t"
  }
  $out | Set-Content $file -Encoding UTF8
}
$todo = @(); for ($n = 1; $n -le $orig.Count; $n++) { if (-not $have[$n]) { $todo += $n } }
Write-Host "строк: $($orig.Count), перевести: $($todo.Count)"
for ($pass = 1; $pass -le 3 -and $todo.Count -gt 0; $pass++) {
  $left = @()
  for ($s = 0; $s -lt $todo.Count; $s += $batch) {
    $chunk = $todo[$s..([Math]::Min($s + $batch - 1, $todo.Count - 1))]
    $lines = ($chunk | ForEach-Object { "$_`t$($orig[$_ - 1])" }) -join "`n"
    $res = $null
    for ($att = 1; $att -le 4; $att++) {
      try { $res = Invoke-DS $lines; break }
      catch {
        $code = 0
        if ($_.Exception.Response) { try { $code = [int]$_.Exception.Response.StatusCode } catch {} }
        Write-Host "ERR $code, попытка $att"
        if ($code -eq 429) { Start-Sleep 30 } elseif ($code -ge 500) { Start-Sleep 10 } else { Save-Progress; throw }
      }
    }
    if (-not $res) { $left += $chunk; continue }
    foreach ($ln in ($res -split "`n")) {
      if ($ln -match '^(\d+)\t(.*)$') {
        $n = [int]$Matches[1]
        if ($chunk -contains $n) { $tr[$n] = $Matches[2] }
      }
    }
    Write-Host "batch ok, всего: $($tr.Count + $have.Count)/$($orig.Count)"
    Save-Progress
    Start-Sleep 2
  }
  $todo = $left
}
Save-Progress
Write-Host "ГОТОВО: $($tr.Count + $have.Count)/$($orig.Count)"