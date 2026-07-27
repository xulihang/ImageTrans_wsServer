B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=7.8
@EndOfDesignText@
Sub Process_Globals
	Public connections As Map
	Public requestKeyMap As Map
	Private busyInstances As JavaObject
	Public ipRequestCount As Map
	Private pendingRequests As Map
	Private failedInstances As JavaObject
	Public reDispatched As Map
End Sub

Public Sub Init
	'this map is accessed from other threads so it needs to be a thread safe map
	connections = Main.srvr.CreateThreadSafeMap
	requestKeyMap = Main.srvr.CreateThreadSafeMap
	ipRequestCount = Main.srvr.CreateThreadSafeMap
	pendingRequests = Main.srvr.CreateThreadSafeMap
	reDispatched = Main.srvr.CreateThreadSafeMap
	busyInstances.InitializeNewInstance("java.util.concurrent.ConcurrentHashMap", Null)
	failedInstances.InitializeNewInstance("java.util.concurrent.ConcurrentHashMap", Null)
End Sub

' Atomically marks an instance as busy. Returns True if it was idle and now marked, False if already busy.
Private Sub TryMarkBusy(instanceName As String) As Boolean
	Dim result As Object = busyInstances.RunMethod("putIfAbsent", Array(instanceName, True))
	Return result = Null
End Sub

Public Sub MarkIdle(instanceName As String)
	busyInstances.RunMethod("remove", Array(instanceName))
End Sub

Public Sub IsInstanceBusy(instanceName As String) As Boolean
	Return busyInstances.RunMethod("containsKey", Array(instanceName))
End Sub

Public Sub HasActiveRequest(instanceName As String) As Boolean
	Return requestKeyMap.ContainsKey(instanceName)
End Sub

Private Sub IsInstanceInCooldown(instanceName As String) As Boolean
	If failedInstances.RunMethod("containsKey", Array(instanceName)) Then
		Dim lastFailure As Long = failedInstances.RunMethod("get", Array(instanceName))
		If DateTime.Now - lastFailure < 60 * 1000 Then
			Return True
		End If
		failedInstances.RunMethod("remove", Array(instanceName))
	End If
	Return False
End Sub

Public Sub RecordFailure(instanceName As String)
	failedInstances.RunMethod("put", Array(instanceName, DateTime.Now))
End Sub

Public Sub SetCurrentRequestKey(instanceName As String, requestKey As String)
	requestKeyMap.Put(instanceName, requestKey)
End Sub

Public Sub GetCurrentRequestKey(instanceName As String) As String
	Dim key As String = requestKeyMap.GetDefault(instanceName, "")
	If key = "" Then
		Return instanceName
	End If
	Return key
End Sub

Public Sub RemoveCurrentRequestKey(instanceName As String)
	requestKeyMap.Remove(instanceName)
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
	If running = False Then
		MarkIdle(displayName)
	End If
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


Public Sub HasPassword(displayName As String) As Boolean
	If displayName <> "" And displayName <> "default" Then
		For Each it As ImageTrans In GetImageTransInstances
			If it.getDisplayName == displayName Then
				If it.getPassword <> "" Then
					Return True
				End If
				Return False
			End If
		Next
	End If
	Return False
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

Public Sub GetReDispatchedName(originalName As String) As String
	Return reDispatched.GetDefault(originalName, "")
End Sub

Public Sub TryReDispatch(failedName As String) As String
	If pendingRequests.ContainsKey(failedName) = False Then
		Log("TryReDispatch: no pending request for " & failedName)
		Return ""
	End If
	Dim params As Map = pendingRequests.Get(failedName)
	Dim requestKey As String = params.Get("requestKey")
	Dim password As String = params.GetDefault("password", "")
	Dim dispatchTime As Long = params.GetDefault("dispatchTime", DateTime.Now)
	If DateTime.Now - dispatchTime > 3 * 1000 Then
		Log("TryReDispatch: task ran too long before failing, skip re-dispatch")
		pendingRequests.Remove(failedName)
		Return ""
	End If
	Dim isRegion As Boolean = params.GetDefault("isRegion", False)
	Dim isPublic As Boolean = File.Exists(File.DirApp, "public")

	For Each it As ImageTrans In GetImageTransInstances
		If it.getDisplayName <> failedName Then
			If (isPublic = False Or it.getDisplayName.StartsWith("default")) Then
				If IsInstanceInCooldown(it.getDisplayName) = False Then
					If TryMarkBusy(it.getDisplayName) Then
						If password = "" Or password = it.getPassword Then
							Log("re-dispatching from " & failedName & " to " & it.getDisplayName)
							SetCurrentRequestKey(it.getDisplayName, requestKey)
							RemoveCurrentRequestKey(failedName)
							reDispatched.Put(failedName, it.getDisplayName)
							If isRegion Then
								CallSubDelayed2(it, "TranslateRegion", CreateMap("filename":params.Get("filename"),"sourceLang":params.Get("sourceLang"),"targetLang":params.Get("targetLang")))
							Else
								CallSubDelayed2(it, "Translate", CreateMap("src":params.Get("src"),"sourceLang":params.Get("sourceLang"),"targetLang":params.Get("targetLang"),"withoutImage":params.Get("withoutImage"),"workflow":params.Get("workflow"),"projectSettings":params.Get("projectSettings"),"apis":params.Get("apis"),"template":params.Get("template")))
							End If
							pendingRequests.Remove(failedName)
							Return it.getDisplayName
						Else
							MarkIdle(it.getDisplayName)
						End If
					End If
				End If
			End If
		End If
	Next

	Log("TryReDispatch: no idle instance available for re-dispatch")
	pendingRequests.Remove(failedName)
	Return ""
