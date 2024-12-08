B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
'WebSocket class
Sub Class_Globals
	Private ws As WebSocket
	Private name As String
	Private displayName As String
	Private password As String
	Private running As Boolean
End Sub

Public Sub Initialize
	
End Sub

Public Sub getName As String
	Return name
End Sub

Public Sub getRunning As Boolean
	Return running
End Sub

Public Sub getDisplayName As String
	Return displayName
End Sub

Public Sub getPassword As String
	Return password
End Sub

Private Sub WebSocket_Connected (WebSocket1 As WebSocket)
	ws = WebSocket1
	Log("new connection")
	name=DateTime.Now
	CallSubDelayed3(ImageTransShared, "NewConnection", Me, name)
End Sub

Private Sub WebSocket_Disconnected
	CallSubDelayed3(ImageTransShared, "Disconnect", Me, name)
End Sub

Public Sub Translate(map1 As Map)
	Dim src As String = map1.GetDefault("src","")
	Dim sourceLang As String = map1.GetDefault("sourceLang","")
	Dim targetLang As String = map1.GetDefault("targetLang","")
	Dim withoutImage As String = map1.GetDefault("withoutImage","")
	ws.RunFunction("Translate",Array(src,sourceLang,targetLang,withoutImage))
	ws.Flush
End Sub

Public Sub TranslateRegion(map1 As Map)
	Dim path As String = map1.GetDefault("filename","")
	Dim sourceLang As String = map1.GetDefault("sourceLang","")
	Dim targetLang As String = map1.GetDefault("targetLang","")
	ws.RunFunction("TranslateRegion",Array(path,sourceLang,targetLang))
	ws.Flush
End Sub

Sub set_translated(map As Map)
	Log("set_translated")
	Log(map)
	Dim resultMap As Map
	resultMap.Initialize
	resultMap.Put("success",map.GetDefault("success",False))
	resultMap.Put("translated",True)
	resultMap.Put("path",map.GetDefault("output",""))
	If map.ContainsKey("imgMap") Then
		Dim imgMap As Map = map.Get("imgMap")
		Dim jsonG As JSONGenerator
		jsonG.Initialize(imgMap)
		resultMap.Put("imgMapString",jsonG.ToString)
	End If
	If map.ContainsKey("regionMap") Then
		Dim regionMap As Map = map.Get("regionMap")
		Dim jsonG As JSONGenerator
		jsonG.Initialize(regionMap)
		resultMap.Put("regionMapString",jsonG.ToString)
	End If
	If displayName = "" Then
		Main.translation.Put("default",resultMap)
	Else
		If Main.translation.ContainsKey(displayName) Then
			Main.translation.Put(displayName,resultMap)
		Else
			Main.translation.Put("default",resultMap)
		End If
	End If
End Sub

Sub set_name_and_password(map As Map)
	displayName=map.GetDefault("name",name)
	password=map.GetDefault("password","")
End Sub

Sub set_running(map As Map)
	running = map.GetDefault("running",False)
End Sub

Sub close_server(map As Map)
	If File.Exists(File.DirApp,"shutdownoff") Then
		Return
	End If
	Log("shutting down")
	ExitApplication
End Sub

