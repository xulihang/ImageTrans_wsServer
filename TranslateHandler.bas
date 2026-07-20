B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
'Handler class
Sub Class_Globals
	Private displayName As String
	Private uniqueKey As String
	Private clientIP As String
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

	clientIP = req.RemoteAddress

	If File.Exists(File.DirApp, "public") Then
		If ImageTransShared.GetRequestCount(clientIP) > 20 Then
			Dim su As StringUtils
			Dim warningBase64 As String = su.EncodeBase64(File.ReadBytes(File.DirAssets,"warning.jpg"))
			Dim limitResult As Map
			limitResult.Initialize
			limitResult.Put("success",True)
			limitResult.Put("img",warningBase64)
			Dim imgMap As Map
			imgMap.Initialize
			Dim boxes As List
			boxes.Initialize
			Dim box As Map
			box.Initialize
			box.Put("text","Daily limit exceeded (20 images/IP). Purchase ImageTrans to host your own server.")
			box.Put("target","")
			Dim geometry As Map
			geometry.Initialize
			geometry.Put("X",21)
			geometry.Put("Y",54)
			geometry.Put("width",218)
			geometry.Put("height",133)
			box.Put("geometry",geometry)
			boxes.Add(box)
			imgMap.Put("boxes",boxes)
			limitResult.Put("imgMap",imgMap)
			Dim json As JSONGenerator
			json.Initialize(limitResult)
			resp.ContentType="application/json"
			Log("rate limit response size: " & json.ToString.Length)
			resp.Write(json.ToString)
			Log("rate limit response sent")
			Return
		End If
	End If

	Dim src As String = req.GetParameter("src")

	displayName = req.GetParameter("displayName")
	If displayName = "" Then
		displayName = "default"
	End If

	Dim password As String = req.GetParameter("password")
	Dim sourceLang As String = req.GetParameter("sourceLang")
	Dim projectSettings As String = req.GetParameter("projectSettings")
	Dim apis As String = req.GetParameter("apis")
	Dim template As String = req.GetParameter("template")
	Dim workflow As String = req.GetParameter("workflow")
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
	uniqueKey = displayName & "_" & DateTime.Now & "_" & Rnd(0, 99999999)
	Main.translation.Put(uniqueKey,CreateMap("translated":False))

	Dim dispatchedTo As String
	If filename <> "" Then
		If Main.IsLocalNetwork(req.RemoteAddress) Then
			dispatchedTo = ImageTransShared.Translate(displayName,src,sourceLang,targetLang,withoutImage,workflow,projectSettings,apis,template,password,uniqueKey)
		Else
			dispatchedTo = ImageTransShared.Translate(displayName,filename,sourceLang,targetLang,withoutImage,workflow,projectSettings,apis,template,password,uniqueKey)
		End If
	Else
		dispatchedTo = ImageTransShared.Translate(displayName,src,sourceLang,targetLang,withoutImage,workflow,projectSettings,apis,template,password,uniqueKey)
	End If
	If dispatchedTo = "" Then
		Main.translation.Remove(uniqueKey)
		resp.Write($"all instances are busy"$)
		Return
	End If
	displayName = dispatchedTo

	Log(Main.translation)
	Dim returnType As String=req.GetParameter("type")
	Dim callback As String=req.GetParameter("callback")

	WaitForTheTranslationToBeDone(resp,returnType,callback)
	StartMessageLoop
End Sub

Private Sub ImageTranslated As Boolean
	If Main.translation.ContainsKey(uniqueKey) Then
		Dim map1 As Map = Main.translation.Get(uniqueKey)
		If map1.GetDefault("translated",False) Then
			Return True
		End If
		Return False
	End If
	Return True
End Sub

Private Sub ImageTranslationFailed As Boolean
	If Main.translation.ContainsKey(uniqueKey) Then
		Dim map1 As Map = Main.translation.Get(uniqueKey)
		Return Not(map1.GetDefault("success",True))
	End If
	Return False
End Sub

Private Sub ImageTranslationMessage As String
	If Main.translation.ContainsKey(uniqueKey) Then
		Dim map1 As Map = Main.translation.Get(uniqueKey)
		Return map1.GetDefault("message","")
	End If
	Return ""
End Sub

Sub WaitForTheTranslationToBeDone(resp As ServletResponse,returnType As String,callback As String)
	Dim result As Map
	result.Initialize
	Dim base64 As String
	Dim waited As Int=0
	Dim idleCount As Int=0
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

		If ImageTransShared.IsRunning(displayName) = False And ImageTransShared.IsInstanceBusy(displayName) = False Then
			idleCount = idleCount + 1
			If idleCount >= 10 Then
				result.Put("message","instance stopped")
				result.Put("success",False)
				success = False
				Exit
			End If
		Else
			idleCount = 0
		End If

		If waited>1000*240 Then 'timeout
			result.Put("message","timeout")
			result.Put("success",False)
			success = False
			Exit
		End If
	Loop

	If success Then
		Dim map1 As Map = Main.translation.Get(uniqueKey)
		If map1.GetDefault("translated",False) Then
			ImageTransShared.IncrementRequestCount(clientIP)
			Dim imgMapString As String = map1.GetDefault("imgMapString","")
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
			result.Put("message","translation did not complete")
		End If
	Else
		result.Put("success",False)
	End If

	ImageTransShared.SetIsRunning(displayName,False)
	Main.translation.Remove(uniqueKey)
	ImageTransShared.RemoveCurrentRequestKey(displayName)
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
