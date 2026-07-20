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
	resp.SetHeader("Access-Control-Allow-Private-Network","true")

	Dim result As Map
	result.Initialize
	result.Put("date", DateTime.Date(DateTime.Now))
	result.Put("total", ImageTransShared.GetTotalRequestCount)

	Dim ipMap As Map
	ipMap.Initialize
	Dim counts As Map = ImageTransShared.GetRequestCounts
	For Each ip As String In counts.Keys
		ipMap.Put(ip, counts.Get(ip))
	Next
	result.Put("ips", ipMap)

	Dim json As JSONGenerator
	json.Initialize(result)
	resp.ContentType="application/json"
	resp.Write(json.ToString)
End Sub
