B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.8
@EndOfDesignText@
Sub Process_Globals
	Public AvoidDuplicates As Map
	Private connections As Map
	Private LastMessages As List
End Sub

Public Sub Init
	'this map is accessed from other threads so it needs to be a thread safe map
	AvoidDuplicates = Main.srvr.CreateThreadSafeMap
	connections.Initialize
	LastMessages.Initialize
End Sub

Public Sub NewConnection(it As ImageTrans, name As String)
	connections.Put(name, it)
	Log("NewConnection: " & name)
End Sub

Public Sub Translated(result As Boolean)
	Log(connections.Size)
	For Each it As ImageTrans In connections.Values
		CallSubDelayed2(it, "Translated",result)
	Next
End Sub

Public Sub Translate(src As String)
	Log(connections.Size)
	For Each it As ImageTrans In connections.Values
		CallSubDelayed2(it, "Translate",src)
		Exit
	Next
End Sub

Public Sub Disconnect(it As ImageTrans, name As String)
	If connections.ContainsKey(name) = False Or connections.Get(name) <> it Then Return
	connections.Remove(name)
	AvoidDuplicates.Remove(name.ToLowerCase)
End Sub

Public Sub HasConnection As Boolean
	If connections.Size=0 Then
		Return False
	Else
		return True
	End If
End Sub
