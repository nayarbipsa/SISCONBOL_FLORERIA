<%@ WebHandler Language="VB" Class="TestWooCommerceSync" %>

Imports System.Web

Public Class TestWooCommerceSync : Implements IHttpHandler
    
    Public Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"
        
        Try
            ' Test 1: ¿Existe la clase?
            Dim testClass = GetType(WooCommerceSync)
            
            ' Test 2: ¿Existe el método?
            Dim testMethod = testClass.GetMethod("ProcesarOrdenWebhook")
            
            If testMethod Is Nothing Then
                context.Response.StatusCode = 500
                context.Response.Write("{""error"":""Método ProcesarOrdenWebhook no encontrado en la clase""}")
                Return
            End If
            
            ' Test 3: Intentar llamar al método con JSON de prueba
            Dim jsonTest As String = "{""id"":9999,""number"":""TEST"",""status"":""processing"",""total"":""100"",""billing"":{""first_name"":""Test""},""shipping"":{""address_1"":""Test""},""line_items"":[]}"
            
            Dim resultado As Dictionary(Of String, Object) = WooCommerceSync.ProcesarOrdenWebhook(jsonTest)
            
            context.Response.StatusCode = 200
            context.Response.Write("{""test"":""ok"",""clase_encontrada"":true,""metodo_encontrado"":true,""resultado_ok"":" & resultado("ok").ToString().ToLower() & ",""mensaje"":""" & resultado("mensaje").ToString() & """}")
            
        Catch ex As TypeLoadException
            context.Response.StatusCode = 500
            context.Response.Write("{""error"":""No se puede cargar WooCommerceSync"",""detalle"":""" & ex.Message.Replace("""", "'") & """}")
            
        Catch ex As System.Reflection.TargetInvocationException
            context.Response.StatusCode = 500
            Dim innerMsg As String = If(ex.InnerException IsNot Nothing, ex.InnerException.Message, ex.Message)
            context.Response.Write("{""error"":""Error al invocar método"",""detalle"":""" & innerMsg.Replace("""", "'") & """}")
            
        Catch ex As Exception
            context.Response.StatusCode = 500
            context.Response.Write("{""error"":""" & ex.GetType().Name & """,""mensaje"":""" & ex.Message.Replace("""", "'") & """,""stack"":""" & ex.StackTrace.Replace("""", "'").Replace(vbCrLf, " | ") & """}")
        End Try
    End Sub
    
    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property
    
End Class
