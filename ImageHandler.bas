B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Try
		If req.Method == "POST" Then
			'upload translated image
			If req.ContentType.StartsWith("multipart/form-data") Then
				Dim parts As Map = req.GetMultipartData(File.DirApp & "/tmp", 10000000)
				Dim filepart As Part = parts.GetDefault("file",Null)
				Dim name As String = req.GetParameter("name")
				Dim imgMap As String = req.GetParameter("imgMap")
				Dim regionMap As String = req.GetParameter("regionMap")
				Dim resultMap As Map
				resultMap.Initialize
				resultMap.Put("translated",True)
				If filepart.IsInitialized Then
					resultMap.Put("path",filepart.TempFile)
				End If
				resultMap.Put("imgMapString",imgMap)
				resultMap.Put("regionMapString",regionMap)
				Main.translation.Put(name,resultMap)
				resp.Write("success")
			End If
		End If
	Catch
		resp.SendError(500, LastException)
	End Try
End Sub

