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

Public Sub GetConnections As Map
	Return connections
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


Public Sub IsPasswordCorrect(displayName As String, password As String) As Boolean
    If displayName <> "" And displayName <> "default" Then
		For Each it As ImageTrans In connections.Values		
			If it.getDisplayName == displayName Then
				If password == it.getPassword Then
			  		Return True
			    Else
					Return False
                End If
			End If
		Next
	End If
	Return True
End Sub

Public Sub Translate(displayName As String,src As String)
	For Each it As ImageTrans In connections.Values
        If displayName <> "" And displayName <> "default" Then
			If it.getDisplayName == displayName Then
				CallSubDelayed2(it, "Translate",src)
				Exit
			End If
		Else
			CallSubDelayed2(it, "Translate",src)
			Exit
        End If
	Next
End Sub

Public Sub TranslateRegion(displayName As String,filename As String)
	For Each it As ImageTrans In connections.Values
		If displayName <> "" And displayName <> "default" Then
			If it.getDisplayName == displayName Then
				CallSubDelayed2(it, "TranslateRegion", filename)
				Exit
			End If
		Else
			CallSubDelayed2(it, "TranslateRegion",filename)
			Exit
		End If
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
		Return True
	End If
End Sub
