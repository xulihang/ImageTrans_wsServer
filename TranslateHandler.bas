B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=7.8
@EndOfDesignText@
'Handler class
Sub Class_Globals
	
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
	Log(src)
	Dim saveToFile As String = req.GetParameter("saveToFile")
	If saveToFile="true" And src.StartsWith("data") Then
		Dim base64 As String
		base64 = Regex.Replace("data:(.*?);base64,",src,"")
		Log(base64)
		Dim su As StringUtils
		Dim path As String = File.Combine(File.DirTemp,DateTime.Now)
		File.WriteBytes(path,"",su.DecodeBase64(base64))
		src = path
	End If
	
	ImageTransShared.Translate(src)
	Dim returnType As String=req.GetParameter("type")
	Dim callback As String=req.GetParameter("callback")
	Main.translated=False
	WaitForTheTranslationToBeDone(resp,returnType,callback)
	StartMessageLoop
End Sub

Sub WaitForTheTranslationToBeDone(resp As ServletResponse,returnType As String,callback As String) 
	Dim result As Map
	result.Initialize
	Dim base64 As String
	Dim waited As Int=0
	Do While Main.translated=False
		Sleep(1000)
		waited=waited+1000
		If Main.success Then
			Dim su As StringUtils
			base64=su.EncodeBase64(File.ReadBytes(Main.outputPath,""))
			result.Put("success",True)
			result.Put("img",base64)
		Else
			result.Put("success",False)
		End If
		If waited>1000*240 Then 'timeout
			result.Put("success",False)
			Exit
		End If
	Loop
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