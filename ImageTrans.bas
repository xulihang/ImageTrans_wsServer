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
End Sub

Public Sub Initialize
	
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

Public Sub Translate(src As String)
	ws.RunFunction("Translate",Array(src))
	ws.Flush
End Sub

Public Sub TranslateRegion(path As String)
	ws.RunFunction("TranslateRegion",Array(path))
	ws.Flush
End Sub

Sub set_translated(map As Map)
	Main.translated=True
	Main.success=map.GetDefault("success",False)
	Main.outputPath=map.GetDefault("output","")
	Main.imgMap=map.GetDefault("imgMap",Null)
	Main.regionMap=map.GetDefault("regionMap",Null)
End Sub

Sub set_name_and_password(map As Map)
	displayName=map.GetDefault("name",name)
	password=map.GetDefault("password","")
End Sub

Sub close_server(map As Map)
	Log("shutting down")
	ExitApplication
End Sub

