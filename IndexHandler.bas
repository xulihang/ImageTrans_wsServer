B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Dim html As String = File.ReadString(File.DirAssets,"index.html")
	resp.ContentType="text/html"
	resp.Write(html)
End Sub