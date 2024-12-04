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
	Dim connections As Map = ImageTransShared.GetConnections
	Dim JSON As JSONGenerator
	JSON.Initialize(connections)
	resp.ContentType="application/json"
	resp.Write(JSON.ToString)
End Sub