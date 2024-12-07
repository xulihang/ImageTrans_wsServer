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
	Dim list1 As List
	list1.Initialize
	For Each key As String In connections.Keys
		Dim it As ImageTrans = connections.Get(key)
		Dim item As Map
		item.Initialize
		item.Put("name",key)
		item.Put("displayName",it.getDisplayName)
		item.Put("running",it.getRunning)
		list1.Add(item)
	Next
	Dim JSON As JSONGenerator
	JSON.Initialize2(list1)
	resp.ContentType="application/json"
	resp.Write(JSON.ToString)
End Sub