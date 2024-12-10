B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
'Handler class
Sub Class_Globals
	Private displayName As String
End Sub

Public Sub Initialize
	
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


Sub Handle(req As ServletRequest, resp As ServletResponse)
	resp.SetHeader("Access-Control-Allow-Origin","*")
	resp.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS, HEAD, DELETE, PUT")
	resp.setHeader("Access-Control-Max-Age", "3600")
	resp.setHeader("Access-Control-Allow-Headers", "Access-Control-Allow-Headers, Origin, Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers, Authorization, api_key")
	resp.SetHeader("Access-Control-Allow-Private-Network","true")
	If ImageTransShared.HasConnection=False Then
		resp.Write($"no imagetrans is connected"$)
		Return
	End If
	
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
	Dim base64 As String = req.GetParameter("base64")
	base64 = Regex.Replace("data:(.*?);base64,",base64,"")
	Dim su As StringUtils
	Dim filename As String = DateTime.Now
	Dim path As String = File.Combine(File.Combine(File.DirApp,"tmp"),filename)
	File.WriteBytes(path,"",su.DecodeBase64(base64))
	Main.translation.Put(displayName,CreateMap("translated":False))
	If Main.IsLocalNetwork(req.RemoteAddress) Then
		ImageTransShared.TranslateRegion(displayName,path,sourceLang,targetLang)
	Else
		ImageTransShared.TranslateRegion(displayName,filename,sourceLang,targetLang)
	End If
	WaitForTheTranslationToBeDone(resp)
	StartMessageLoop
End Sub


Sub WaitForTheTranslationToBeDone(resp As ServletResponse)
	Dim result As Map
	result.Initialize
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
		Dim regionMapString As String = map1.Get("regionMapString")
		If regionMapString <> "" Then
			Dim jsonP As JSONParser
			jsonP.Initialize(regionMapString)
			Dim regionMap As Map = jsonP.NextObject
			result.Put("regionMap", regionMap)
		End If
		result.Put("success",True)
	Else
	    result.Put("success",False)
	End If
	
	Main.translation.Remove(displayName)
	Dim json As JSONGenerator
	json.Initialize(result)
	resp.ContentType="application/json"
	resp.Write(json.ToString)
	StopMessageLoop
End Sub