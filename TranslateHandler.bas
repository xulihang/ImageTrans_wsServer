B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
'Handler class
Sub Class_Globals
	Private displayName As String
End Sub

Public Sub Initialize
	
End Sub

Sub Handle(req As ServletRequest, resp As ServletResponse)
	Log("new translation connection")
	resp.SetHeader("Access-Control-Allow-Origin","*")
	resp.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS, HEAD, DELETE, PUT")
	resp.setHeader("Access-Control-Max-Age", "3600")
	resp.setHeader("Access-Control-Allow-Headers", "Access-Control-Allow-Headers, Origin, Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers, Authorization, api_key")
	resp.SetHeader("Access-Control-Allow-Private-Network","true")
	If ImageTransShared.HasConnection=False Then
		resp.Write($"no imagetrans is connected"$)
		Return
	End If
	
	Dim src As String = req.GetParameter("src")

	displayName = req.GetParameter("displayName")
	If displayName = "" Then
		displayName = "default"
	End If
	
	If ImageTransShared.IsRunning(displayName) Then
		resp.Write($"This instance of ImageTrans is processing or does not exist."$)
		Return
	End If
	Dim password As String = req.GetParameter("password")
	If ImageTransShared.IsPasswordCorrect(displayName,password) == False Then
		resp.Write($"Password incorrect."$)
		Return
	End If
	Dim sourceLang As String = req.GetParameter("sourceLang")
	Dim targetLang As String = req.GetParameter("targetLang")
	Dim saveToFile As String = req.GetParameter("saveToFile")
	Dim withoutImage As String = req.GetParameter("withoutImage")
	Dim filename As String
	If saveToFile="true" And src.StartsWith("data") Then
		Dim base64 As String
		base64 = Regex.Replace("data:(.*?);base64,",src,"")
		Dim su As StringUtils
		filename = DateTime.Now
		Dim path As String = File.Combine(File.Combine(File.DirApp,"tmp"),filename)
		File.WriteBytes(path,"",su.DecodeBase64(base64))
		src = path
	End If
	Log("translate handler")
	Main.translation.Put(displayName,CreateMap("translated":False))
	
	If filename <> "" Then
		If Main.IsLocalNetwork(req.RemoteAddress) Then
			ImageTransShared.Translate(displayName,src,sourceLang,targetLang,withoutImage)
		Else
			ImageTransShared.Translate(displayName,filename,sourceLang,targetLang,withoutImage)
		End If
	Else
		ImageTransShared.Translate(displayName,src,sourceLang,targetLang,withoutImage)
	End If
	
	Log(Main.translation)
	Dim returnType As String=req.GetParameter("type")
	Dim callback As String=req.GetParameter("callback")
	
	WaitForTheTranslationToBeDone(resp,returnType,callback)
	StartMessageLoop
End Sub

Private Sub ImageTranslated As Boolean
	If Main.translation.ContainsKey(displayName) Then
		Dim map1 As Map = Main.translation.Get(displayName)
		Return map1.GetDefault("translated",False)
	End If
	Return True
End Sub

Private Sub ImageTranslationFailed As Boolean
	If Main.translation.ContainsKey(displayName) Then
		Dim map1 As Map = Main.translation.Get(displayName)
		Return Not(map1.GetDefault("success",True))
	End If
	Return False
End Sub

Private Sub ImageTranslationMessage As String
	If Main.translation.ContainsKey(displayName) Then
		Dim map1 As Map = Main.translation.Get(displayName)
		Return map1.GetDefault("message","")
	End If
	Return ""
End Sub

Sub WaitForTheTranslationToBeDone(resp As ServletResponse,returnType As String,callback As String) 
	Dim result As Map
	result.Initialize
	Dim base64 As String
	Dim waited As Int=0
	Dim success As Boolean = True
	Do While ImageTranslated=False
		Sleep(1000)
		waited=waited+1000
		
		If ImageTranslationFailed Then
			result.Put("message",ImageTranslationMessage)
			result.Put("success",False)
			success = False
			Exit
		End If
		
		If waited>1000*240 Then 'timeout
			result.Put("message","timeout")
			result.Put("success",False)
			success = False
			Exit
		End If
	Loop
	
	If success Then
		Dim map1 As Map = Main.translation.Get(displayName)
		
		Dim imgMapString As String = map1.Get("imgMapString")
		
		result.Put("success",True)
		
		If map1.ContainsKey("path") Then
			Dim imgPath As String = map1.Get("path")
			Dim su As StringUtils
			base64=su.EncodeBase64(File.ReadBytes(imgPath,""))
			result.Put("img",base64)
			File.Delete(imgPath,"")
		End If
		
		If imgMapString <> "" Then
			Dim jsonP As JSONParser
			jsonP.Initialize(imgMapString)
			Dim imgMap As Map = jsonP.NextObject
			result.Put("imgMap", imgMap)
		End If
		
	Else
		result.Put("success",False)
	End If
	
	Main.translation.Remove(displayName)
	If returnType="html" Then
		resp.ContentType="text/html"
		resp.Write($"<img src="data:image/jpeg;base64,${base64}"  alt="result" />"$)
	Else
		Dim json As JSONGenerator
		json.Initialize(result)
		If callback<>"" Then
			resp.ContentType="text/html"
			resp.Write(callback&$"(${json.ToString})"$)
		Else
			resp.ContentType="application/json"
			resp.Write(json.ToString)
		End If
	End If
	StopMessageLoop
End Sub