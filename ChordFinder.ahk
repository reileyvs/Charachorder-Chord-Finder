#SingleInstance Force
SetWorkingDir A_ScriptDir

; Initialize global variables
global wordFrequency := Map()
global currentWord := ""
global helpGui := ""
global customStrings := Map()
global settingsGui := ""
global tray := A_TrayMenu  ; Get handle to tray menu

; Load existing word frequencies from file
if FileExist("words_frequency.txt") {
    try {
        fileContent := FileRead("words_frequency.txt")
        lines := StrSplit(fileContent, "`n")
        for line in lines {
            if (line = "")  ; Skip empty lines
                continue
                
            parts := StrSplit(line, "`t")
            if (parts.Length >= 2) {
                word := parts[1]
                freq := Integer(parts[2])
                if (freq > 0)
                    wordFrequency[word] := freq
            }
        }
    } catch Error as e {
        MsgBox("Error loading word frequencies: " . e.Message)
    }
}

; Create the help GUI
helpGui := Gui("+AlwaysOnTop +ToolWindow -Caption +Border")
helpGui.BackColor := "F0F0F0"  ; Light gray background
WinSetTransparent(220, helpGui)  ; Make entire window semi-transparent
helpGui.SetFont("s14", "Arial")
helpText := helpGui.Add("Text", "w280 h130 cBlack", "")
helpGui.Show("w300 h150 NoActivate")

; Load chords from JSON if file exists
if FileExist("chords.json") {
    try {
        ; Read the file content
        jsonContent := FileRead("chords.json")
        
        ; Use RegEx to find and extract chord data
        pattern := "\[\[([0-9,]+)\],\[([0-9,]+)\]\]"
        pos := 1
        
        while (RegExMatch(jsonContent, pattern, &match, pos)) {
            ; Process input array (first capture group)
            inputCodes := StrSplit(match[1], ",")
            inputString := ""
            for _, codeStr in inputCodes {
                code := Integer(codeStr)
                if (code > 0)
                    inputString .= Chr(code)
            }
            
            ; Process output array (second capture group)
            outputCodes := StrSplit(match[2], ",")
            outputString := ""
            for _, codeStr in outputCodes {
                code := Integer(codeStr)
                if (code > 0)
                    outputString .= Chr(code)
            }
            
            ; Add to custom strings if both are not empty
            if (inputString && outputString) {
                ; If this output string already has a list, add to it
                if (customStrings.Has(outputString)) {
                    ; Check if this inputString is already in the list
                    alreadyExists := false
                    for _, existingInput in customStrings[outputString] {
                        if (existingInput == inputString) {
                            alreadyExists := true
                            break
                        }
                    }
                    
                    ; Add it if its not a duplicate
                    if (!alreadyExists)
                        customStrings[outputString].Push(inputString)
                } else {
                    ; Create a new array with this inputString
                    customStrings[outputString] := [inputString]
                }
            }
            
            ; Move position for next search
            pos := match.Pos + match.Len
        }
    } catch Error as e {
        MsgBox("Error processing JSON file: " . e.Message)
    }
}

; Hook keyboard input
InstallKeybdHook()

; Add this function to handle file updates
UpdateWordFrequencyFile() {
    global wordFrequency
    
    try {
        ; Create content with all current frequencies
        fileContent := ""
        for word, freq in wordFrequency {
            if (StrLen(word) > 2)  ; Only save words longer than 2 characters
                fileContent .= word . "`t" . freq . "`n"
        }
        
        ; Overwrite the entire file with updated content
        FileDelete("words_frequency.txt")
        FileAppend(fileContent, "words_frequency.txt")
    } catch Error as e {
        MsgBox("Error updating frequency file: " . e.Message)
    }
}

; Modify the HandleKeypress function to use the new update method
HandleKeypress(key) {
    global currentWord, wordFrequency, customStrings
    
    ; Special handling for capital letters (preserve case)
    if (StrLen(key) == 1 && Ord(key) >= 65 && Ord(key) <= 90) {
        ; Its a capital letter, add it directly
        currentWord .= key
        UpdateHelpGui()
        return
    }
    
    ; Handle punctuation and non-word-building keys
    if (key = "Space" || key = "Enter" || 
        key = "," || key = "." || key = "!" || key = "?" || 
        key = ":" || key = ";" || key = ")" || key = "]" || key = "}") {
        
        ; Word completed
        if (currentWord != "") {
            ; Only process words longer than 2 characters
            if (StrLen(currentWord) > 2) {
                ; Update frequency
                wordFrequency[currentWord] := (wordFrequency.Has(currentWord) ? wordFrequency[currentWord] : 0) + 1
                
                ; Update the file with all current frequencies
                UpdateWordFrequencyFile()
            }
            
            currentWord := ""
            UpdateHelpGui()
        }
        
        ; For punctuation that doesnt end a word, continue the word
        if (key = "'" || key = "-" || key = "_" || key = "(" || key = "[" || key = "{") {
            currentWord .= key
            UpdateHelpGui()
        }
    }
    else if (key = "Backspace") {
        ; Remove last character
        if (StrLen(currentWord) > 0)
            currentWord := SubStr(currentWord, 1, StrLen(currentWord) - 1)
        UpdateHelpGui()
    }
    else {
        ; Add character to current word
        currentWord .= key
        UpdateHelpGui()
    }
}

