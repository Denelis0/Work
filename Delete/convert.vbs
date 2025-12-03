On Error Resume Next

Set xl = CreateObject("Excel.Application")
If Err.Number <> 0 Then
    WScript.Echo "[Error] Could not start Excel."
    WScript.Quit 1
End If

xl.DisplayAlerts = False

src = WScript.Arguments(0)
dst = WScript.Arguments(1)

Set wb = xl.Workbooks.Open(src, False, True)
If Err.Number <> 0 Then
    WScript.Echo "[Error] Could not open file: " & src
    xl.Quit
    WScript.Quit 1
End If

wb.SaveAs dst, 6 ' 6 = CSV
If Err.Number <> 0 Then
    WScript.Echo "[Error] Could not save CSV to: " & dst
    wb.Close False
    xl.Quit
    WScript.Quit 1
End If

wb.Close False
xl.Quit
WScript.Echo "[OK] File converted successfully."
WScript.Quit 0
