# Recursively run the calculator over an entire path.
function findentropy ([string]$Path, [double]$Threshold = 11, [int]$ThrottleLimit = 8, [switch]$file, [switch]$quiet, [switch]$help) {# Find suspicious filenames.
# Entropy calculation variables:
$enumerated = 0; $scored = 0; $sum = 0.0; $min = [double]::MaxValue; $max = [double]::MinValue
# File write variables:
$writeToFile = $file -or $quiet; $logFile = ".\HighEntropyFilenames.txt"; $buffer = New-Object System.Collections.Generic.List[string]; $flushSize = 50

if ((-not $path) -and (-not $help)) {Write-Host -n -f cyan "`nUsage: findentropy `"path`" <threshold #> <throttlelimit #> <-file> <-quiet> <-help>`n`n"; return}

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

# Display a horizontal line.
function line ($colour, $length, [switch]$pre, [switch]$post, [switch]$double) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
$character = if ($double) {"="} else {"-"}
Write-Host -f $colour ($character * $length)
if ($post) {Write-Host ""}}

function help {# Inline help.
# Select content.
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)"); $selection = $null; $lines = @(); $wrappedLines = @(); $position = 0; $pageSize = 30; $inputBuffer = ""

function scripthelp ($section) {$pattern = "(?ims)^## ($([regex]::Escape($section)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}

# Display Table of Contents.
while ($true) {cls; Write-Host -f cyan "$(Get-ChildItem (Split-Path $PSCommandPath) | Where-Object { $_.FullName -ieq $PSCommandPath } | Select-Object -ExpandProperty BaseName) Help Sections:`n"

if ($sections.Count -gt 7) {$half = [Math]::Ceiling($sections.Count / 2)
for ($i = 0; $i -lt $half; $i++) {$leftIndex = $i; $rightIndex = $i + $half; $leftNumber  = "{0,2}." -f ($leftIndex + 1); $leftLabel   = " $($sections[$leftIndex].Groups[1].Value)"; $leftOutput  = [string]::Empty

if ($rightIndex -lt $sections.Count) {$rightNumber = "{0,2}." -f ($rightIndex + 1); $rightLabel  = " $($sections[$rightIndex].Groups[1].Value)"; Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel -n; $pad = 40 - ($leftNumber.Length + $leftLabel.Length)
if ($pad -gt 0) {Write-Host (" " * $pad) -n}; Write-Host -f cyan $rightNumber -n; Write-Host -f white $rightLabel}
else {Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel}}}

else {for ($i = 0; $i -lt $sections.Count; $i++) {Write-Host -f cyan ("{0,2}. " -f ($i + 1)) -n; Write-Host -f white "$($sections[$i].Groups[1].Value)"}}

# Display Header.
line yellow 100
if ($lines.Count -gt 0) {Write-Host  -f yellow $lines[0]}
else {Write-Host "Choose a section to view." -f darkgray}
line yellow 100

# Display content.
$end = [Math]::Min($position + $pageSize, $wrappedLines.Count)
for ($i = $position; $i -lt $end; $i++) {Write-Host -f white $wrappedLines[$i]}

# Pad display section with blank lines.
for ($j = 0; $j -lt ($pageSize - ($end - $position)); $j++) {Write-Host ""}

# Display menu options.
line yellow 100; Write-Host -f white "[↑/↓]  [PgUp/PgDn]  [Home/End]  |  [#] Select section  |  [Q] Quit  " -n; if ($inputBuffer.length -gt 0) {Write-Host -f cyan "section: $inputBuffer" -n}; $key = [System.Console]::ReadKey($true)

# Define interaction.
switch ($key.Key) {'UpArrow' {if ($position -gt 0) { $position-- }; $inputBuffer = ""}
'DownArrow' {if ($position -lt ($wrappedLines.Count - $pageSize)) { $position++ }; $inputBuffer = ""}
'PageUp' {$position -= 30; if ($position -lt 0) {$position = 0}; $inputBuffer = ""}
'PageDown' {$position += 30; $maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); if ($position -gt $maxStart) {$position = $maxStart}; $inputBuffer = ""}
'Home' {$position = 0; $inputBuffer = ""}
'End' {$maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); $position = $maxStart; $inputBuffer = ""}

'Enter' {if ($inputBuffer -eq "") {"`n"; return}
elseif ($inputBuffer -match '^\d+$') {$index = [int]$inputBuffer
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index; $pattern = "(?ims)^## ($([regex]::Escape($sections[$selection-1].Groups[1].Value)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $block = $match.Groups[1].Value.TrimEnd(); $lines = $block -split "`r?`n", 2
if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}}
$inputBuffer = ""}