; Define UpdateHelpGui function
UpdateHelpGui() {
    global currentWord, customStrings, helpText, helpGui
    
    ; If currentWord is empty, just show an empty GUI or hide it
    if (currentWord == "") {
        helpText.Value := ""
        helpGui.Hide()
        return
    }
    
    ; Find all matches that start with currentWord
    suggestionsText := ""
    count := 0
    maxSuggestions := 5  ; Limit number of suggestions to show
    
    ; First add exact match if it exists
    if (customStrings.Has(currentWord)) {
        suggestionsText .= "`n" . currentWord . " -> "
        
        ; Add all input strings for this output word
        for i, inputStr in customStrings[currentWord] {
            if (i > 1)  ; Add separator after the first one
                suggestionsText .= ", "
            suggestionsText .= inputStr
        }
        count++
    }
    
    ; Then add other words that start with currentWord
    if (currentWord != "") {
        for word, inputsList in customStrings {
            if (InStr(word, currentWord) == 1 && word != currentWord) {  ; Starts with currentWord but is not currentWord
                suggestionsText .= "`n" . word . " -> "
                
                ; Add all input strings for this word
                for i, inputStr in inputsList {
                    if (i > 1)  ; Add separator after the first one
                        suggestionsText .= ", "
                    suggestionsText .= inputStr
                }
                
                count++
                if (count >= maxSuggestions)
                    break
            }
        }
    }
    
    ; Update help window text
    helpText.Value := currentWord . "`n-----------------------" suggestionsText
    
    ; Make the GUI bigger if we have suggestions
    if (count > 0) {
        helpGui.Opt("+MinSize300x" . (150 + count * 30))  ; Increase height based on suggestion count
        helpText.Opt("w280 h" . (130 + count * 30))
    } else {
        helpGui.Opt("+MinSize300x150")
        helpText.Opt("w280 h130")
    }
    
    ; Determine which side of the screen to anchor based on mouse position
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    
    ; Get screen dimensions
    screenWidth := A_ScreenWidth
    screenHeight := A_ScreenHeight
    
    ; Anchor to bottom left or right based on mouse position
    if (mouseX < screenWidth / 2) {
        ; Left side of screen
        xPos := screenWidth - 320
    } else {
        ; Right side of screen
        xPos := 20
    }
    
    ; Set Y position to bottom of screen with some padding
    yPos := screenHeight - 250 ; Adjust Y position based on GUI height
    
    ; Show GUI with dynamic size based on suggestions
    guiHeight := 150
    helpGui.Show("x" . xPos . " y" . yPos . " w300 h" . guiHeight . " NoActivate")
}

ResetAndHideGui() {
    global currentWord, helpGui
    
    ; Reset the current word
    currentWord := ""
    
    ; Hide the GUI
    helpGui.Hide()
}

; Create settings menu option in tray
tray.Add("Settings", ShowSettingsGui)

