B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.8
@EndOfDesignText@
Sub Process_Globals
	Public connections As Map
End Sub

Public Sub Init
	'this map is accessed from other threads so it needs to be a thread safe map
	connections = Main.srvr.CreateThreadSafeMap
End Sub

Public Sub NewConnection(it As ImageTrans, name As String)
	connections.Put(name, it)
	Log("NewConnection: " & name)
End Sub

Private Sub GetImageTransInstances As List
	Dim keys As List
	keys.Initialize
	For Each key As String In connections.Keys
		keys.Add(key)
	Next
	keys.Sort(False)
	Dim instances As List
	instances.Initialize
	For Each key As String In keys
		instances.Add(connections.Get(key))
	Next
	Return instances
End Sub

Public Sub IsRunning(displayName As String) As Boolean
	For Each it As ImageTrans In GetImageTransInstances
		If it.getDisplayName == displayName Then
			Return it.getRunning
		End If
	Next
	If displayName == "" Or displayName == "default" Then
		For Each it As ImageTrans In GetImageTransInstances
			Return it.getRunning
		Next
	End If
	Return True
End Sub

Public Sub SetIsRunning(displayName As String,running As Boolean)
	For Each it As ImageTrans In GetImageTransInstances
		If it.getDisplayName == displayName Then
			it.setRunning(running)
			Return
		End If
	Next
	If displayName == "" Or displayName == "default" Then
		For Each it As ImageTrans In GetImageTransInstances
			it.setRunning(running)
			Return
		Next
	End If
End Sub


Public Sub IsPasswordCorrect(displayName As String, password As String) As Boolean
    If displayName <> "" And displayName <> "default" Then
		For Each it As ImageTrans In GetImageTransInstances
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

Public Sub Translate(displayName As String,src As String,sourceLang As String,targetLang As String,withoutImage As String,workflow As String,projectSettings As String,apis As String,template As String)
	Log("translate using "&displayName)
	Dim specifiedFound As Boolean = False
	Dim specifiedBusy As Boolean = False
	' Check if specified instance exists and whether it's running
	For Each it As ImageTrans In GetImageTransInstances
		If it.getDisplayName == displayName Then
			specifiedFound = True
			If it.getRunning == False Then
				' Specified instance is idle, mark as running immediately
				it.setRunning(True)
				CallSubDelayed2(it, "Translate",CreateMap("src":src,"sourceLang":sourceLang,"targetLang":targetLang,"withoutImage":withoutImage,"workflow":workflow,"projectSettings":projectSettings,"apis":apis,"template":template))
				Return
			Else
				specifiedBusy = True
			End If
			Exit
		End If
	Next
	' If specified instance is busy, try any non-running instance
	If specifiedFound And specifiedBusy Then
		For Each it As ImageTrans In GetImageTransInstances
			If it.getRunning == False Then
				Log("translate using idle instance: "&it.getDisplayName)
				it.setRunning(True)
				CallSubDelayed2(it, "Translate",CreateMap("src":src,"sourceLang":sourceLang,"targetLang":targetLang,"withoutImage":withoutImage,"workflow":workflow,"projectSettings":projectSettings,"apis":apis,"template":template))
				Return
			End If
		Next
		' All instances are running, fallback to specified instance even if busy
		For Each it As ImageTrans In GetImageTransInstances
			If it.getDisplayName == displayName Then
				Log("translate using specified instance (busy): "&displayName)
				it.setRunning(True)
				CallSubDelayed2(it, "Translate",CreateMap("src":src,"sourceLang":sourceLang,"targetLang":targetLang,"withoutImage":withoutImage,"workflow":workflow,"projectSettings":projectSettings,"apis":apis,"template":template))
				Return
			End If
		Next
	End If
	' Fallback for default/empty displayName
	If displayName == "" Or displayName == "default" Then
		For Each it As ImageTrans In GetImageTransInstances
			Log("translate using fallback")
			it.setRunning(True)
			CallSubDelayed2(it, "Translate",CreateMap("src":src,"sourceLang":sourceLang,"targetLang":targetLang,"withoutImage":withoutImage,"workflow":workflow,"projectSettings":projectSettings,"apis":apis,"template":template))
			Exit
		Next
	End If
End Sub

Public Sub TranslateRegion(displayName As String,filename As String,sourceLang As String,targetLang As String)
	Dim specifiedFound As Boolean = False
	Dim specifiedBusy As Boolean = False
	' Check if specified instance exists and whether it's running
	For Each it As ImageTrans In GetImageTransInstances
		If it.getDisplayName == displayName Then
			specifiedFound = True
			If it.getRunning == False Then
				' Specified instance is idle, mark as running immediately
				it.setRunning(True)
				CallSubDelayed2(it, "TranslateRegion", CreateMap("filename":filename,"sourceLang":sourceLang,"targetLang":targetLang))
				Return
			Else
				specifiedBusy = True
			End If
			Exit
		End If
	Next
	' If specified instance is busy, try any non-running instance
	If specifiedFound And specifiedBusy Then
		For Each it As ImageTrans In GetImageTransInstances
			If it.getRunning == False Then
				it.setRunning(True)
				CallSubDelayed2(it, "TranslateRegion",CreateMap("filename":filename,"sourceLang":sourceLang,"targetLang":targetLang))
				Return
			End If
		Next
		' All instances are running, fallback to specified instance even if busy
		For Each it As ImageTrans In GetImageTransInstances
			If it.getDisplayName == displayName Then
				it.setRunning(True)
				CallSubDelayed2(it, "TranslateRegion", CreateMap("filename":filename,"sourceLang":sourceLang,"targetLang":targetLang))
				Return
			End If
		Next
	End If
	' Fallback for default/empty displayName
	If displayName == "" Or displayName == "default" Then
		For Each it As ImageTrans In GetImageTransInstances
			it.setRunning(True)
			CallSubDelayed2(it, "TranslateRegion",CreateMap("filename":filename,"sourceLang":sourceLang,"targetLang":targetLang))
			Exit
		Next
	End If
End Sub

Public Sub Disconnect(it As ImageTrans, name As String)
	connections.Remove(name)
End Sub

Public Sub HasConnection As Boolean
	If connections.Size=0 Then
		Return False
	Else
		Return True
	End If
End Sub
