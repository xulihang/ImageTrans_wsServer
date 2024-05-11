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
End Sub

Public Sub Initialize
	
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

Sub set_translated(map As Map)
	Main.translated=True
	Main.success=map.GetDefault("success",False)
	Main.outputPath=map.GetDefault("output","")
	Main.imgMap=map.GetDefault("imgMap",Null)
	Log(map)
End Sub

Sub close_server(map As Map)
	Log("shutting down")
	ExitApplication
End Sub

