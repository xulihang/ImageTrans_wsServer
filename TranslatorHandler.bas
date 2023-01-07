B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Dim html As String = File.ReadString(File.DirAssets,"translator.html")
	resp.ContentType="text/html"
	resp.Write(html)
End Sub