End Sub

Public Sub Translate(displayName As String,src As String,sourceLang As String,targetLang As String,withoutImage As String,workflow As String,projectSettings As String,apis As String,template As String,password As String,requestKey As String) As String
	Log("translate using "&displayName)
	Dim isPublic As Boolean = File.Exists(File.DirApp, "public")
	Dim specifiedFound As Boolean = False
	Dim specifiedBusy As Boolean = False
	' Check if specified instance exists, password matches, and whether it's running
	For Each it As ImageTrans In GetImageTransInstances
		If it.getDisplayName == displayName Then
			specifiedFound = True
			If password <> it.getPassword Then
				Log("password incorrect for "&displayName)
				Return ""
			End If
			If IsInstanceInCooldown(it.getDisplayName) Then
				Log("skipping " & it.getDisplayName & " (in cooldown)")
			End If
			If IsInstanceInCooldown(it.getDisplayName) = False And TryMarkBusy(it.getDisplayName) Then
				StoreRequest(it.getDisplayName, src, sourceLang, targetLang, withoutImage, workflow, projectSettings, apis, template, password, requestKey, False, "")
				SetCurrentRequestKey(it.getDisplayName, requestKey)
				CallSubDelayed2(it, "Translate",CreateMap("src":src,"sourceLang":sourceLang,"targetLang":targetLang,"withoutImage":withoutImage,"workflow":workflow,"projectSettings":projectSettings,"apis":apis,"template":template))
				Return it.getDisplayName
			Else
				specifiedBusy = True
			End If
			Exit
		End If
	Next
	' If specified instance is busy, try any idle instance (public: only default-prefixed)
	If specifiedFound And specifiedBusy And password = "" Then
		For Each it As ImageTrans In GetImageTransInstances
			If IsInstanceInCooldown(it.getDisplayName) Then
				Log("skipping " & it.getDisplayName & " (in cooldown)")
			End If
			If (isPublic = False Or it.getDisplayName.StartsWith("default")) And IsInstanceInCooldown(it.getDisplayName) = False And TryMarkBusy(it.getDisplayName) Then
				If password = it.getPassword Then
					Log("translate using idle instance: "&it.getDisplayName)
					StoreRequest(it.getDisplayName, src, sourceLang, targetLang, withoutImage, workflow, projectSettings, apis, template, password, requestKey, False, "")
					SetCurrentRequestKey(it.getDisplayName, requestKey)
					CallSubDelayed2(it, "Translate",CreateMap("src":src,"sourceLang":sourceLang,"targetLang":targetLang,"withoutImage":withoutImage,"workflow":workflow,"projectSettings":projectSettings,"apis":apis,"template":template))
					Return it.getDisplayName
				Else
					MarkIdle(it.getDisplayName)
				End If
			End If
		Next
		Log("all instances are busy")
		Return ""
	End If
	' Fallback for default/empty displayName (public: only default-prefixed)
	If (displayName == "" Or displayName == "default") And password = "" Then
		For Each it As ImageTrans In GetImageTransInstances
			If IsInstanceInCooldown(it.getDisplayName) Then
				Log("skipping " & it.getDisplayName & " (in cooldown)")
			End If
			If (isPublic = False Or it.getDisplayName.StartsWith("default")) And IsInstanceInCooldown(it.getDisplayName) = False And TryMarkBusy(it.getDisplayName) Then
				If password = it.getPassword Then
					Log("translate using fallback")
					StoreRequest(it.getDisplayName, src, sourceLang, targetLang, withoutImage, workflow, projectSettings, apis, template, password, requestKey, False, "")
					SetCurrentRequestKey(it.getDisplayName, requestKey)
					CallSubDelayed2(it, "Translate",CreateMap("src":src,"sourceLang":sourceLang,"targetLang":targetLang,"withoutImage":withoutImage,"workflow":workflow,"projectSettings":projectSettings,"apis":apis,"template":template))
					Return it.getDisplayName
				Else
					MarkIdle(it.getDisplayName)
				End If
			End If
		Next
		Log("all instances are busy")
		Return ""
	End If
	Return ""
End Sub