default {$char = $key.KeyChar
if ($char -match '^[Qq]$') {"`n"; return}
elseif ($char -match '^\d$') {$inputBuffer += $char}
else {$inputBuffer = ""}}}}}

# External call to help.
if ($help) {help; return}

Write-Host -n -f cyan "`nProcessing "

Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object -Parallel {# Use Shannon entropy calculation to determine character frequency patterns.
function StringEntropy ([string]$s) {$len = $s.Length
if($len -eq 0){return 0}
$freq = @{}
foreach($c in $s.ToCharArray()){if(!$freq[$c]){$freq[$c]=0}; $freq[$c]++}
$entropy = 0
foreach($count in $freq.Values){$p = $count / $len; $entropy -= $p * [math]::Log($p,2)}
[math]::Round($entropy,3)}

# Look for upper, lower, digit and symbol distribution over run length.
function StringFeatures ([string]$s) {$class = {param($c)
if($c -match '[a-z]'){'l'}
elseif($c -match '[A-Z]'){'u'}
elseif($c -match '\d'){'d'}
else{'s'}}
$chars = $s.ToCharArray(); $classes = $chars | ForEach-Object {& $class $_}; $switches = 0
for($i=1;$i -lt $classes.Count;$i++){if($classes[$i] -ne $classes[$i-1]){$switches++}}
$switchRate = if($classes.Count -gt 1){$switches/($classes.Count-1)}
else{0}

# Calculate run lengths.
$runs = @(); $run = 1
for($i=1;$i -lt $classes.Count;$i++){if($classes[$i] -eq $classes[$i-1]){$run++}
else{$runs += $run;$run=1}}
$runs += $run
$avgRun = ($runs | Measure-Object -Average).Average

# Calculate character class distributions.
$counts = @{l = ($classes | Where-Object {$_ -eq 'l'}).Count; u = ($classes | Where-Object {$_ -eq 'u'}).Count; d = ($classes | Where-Object {$_ -eq 'd'}).Count; s = ($classes | Where-Object {$_ -eq 's'}).Count}
$total = $classes.Count; $balance = ($counts.Values | ForEach-Object {($_ / $total)} | Measure-Object -StandardDeviation).StandardDeviation
[pscustomobject]@{SwitchRate = [math]::Round($switchRate,3)
AvgRunLength = [math]::Round($avgRun,2)
ClassBalance = [math]::Round($balance,3)}}

# Calculate the score of a file based upon: (1.5 * entropy) + (3 * switch_rate) + (2 * (1 / avg_run_length)) + (2 * (1 - class_balance))
function FilenameScore ([string]$name) {$entropy = StringEntropy $name; $f = StringFeatures $name
# Tunable score settings.
$score = ($entropy * 1.5) + ($f.SwitchRate * 3) + ((1 / $f.AvgRunLength) * 2) + ((1 - $f.ClassBalance) * 2)

[pscustomobject]@{Name = $name
Entropy = $entropy
SwitchRate = $f.SwitchRate
AvgRun = $f.AvgRunLength
Score = [math]::Round($score,3)}}

$result = FilenameScore $_.Name
# Exclude hexadecimal filenames.
if ([System.IO.Path]::GetFileNameWithoutExtension($_.Name) -match '^[0-9a-fA-F]+$') {$result = 1}

[pscustomobject]@{Name = $_.Name
FullPath = $_.FullName
Score = $result.Score
Entropy = $result.Entropy
Switch = $result.SwitchRate
AvgRun = $result.AvgRun}} -ThrottleLimit $ThrottleLimit | ForEach-Object {$enumerated++; $scored++; $score = $_.Score; $sum += $score; if($score -lt $min){$min = $score}
if($score -gt $max){$max = $score}

# Show progress indicator after 100 file evaluations.
if (($scored % 100 -eq 0) -and (-not $quiet)){Write-Host -n -f cyan "."}

# Output summary to screen.
if($score -ge $Threshold -and $null -ne $_.Name){$avg = if ($scored -gt 0) {$sum / $scored} else {0}
if (-not $quiet) {Write-Host -n -f white ("`n`nFiles`:`t$scored")
Write-Host -n -f green ("`tMinimum Score`:`t{0:N3}" -f $min)
Write-Host -n -f yellow ("`tAverage Score`:`t{0:N3}" -f $avg)
Write-Host -f red ("`tMaximum Score`:`t{0:N3}" -f $max)

# Output files that surpass the threshold to screen.
$flag = "⚠️"
[pscustomobject]@{Flag = $flag
Score = $score
Path = $_.FullPath} | Format-Table -AutoSize | Out-Host}

# Write files that surpass the threshold to disk if requested, using a buffer to reduce file writes.
if ($writeToFile) {$buffer.Add($_.FullPath)
if ($buffer.Count -ge $flushSize) {$buffer | Add-Content -Path $logFile; $buffer.Clear()}}}}
# Ensure remaining files in buffer get added to file, if requested.
if (($buffer.Count -gt 0) -and $writetofile) {$buffer | Add-Content -Path $logFile; $buffer.Clear()}
Write-Host -f yellow ("-"*100); Write-Host ""}

