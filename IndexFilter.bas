B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
'Filter class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

'Return True to allow the request to proceed.
Public Sub Filter(req As ServletRequest, resp As ServletResponse) As Boolean
	If File.Exists(File.DirApp,"index.html") == False Then
		resp.SendRedirect("/index")
		Return False
	End If
	Return True
End Sub