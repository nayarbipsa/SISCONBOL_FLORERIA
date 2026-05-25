<%@ WebHandler Language="VB" Class="Cliente_PublicHandler" %>

Imports System
Imports System.Web
Imports System.Data
Imports System.Data.SqlClient

' ============================================================
' SISCONBOL - Handler PUBLICO (sin sesion)
' Archivo: cliente/Cliente_PublicHandler.ashx
'
' Acciones:
'   GUARDAR_CLIENTE      (campo, valor)
'   GUARDAR_ENTREGA      (entrega_id, campo, valor)
'   GUARDAR_METODO_PAGO  (metodo)
'   CONFIRMAR
'
' Validacion: cada request requiere 'token' y se verifica contra
'   FLORERIA_PrePedido.token_web + token_expira > NOW + token_confirmado_por_cliente_en IS NULL
' ============================================================
Public Class Cliente_PublicHandler
    Implements IHttpHandler

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"

        Dim accion As String = context.Request.Form("accion")
        Dim token As String = context.Request.Form("token")
        If accion Is Nothing Then accion = ""
        If token Is Nothing Then token = ""
        token = token.Trim()

        If token = "" OrElse token.Length < 16 Then
            context.Response.Write("{""ok"":false,""msg"":""Token invalido""}")
            Return
        End If

        Try
            ' Validar token y obtener prepedido_id
            Dim ppId As Integer = ValidarToken(token)
            If ppId <= 0 Then
                context.Response.Write("{""ok"":false,""msg"":""Token invalido, expirado o ya confirmado""}")
                Return
            End If

            Select Case accion
                Case "GUARDAR_CLIENTE"
                    GuardarCliente(context, ppId)
                Case "GUARDAR_ENTREGA"
                    GuardarEntrega(context, ppId)
                Case "GUARDAR_METODO_PAGO"
                    GuardarMetodoPago(context, ppId)
                Case "CONFIRMAR"
                    Confirmar(context, ppId)
                Case Else
                    context.Response.Write("{""ok"":false,""msg"":""Accion no valida""}")
            End Select
        Catch ex As Exception
            context.Response.Write("{""ok"":false,""msg"":""" & ex.Message.Replace("""", "'") & """}")
        End Try
    End Sub

    ' ============================================================
    ' ValidarToken -> devuelve prepedido_id o 0
    ' ============================================================
    Private Function ValidarToken(token As String) As Integer
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand(
                "SELECT prepedido_id FROM FLORERIA_PrePedido " &
                "WHERE token_web = @t " &
                "  AND token_expira > GETDATE() " &
                "  AND token_confirmado_por_cliente_en IS NULL", conn)
                cmd.Parameters.AddWithValue("@t", token)
                Dim r As Object = cmd.ExecuteScalar()
                If r Is Nothing OrElse IsDBNull(r) Then Return 0
                Return CInt(r)
            End Using
        End Using
    End Function

    ' ============================================================
    ' GuardarCliente
    ' ============================================================
    Private Sub GuardarCliente(context As HttpContext, ppId As Integer)
        Dim campo As String = context.Request.Form("campo")
        Dim valor As String = context.Request.Form("valor")
        If campo Is Nothing Then campo = ""
        If valor Is Nothing Then valor = ""

        ' Lista blanca
        Dim permitidos As String() = {"cliente_nombre", "cliente_apellidos", "cliente_email"}
        If Array.IndexOf(permitidos, campo) < 0 Then
            context.Response.Write("{""ok"":false,""msg"":""Campo no permitido""}")
            Return
        End If

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Dim sql As String = "UPDATE FLORERIA_PrePedido SET [" & campo & "] = @val, modificado_en = GETDATE() WHERE prepedido_id = @id"
            Using cmd As New SqlCommand(sql, conn)
                cmd.Parameters.AddWithValue("@val", If(valor = "", DBNull.Value, CObj(valor.Trim())))
                cmd.Parameters.AddWithValue("@id", ppId)
                cmd.ExecuteNonQuery()
            End Using
        End Using

        context.Response.Write("{""ok"":true}")
    End Sub

    ' ============================================================
    ' GuardarEntrega (campo de FLORERIA_PrePedido_Entrega)
    ' ============================================================
    Private Sub GuardarEntrega(context As HttpContext, ppId As Integer)
        Dim entregaId As Integer = 0
        Integer.TryParse(context.Request.Form("entrega_id"), entregaId)
        Dim campo As String = context.Request.Form("campo")
        Dim valor As String = context.Request.Form("valor")
        If campo Is Nothing Then campo = ""
        If valor Is Nothing Then valor = ""

        If entregaId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""entrega_id invalido""}")
            Return
        End If

        ' Lista blanca de campos que el cliente puede editar
        Dim permitidos As String() = {
            "receptor_nombre", "receptor_celular",
            "direccion", "referencia", "gps",
            "dedicatoria", "firma_tarjeta", "tipo_ocacion"
        }
        If Array.IndexOf(permitidos, campo) < 0 Then
            context.Response.Write("{""ok"":false,""msg"":""Campo no permitido""}")
            Return
        End If

        ' Verificar que la entrega pertenezca al pre-pedido y siga en BORRADOR
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()

            Using cmdCheck As New SqlCommand(
                "SELECT COUNT(*) FROM FLORERIA_PrePedido_Entrega " &
                "WHERE prepedido_entrega_id = @eid AND prepedido_id = @pp AND estado = 'BORRADOR'", conn)
                cmdCheck.Parameters.AddWithValue("@eid", entregaId)
                cmdCheck.Parameters.AddWithValue("@pp", ppId)
                Dim n As Object = cmdCheck.ExecuteScalar()
                If n Is Nothing OrElse CInt(n) = 0 Then
                    context.Response.Write("{""ok"":false,""msg"":""Entrega no encontrada""}")
                    Return
                End If
            End Using

            Dim sql As String = "UPDATE FLORERIA_PrePedido_Entrega SET [" & campo & "] = @val, modificado_en = GETDATE() " &
                                "WHERE prepedido_entrega_id = @eid"
            Using cmd As New SqlCommand(sql, conn)
                cmd.Parameters.AddWithValue("@val", If(valor = "", DBNull.Value, CObj(valor.Trim())))
                cmd.Parameters.AddWithValue("@eid", entregaId)
                cmd.ExecuteNonQuery()
            End Using
        End Using

        context.Response.Write("{""ok"":true}")
    End Sub

    ' ============================================================
    ' GuardarMetodoPago
    ' ============================================================
    Private Sub GuardarMetodoPago(context As HttpContext, ppId As Integer)
        Dim metodo As String = context.Request.Form("metodo")
        If metodo Is Nothing Then metodo = ""

        Dim validos As String() = {"QR", "TRANSFERENCIA", "EFECTIVO", "PAYPAL", "TARJETA", "PAGOMOVIL", "CRIPTO", "YAPE", "PIX"}
        If Array.IndexOf(validos, metodo) < 0 Then
            context.Response.Write("{""ok"":false,""msg"":""Metodo no valido""}")
            Return
        End If

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand(
                "UPDATE FLORERIA_PrePedido SET metodo_pago_cliente = @m, modificado_en = GETDATE() " &
                "WHERE prepedido_id = @id", conn)
                cmd.Parameters.AddWithValue("@m", metodo)
                cmd.Parameters.AddWithValue("@id", ppId)
                cmd.ExecuteNonQuery()
            End Using
        End Using

        context.Response.Write("{""ok"":true}")
    End Sub

    ' ============================================================
    ' Confirmar (marca timestamp del cliente; el agente confirma final)
    ' ============================================================
    Private Sub Confirmar(context As HttpContext, ppId As Integer)
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand(
                "UPDATE FLORERIA_PrePedido " &
                "SET token_confirmado_por_cliente_en = GETDATE(), modificado_en = GETDATE() " &
                "WHERE prepedido_id = @id AND token_confirmado_por_cliente_en IS NULL", conn)
                cmd.Parameters.AddWithValue("@id", ppId)
                cmd.ExecuteNonQuery()
            End Using
        End Using

        context.Response.Write("{""ok"":true}")
    End Sub

    Public ReadOnly Property IsReusable As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