Public Sub TranslateRegion(displayName As String,filename As String,sourceLang As String,targetLang As String,password As String,requestKey As String) As String
	Dim isPublic As Boolean = File.Exists(File.DirApp, "public")
	Dim specifiedFound As Boolean = False
	Dim specifiedBusy As Boolean = False
	' Check if specified instance exists, password matches, and whether it's running
	For Each it As ImageTrans In GetImageTransInstances
		If it.getDisplayName == displayName Then
			specifiedFound = True
			If password <> it.getPassword Then
				Log("password incorrect for "&displayName)
				Return ""
			End If
			If IsInstanceInCooldown(it.getDisplayName) = False And TryMarkBusy(it.getDisplayName) Then
				StoreRequest(it.getDisplayName, "", sourceLang, targetLang, "", "", "", "", "", password, requestKey, True, filename)
				SetCurrentRequestKey(it.getDisplayName, requestKey)
				CallSubDelayed2(it, "TranslateRegion", CreateMap("filename":filename,"sourceLang":sourceLang,"targetLang":targetLang))
				Return it.getDisplayName
			Else
				specifiedBusy = True
			End If
			Exit
		End If
	Next
	' If specified instance is busy, try any idle instance (public: only default-prefixed)
	If specifiedFound And specifiedBusy And password = "" Then
		For Each it As ImageTrans In GetImageTransInstances
			If (isPublic = False Or it.getDisplayName.StartsWith("default")) And IsInstanceInCooldown(it.getDisplayName) = False And TryMarkBusy(it.getDisplayName) Then
				If password = it.getPassword Then
					StoreRequest(it.getDisplayName, "", sourceLang, targetLang, "", "", "", "", "", password, requestKey, True, filename)
					SetCurrentRequestKey(it.getDisplayName, requestKey)
					CallSubDelayed2(it, "TranslateRegion",CreateMap("filename":filename,"sourceLang":sourceLang,"targetLang":targetLang))
					Return it.getDisplayName
				Else
					MarkIdle(it.getDisplayName)
				End If
			End If
		Next
		Log("all instances are busy")
		Return ""
	End If
	' Fallback for default/empty displayName (public: only default-prefixed)
	If (displayName == "" Or displayName == "default") And password = "" Then
		For Each it As ImageTrans In GetImageTransInstances
			If (isPublic = False Or it.getDisplayName.StartsWith("default")) And IsInstanceInCooldown(it.getDisplayName) = False And TryMarkBusy(it.getDisplayName) Then
				If password = it.getPassword Then
					StoreRequest(it.getDisplayName, "", sourceLang, targetLang, "", "", "", "", "", password, requestKey, True, filename)
					SetCurrentRequestKey(it.getDisplayName, requestKey)
					CallSubDelayed2(it, "TranslateRegion",CreateMap("filename":filename,"sourceLang":sourceLang,"targetLang":targetLang))
					Return it.getDisplayName
				Else
					MarkIdle(it.getDisplayName)
				End If
			End If
		Next
		Log("all instances are busy")
		Return ""
	End If
	Return ""
End Sub

Private Sub StoreRequest(instanceName As String, src As String, sourceLang As String, targetLang As String, withoutImage As String, workflow As String, projectSettings As String, apis As String, template As String, password As String, requestKey As String, isRegion As Boolean, filename As String)
	Dim params As Map
	params.Initialize
	params.Put("src", src)
	params.Put("sourceLang", sourceLang)
	params.Put("targetLang", targetLang)
	params.Put("withoutImage", withoutImage)
	params.Put("workflow", workflow)
	params.Put("projectSettings", projectSettings)
	params.Put("apis", apis)
	params.Put("template", template)
	params.Put("password", password)
	params.Put("requestKey", requestKey)
	params.Put("isRegion", isRegion)
	params.Put("filename", filename)
	params.Put("dispatchTime", DateTime.Now)
	pendingRequests.Put(instanceName, params)
End Sub

Public Sub Disconnect(it As ImageTrans, name As String)
	connections.Remove(name)
End Sub

Public Sub GetWsSecret As String
	If File.Exists(File.DirApp, "ws_secret") Then
		Return File.ReadString(File.DirApp, "ws_secret").Trim
	End If
	Return ""
End Sub

Public Sub HasConnection As Boolean
	If connections.Size=0 Then
		Return False
	Else
		Return True
	End If
End Sub

Public Sub IncrementRequestCount(ip As String)
	Dim currentCount As Int = ipRequestCount.GetDefault(ip, 0)
	ipRequestCount.Put(ip, currentCount + 1)
End Sub

Public Sub GetRequestCounts As Map
	Return ipRequestCount
End Sub

Public Sub GetTotalRequestCount As Int
	Dim total As Int = 0
	For Each count As Int In ipRequestCount.Values
		total = total + count
	Next
	Return total
End Sub

Public Sub GetRequestCount(ip As String) As Int
	Return ipRequestCount.GetDefault(ip, 0)
End Sub

Public Sub ClearRequestCounts
	ipRequestCount.Clear
End Sub
