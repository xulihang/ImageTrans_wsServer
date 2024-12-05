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
				Dim successPart As Part = parts.GetDefault("success",Null)
				Dim success As Boolean = True
				If successPart.IsInitialized Then
					success = successPart.GetValue(req.CharacterEncoding)
				End If
				Dim messagePart As Part = parts.GetDefault("message",Null)
				Dim message As String
				If messagePart.IsInitialized Then
					message = messagePart.GetValue(req.CharacterEncoding)
				End If
				Dim filepart As Part = parts.GetDefault("file",Null)
				Dim name As String 
				Dim namePart As Part = parts.GetDefault("name",Null)
				If namePart.IsInitialized Then
					name = namePart.GetValue(req.CharacterEncoding)
				End If
				If name = "" Then
					name = "default"
				End If
				Dim imgMapPart As Part = parts.GetDefault("imgMap",Null)
				Dim regionMapPart As Part = parts.GetDefault("regionMap",Null)
				Dim imgMap As String
				If imgMapPart.IsInitialized Then
					imgMap = imgMapPart.GetValue(req.CharacterEncoding)
				End If
				Dim regionMap As String
				If regionMapPart.IsInitialized Then
					regionMap = regionMapPart.GetValue(req.CharacterEncoding)
				End If
				Dim resultMap As Map
				resultMap.Initialize
				resultMap.Put("translated",True)
				If filepart.IsInitialized Then
					resultMap.Put("path",filepart.TempFile)
				End If
				resultMap.Put("imgMapString",imgMap)
				resultMap.Put("regionMapString",regionMap)
				resultMap.Put("success",success)
				resultMap.Put("message",message)
				Main.translation.Put(name,resultMap)
				resp.Write("success")
			End If
		End If
	Catch
		resp.SendError(500, LastException)
	End Try
End Sub

