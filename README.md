# ChordFinder

ChordFinder is an AutoHotkey v2 script that helps users learn and discover Charachorder chord mappings while typing. It provides real-time suggestions and tracks word frequencies to help optimize your typing experience.

## Features

### 1. Real-Time Chord Suggestions
- Displays a floating GUI window that shows chord suggestions as you type
- Updates suggestions dynamically based on your current word
- Shows up to 5 most relevant suggestions at a time
- Supports both exact matches and prefix-based suggestions
- Format: `word -> chord1, chord2, ...` (multiple chord options per word)

### 2. Word Frequency Tracking
- Automatically tracks the frequency of words you type
- Stores frequencies in `words_frequency.txt`
- Only tracks words longer than 2 characters
- Maintains a running count of how often each word is used

### 3. Smart GUI Behavior
- GUI appears automatically while typing
- Positions itself intelligently based on mouse location
- Disappears when clicking anywhere on the screen
- Semi-transparent for minimal visual interference
- Resizes dynamically based on the number of suggestions

### 4. Comprehensive Input Support
- Handles lowercase and uppercase letters
- Supports numbers 0-9
- Processes special keys (Space, Enter, Backspace)
- Full punctuation support including:
  - Basic punctuation (.,;'-=)
  - Brackets ([{}])
  - Quotes ("'`)
  - Special characters (@#$%^&*)

### 5. Settings Menu
- Accessible via system tray icon
- Features multiple tabs:
  1. Word Statistics
     - Shows high-frequency words
     - Filters for words without chord mappings
     - Minimum frequency filter
     - Export missing words to CSV
  2. Appearance
     - Adjustable GUI transparency
     - Customizable background color
  3. About information

### 6. Custom Chord Mappings
- Loads chord mappings from `chords.json`
- Supports multiple chord options per word
- Automatically updates when new mappings are added

## Files
- `ChordFinder.ahk` - Main script file
- `Hotkeys.ahk` - Keyboard and mouse input definitions
- `chords.json` - Chord mapping database
- `words_frequency.txt` - Word frequency tracking file

## Requirements
- AutoHotkey v2
- Windows OS

## Installation
1. Install AutoHotkey v2
2. Download all script files
3. Place `chords.json` in the same directory as the script
4. Run `ChordFinder.ahk`

## Usage
1. Start typing in any application
2. Watch for the suggestion window to appear
3. Press Space or punctuation to complete words
4. Click anywhere to hide suggestions
5. Access settings through the tray icon

## Tips
- The script tracks word frequencies to help identify commonly used words that might benefit from chord mappings
- Export missing words to find opportunities for new chord mappings
- Adjust GUI transparency and position for optimal visibility
- Use the statistics view to optimize your most frequent words

## Note
This tool is designed to help users learn and optimize their Charachorder usage by providing real-time feedback and usage statistics. It does not modify your typing but rather provides suggestions and tracking to help improve your chord usage over time.
