On Error Resume Next

Set xl = CreateObject("Excel.Application")
If Err.Number <> 0 Then
    WScript.Echo "[Error] Could not start Excel."
    WScript.Quit 1
End If

xl.DisplayAlerts = False

csvFile = WScript.Arguments(0)
xlsxFile = WScript.Arguments(1)

Set wb = xl.Workbooks.Open(csvFile)
If Err.Number <> 0 Then
    WScript.Echo "[Error] Could not open CSV file: " & csvFile
    xl.Quit
    WScript.Quit 1
End If

wb.SaveAs xlsxFile, 51 ' 51 = XLSX format
If Err.Number <> 0 Then
    WScript.Echo "[Error] Could not save Excel file: " & xlsxFile
    wb.Close False
    xl.Quit
    WScript.Quit 1
End If

wb.Close False
xl.Quit
WScript.Echo "[OK] CSV converted to Excel successfully."
WScript.Quit 0