; Function to create and show settings GUI
ShowSettingsGui(*) {
    global settingsGui, wordFrequency, customStrings
    
    ; If settings GUI already exists, just show it
    if (settingsGui) {
        settingsGui.Show()
        return
    }
    
    ; Create new settings GUI
    settingsGui := Gui("+Resize")
    settingsGui.Title := "ChordFinder Settings"
    settingsGui.SetFont("s10", "Arial")
    
    ; Add tabs for different settings sections
    tabs := settingsGui.Add("Tab3", "w600 h400", ["Word Statistics", "Appearance", "About"])
    
    ; Word Statistics Tab
    tabs.UseTab(1)
    
    ; Create ListView for high frequency words
    freqList := settingsGui.Add("ListView", "w580 h300", ["Word", "Frequency", "Has Chord?"])
    
    ; Populate ListView with word frequencies
    wordArray := []
    for word, freq in wordFrequency {
        hasChord := customStrings.Has(word) ? "Yes" : "No"
        wordArray.Push([word, freq, hasChord])
    }
    
    ; Sort by frequency (descending)
    n := wordArray.Length
    loop n-1 {
        i := A_Index
        loop n-1-i {
            j := A_Index
            if (wordArray[j][2] < wordArray[j+1][2]) {
                ; Swap elements
                temp := wordArray[j]
                wordArray[j] := wordArray[j+1]
                wordArray[j+1] := temp
            }
        }
    }
    
    ; Add items to ListView
    for item in wordArray {
        if (item[3] == "No" && item[2] > 1) {  ; Only show words without chords and frequency > 1
            freqList.Add(, item[1], item[2], item[3])
        }
    }
    
    ; Add filter controls
    settingsGui.Add("Text", "xm y+10", "Minimum Frequency:")
    freqFilter := settingsGui.Add("Edit", "x+10 yp-3 w60", "2")
    settingsGui.Add("Button", "x+10 yp", "Apply Filter").OnEvent("Click", (*) => UpdateFrequencyList(freqList, freqFilter))
    
    ; Export button
    settingsGui.Add("Button", "x+20", "Export Missing Words").OnEvent("Click", (*) => ExportMissingWords(wordArray))
    
    ; Appearance Tab
    tabs.UseTab(2)
    settingsGui.Add("Text", "xm y+10", "GUI Transparency:")
    transparencySlider := settingsGui.Add("Slider", "x+10 yp w200 Range0-255", 220)
    transparencySlider.OnEvent("Change", (*) => UpdateTransparency(transparencySlider.Value))
    
    settingsGui.Add("Text", "xm y+20", "Background Color:")
    colorPicker := settingsGui.Add("Edit", "x+10 yp-3 w100", "F0F0F0")
    settingsGui.Add("Button", "x+10 yp", "Apply Color").OnEvent("Click", (*) => UpdateBackgroundColor(colorPicker.Value))
    
    ; About Tab
    tabs.UseTab(3)
    settingsGui.Add("Text", "xm y+10", "ChordFinder Settings")
    settingsGui.Add("Text", "xm y+10", "Version 1.0")
    settingsGui.Add("Text", "xm y+10", "A tool for managing and viewing chord mappings.")
    
    ; Show the settings GUI
    settingsGui.Show()
}

; Function to update frequency list based on filter
UpdateFrequencyList(listView, freqFilter) {
    global wordFrequency, customStrings
    
    ; Clear existing items
    listView.Delete()
    
    ; Get minimum frequency
    minFreq := Integer(freqFilter.Value)
    if (minFreq < 1)
        minFreq := 1
    
    ; Create sorted array
    wordArray := []
    for word, freq in wordFrequency {
        ; Only include words longer than 2 characters
        if (StrLen(word) > 2) {
            hasChord := customStrings.Has(word) ? "Yes" : "No"
            if (freq >= minFreq)
                wordArray.Push([word, freq, hasChord])
        }
    }
    
    ; Sort by frequency (descending)
    n := wordArray.Length
    loop n-1 {
        i := A_Index
        loop n-1-i {
            j := A_Index
            if (wordArray[j][2] < wordArray[j+1][2]) {
                ; Swap elements
                temp := wordArray[j]
                wordArray[j] := wordArray[j+1]
                wordArray[j+1] := temp
            }
        }
    }
    
    ; Add filtered items
    for item in wordArray {
        if (item[3] == "No")  ; Only show words without chords
            listView.Add(, item[1], item[2], item[3])
    }
}

; Function to export missing words to a file
ExportMissingWords(wordArray) {
    try {
        fileContent := "Word,Frequency`n"
        for item in wordArray {
            ; Only export words longer than 2 characters
            if (item[3] == "No" && item[2] > 1 && StrLen(item[1]) > 2)
                fileContent .= item[1] . "," . item[2] . "`n"
        }
        
        ; Save to file
        if (selectedFile := FileSelect(8,, "Export Missing Words", "CSV Files (*.csv)")) {
            FileDelete(selectedFile)
            FileAppend(fileContent, selectedFile)
            MsgBox("Missing words exported successfully to " . selectedFile)
        }
    } catch Error as e {
        MsgBox("Error exporting words: " . e.Message)
    }
}

; Function to update GUI transparency
UpdateTransparency(value) {
    global helpGui
    WinSetTransparent(value, helpGui)
}

; Function to update GUI background color
UpdateBackgroundColor(color) {
    global helpGui
    helpGui.BackColor := color
}

; Include all the hotkey definitions from the separate file
#Include Hotkeys.ahk

; Hotkey to exit script
Hotkey "^Esc", (*) => ExitApp()