Export-ModuleMember -function findentropy

# Helptext.

<#
## Overview
This module recursively locates high entropy filenames within the specified path, providing output to screen, file or both. This is particularly useful for finding filenames written by malware.

Usage: findentropy "path" <threshold #> <throttlelimit #> <-file> <-quiet> <-help>

Entropy Score Calculation:

The score is based on how “random” a filename looks. Higher scores mean the name is more likely to be machine-generated or suspicious.

Score = (1.5 × entropy) + (3 × switch_rate) + (2 × (1 − class_balance)) + (2 × (1 / avg_run_length))

• Where entropy measures how unpredictable the characters are within the filename, based on the Shannon entropy model: H = -∑(p(x) * log₂ p(x))
  (https://en.wikipedia.org/wiki/Entropy_(information_theory))

• The switch_rate calculates how often the filename switches between character types, including upper and lower-case letters, numbers and symbols.

• The avg_run_length calculates the average length of repeated character types.

• The class_balance calculates how evenly the filename uses the character types.

In simple terms:

Random-looking names, such as those with mixed case, numbers, symbols and constant switching between these will score high.
Human-readable names, such as those containing words and consistent patterns will score low.

Examples:

"report_final_2024.txt" → low score
"f84e5c391f9f55b3d2d6b10a92f118b4.png" → high score

## Parameters
• Use the threshold parameter to control what is considered “suspicious.” 11 is the default.

• Set the throttle limit to control parallel processing, for performance enhancements during large jobs. 8 is the default.

• Use the file switch to write matching filenames to a file called "HighEntropyFilenames.txt" in the current directory. Without this switch the script will only output to screen.

• Use the quiet switch to suppress screen output, which will thereby force the file switch to be enabled.

## License
MIT License

Copyright (c) 2026 Craig Plath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
##>
