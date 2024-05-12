B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.8
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
End Sub

Public Sub Initialize
	
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
	Dim base64 As String = req.GetParameter("base64")
	base64 = Regex.Replace("data:(.*?);base64,",base64,"")
	Dim su As StringUtils
	Dim path As String = File.Combine(File.DirTemp,DateTime.Now)
	File.WriteBytes(path,"",su.DecodeBase64(base64))
	ImageTransShared.TranslateRegion(path)
	Main.translated=False
	WaitForTheTranslationToBeDone(resp)
	StartMessageLoop
End Sub


Sub WaitForTheTranslationToBeDone(resp As ServletResponse)
	Dim result As Map
	result.Initialize
	Dim waited As Int=0
	Do While Main.translated=False
		Sleep(1000)
		waited=waited+1000
		If Main.success Then
			result.Put("success",True)
			If Main.regionMap.IsInitialized Then
				result.Put("regionMap",Main.regionMap)
			End If
		Else
			result.Put("success",False)
		End If
		If waited>1000*240 Then 'timeout
			result.Put("success",False)
			Exit
		End If
	Loop
	Dim json As JSONGenerator
	json.Initialize(result)
	resp.ContentType="application/json"
	resp.Write(json.ToString)
	StopMessageLoop
End Sub