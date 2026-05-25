<%@ WebHandler Language="VB" Class="TestWebhook" %>

Imports System.Web
Imports System.IO
Imports System.Text

Public Class TestWebhook : Implements IHttpHandler
    
    Public Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"
        
        Try
            ' Leer body
            Dim bodyStream As String = ""
            Using reader As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                bodyStream = reader.ReadToEnd()
            End Using
            
            ' Responder con éxito
            context.Response.StatusCode = 200
            context.Response.Write("{""test"":""ok"",""body_length"":" & bodyStream.Length & ",""message"":""Endpoint de prueba funcionando""}")
            
        Catch ex As Exception
            context.Response.StatusCode = 500
            context.Response.Write("{""error"":""" & ex.Message.Replace("""", "'") & """}")
        End Try
    End Sub
    
    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property
    
End Class
