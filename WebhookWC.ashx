<%@ WebHandler Language="VB" Class="WebhookWC" %>

Imports System.Web
Imports System.IO
Imports System.Text
Imports System.Security.Cryptography
Imports System.Data.SqlClient
Imports System.Configuration

''' <summary>
''' HTTP Handler para recibir webhooks de WooCommerce
''' Endpoint: https://tu-sitio.somee.com/WebhookWC.ashx
''' Autor: SISCONBOL Team
''' Fecha: Mayo 2026
''' </summary>
Public Class WebhookWC : Implements IHttpHandler

    Public Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"
        
        ' Log del webhook recibido (para debugging)
        LogWebhook("INICIO", "Webhook recibido de " & context.Request.UserHostAddress)
        
        Try
            ' ============================================
            ' 1. LEER EL CUERPO JSON DEL WEBHOOK
            ' ============================================
            Dim bodyStream As String = ""
            Using reader As New StreamReader(context.Request.InputStream, Encoding.UTF8)
                bodyStream = reader.ReadToEnd()
            End Using
            
            If String.IsNullOrWhiteSpace(bodyStream) Then
                LogWebhook("ERROR", "Body vacío")
                context.Response.StatusCode = 400
                context.Response.Write("{""error"":""Body vacío""}")
                Return
            End If
            
            LogWebhook("BODY", bodyStream.Substring(0, Math.Min(500, bodyStream.Length)))
            
            ' ============================================
            ' 2. VALIDAR FIRMA HMAC SHA256
            ' ============================================
            Dim signature As String = context.Request.Headers("X-WC-Webhook-Signature")
            
            If Not String.IsNullOrEmpty(signature) Then
                If Not ValidarFirma(bodyStream, signature) Then
                    LogWebhook("ERROR", "Firma inválida. Recibida: " & signature)
                    context.Response.StatusCode = 401
                    context.Response.Write("{""error"":""Firma inválida""}")
                    Return
                End If
                LogWebhook("OK", "Firma válida")
            Else
                LogWebhook("WARN", "Sin firma X-WC-Webhook-Signature - validación omitida")
            End If
            
            ' ============================================
            ' 3. PROCESAR LA ORDEN
            ' ============================================
            Dim resultado As Dictionary(Of String, Object) = WooCommerceSync.ProcesarOrdenWebhook(bodyStream)
            
            If resultado("ok") Then
                LogWebhook("OK", "Orden procesada correctamente. Pedido ID: " & resultado("pedido_id"))
                context.Response.StatusCode = 200
                context.Response.Write("{""mensaje"":""" & resultado("mensaje").ToString() & """,""pedido_id"":" & resultado("pedido_id") & "}")
            Else
                LogWebhook("ERROR", "Fallo al procesar: " & resultado("mensaje"))
                context.Response.StatusCode = 500
                context.Response.Write("{""error"":""" & EscaparJson(resultado("mensaje").ToString()) & """}")
            End If
            
        Catch ex As Exception
            LogWebhook("EXCEPTION", ex.Message & " | " & ex.StackTrace)
            context.Response.StatusCode = 500
            context.Response.Write("{""error"":""" & EscaparJson(ex.Message) & """}")
        End Try
    End Sub
    
    ''' <summary>
    ''' Valida la firma HMAC SHA256 del webhook
    ''' </summary>
    Private Function ValidarFirma(body As String, signatureHeader As String) As Boolean
        Try
            Dim secret As String = ObtenerConfig("WC_WEBHOOK_SECRET")
            
            ' Si no hay secreto configurado, no validamos (modo desarrollo)
            If String.IsNullOrEmpty(secret) Then
                LogWebhook("WARN", "WC_WEBHOOK_SECRET no configurado - firma NO validada")
                Return True
            End If
            
            ' Calcular HMAC SHA256
            Using hmac As New HMACSHA256(Encoding.UTF8.GetBytes(secret))
                Dim hash() As Byte = hmac.ComputeHash(Encoding.UTF8.GetBytes(body))
                Dim computedSignature As String = Convert.ToBase64String(hash)
                
                LogWebhook("FIRMA_CALC", "Calculada: " & computedSignature)
                LogWebhook("FIRMA_REC", "Recibida: " & signatureHeader)
                
                Return computedSignature = signatureHeader
            End Using
            
        Catch ex As Exception
            LogWebhook("ERROR_FIRMA", ex.Message)
            Return False
        End Try
    End Function
    
    ''' <summary>
    ''' Obtiene valor de configuración desde FLORERIA_Config
    ''' </summary>
    Private Function ObtenerConfig(clave As String) As String
        Try
            Using conn As New SqlConnection(ConfigurationManager.ConnectionStrings("SISCONBOL").ConnectionString)
                conn.Open()
                Using cmd As New SqlCommand("SELECT valor FROM FLORERIA_Config WHERE clave=@c AND activo=1", conn)
                    cmd.Parameters.AddWithValue("@c", clave)
                    Dim val As Object = cmd.ExecuteScalar()
                    Return If(val IsNot Nothing, val.ToString(), "")
                End Using
            End Using
        Catch ex As Exception
            LogWebhook("ERROR_CONFIG", "Error al leer " & clave & ": " & ex.Message)
            Return ""
        End Try
    End Function
    
    ''' <summary>
    ''' Escapa caracteres especiales para JSON
    ''' </summary>
    Private Function EscaparJson(texto As String) As String
        If texto Is Nothing Then Return ""
        Return texto.Replace("\", "\\").Replace("""", "\""").Replace(vbCr, "").Replace(vbLf, "\n").Replace(vbTab, " ")
    End Function
    
    ''' <summary>
    ''' Log simple para debugging (escribe en Debug Output y en tabla opcional)
    ''' </summary>
    Private Sub LogWebhook(tipo As String, mensaje As String)
        Dim logMsg As String = "[WEBHOOK_WC] [" & tipo & "] " & mensaje
        System.Diagnostics.Debug.WriteLine(logMsg)
        
        ' TODO: Opcional - guardar en tabla FLORERIA_Log para auditoría
        ' INSERT INTO FLORERIA_Log (tipo, mensaje, fecha) VALUES (@tipo, @msg, GETDATE())
    End Sub
    
    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
