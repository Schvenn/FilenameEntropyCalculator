# Overview
This module recursively locates high entropy filenames within the specified path, providing output to screen, file or both. This is particularly useful for finding filenames written by malware.

    Usage: filenameentropycalculator "path" <threshold #> <throttlelimit #> <-file> <-quiet> <-help>

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

# Parameters
    • Use the threshold parameter to control what is considered “suspicious.” 11 is the default.
    • Set the throttle limit to control parallel processing, for performance enhancements during large jobs. 8 is the default.
    • Use the file switch to write matching filenames to a file called "HighEntropyFilenames.txt" in the current directory. Without this switch the script will only output to screen.
    • Use the quiet switch to suppress screen output, which will thereby force the file switch to be enabled.
