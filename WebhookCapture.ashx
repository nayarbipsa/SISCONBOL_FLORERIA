<%@ WebHandler Language="VB" Class="WebhookCapture" %>

Imports System.Web
Imports System.IO
Imports System.Text
Imports System.Data.SqlClient
Imports System.Configuration

Public Class WebhookCapture : Implements IHttpHandler
    
    Public Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"
        
        Try
            ' Leer el body
            Dim bodyStream As String = ""
            Using reader As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                bodyStream = reader.ReadToEnd()
            End Using
            
            ' Leer todos los headers
            Dim headers As String = ""
            For Each key As String In context.Request.Headers.AllKeys
                headers &= key & ": " & context.Request.Headers(key) & vbCrLf
            Next
            
            ' Guardar en base de datos
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("INSERT INTO FLORERIA_Webhook_Log (tipo, payload, mensaje, ip_origen, fecha) VALUES (@tipo, @payload, @msg, @ip, GETDATE())", conn)
                    cmd.Parameters.AddWithValue("@tipo", "CAPTURA_WC")
                    cmd.Parameters.AddWithValue("@payload", bodyStream)
                    cmd.Parameters.AddWithValue("@msg", headers)
                    cmd.Parameters.AddWithValue("@ip", context.Request.UserHostAddress)
                    cmd.ExecuteNonQuery()
                End Using
            End Using
            
            ' Siempre retornar 200 OK
            context.Response.StatusCode = 200
            context.Response.Write("{""test"":""ok"",""captured"":true}")
            
        Catch ex As Exception
            context.Response.StatusCode = 200
            context.Response.Write("{""error"":""" & ex.Message.Replace("""", "'") & """}")
        End Try
    End Sub
    
    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property
    
End Class
