Attribute VB_Name = "Module1"
Option Explicit

' Kataloghub Validation Worksheet builder
' Run on a fresh sheet inside the Kataloghub_Validation .xlsm template.
' Output mirrors HeyRoya's Metadata Correction Template (one row per work-line,
' single corrected_value column for publisher edits).
' Operator pastes catalog rows into A9:K508 after the macro has built the
' structure; the notes column (M) is pre-populated by Kataloghub with
' validation issues. Only L (corrected_value) and M (notes) remain editable.

Sub CreateKataloghubWorksheet()

    Dim ws As Worksheet
    Set ws = ActiveSheet

    ' --- 1. Clear sheet ---
    ws.Cells.Clear

    ' --- 2. Title block (rows 1-3) ---
    ws.Range("A1").Value = "HeyRoya"
    ws.Range("A1").Font.Bold = True
    ws.Range("A1").Font.Size = 18

    ws.Range("A2").Value = "Metadata Correction Template"
    ws.Range("A2").Font.Bold = True
    ws.Range("A2").Font.Size = 14

    ws.Range("A3").Value = "For Music Publishers   " & ChrW(183) & "   File-based correction workflow"
    ws.Range("A3").Font.Italic = True

    ' --- 3. Instructions (rows 5-7) ---
    ws.Range("A5").Value = ChrW(8226) & "  Publishers only edit the 'corrected_value' and 'notes' columns."
    ws.Range("A6").Value = ChrW(8226) & "  All other fields reflect the original metadata as received."
    ws.Range("A7").Value = ChrW(8226) & "  Return the completed file to HeyRoya for processing."

    ' --- 4. Table Header (row 8) ---
    Dim headers As Variant
    headers = Array("work id", "title", "writer name", "writer ipi", "role code", _
                    "share percentage", "publisher name", "publisher ipi", "STIM", _
                    "iswc", "isrc", "corrected value", "notes")

    ws.Range("A8:M8").Value = headers
    ws.Range("A8:M8").Font.Bold = True
    ws.Range("A8:M8").Interior.Color = RGB(217, 217, 217)

    ' --- 5. Data area (rows 9-508) ---
    ws.Range("A8:M508").Borders.LineStyle = xlContinuous
    ws.Range("A9:K508").Interior.Color = RGB(242, 242, 242)

    ' --- 6. Column widths (match HeyRoya template) ---
    ws.Columns("A").ColumnWidth = 14   ' work id
    ws.Columns("B").ColumnWidth = 28   ' title
    ws.Columns("C").ColumnWidth = 22   ' writer name
    ws.Columns("D").ColumnWidth = 14   ' writer ipi
    ws.Columns("E").ColumnWidth = 12   ' role code
    ws.Columns("F").ColumnWidth = 19   ' share percentage
    ws.Columns("G").ColumnWidth = 24   ' publisher name
    ws.Columns("H").ColumnWidth = 14   ' publisher ipi
    ws.Columns("I").ColumnWidth = 14   ' STIM
    ws.Columns("J").ColumnWidth = 18   ' iswc
    ws.Columns("K").ColumnWidth = 18   ' isrc
    ws.Columns("L").ColumnWidth = 28   ' corrected value
    ws.Columns("M").ColumnWidth = 32   ' notes

    ' --- 7. Freeze panes (lock title + instructions + header) ---
    ws.Range("A9").Select
    ActiveWindow.FreezePanes = True

    ' --- 8. Protection (only L and M editable) ---
    ws.Cells.Locked = True
    ws.Range("L9:M508").Locked = False
    ws.Protect Password:="kataloghub", AllowFiltering:=True

End Sub
