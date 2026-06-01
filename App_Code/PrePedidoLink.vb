Imports System.Data.SqlClient
Imports System.Web

' ============================================================
' SISCONBOL - PrePedidoLink
' Helper compartido para el LINK DUAL cliente/agente (pp.aspx).
'
' Centraliza la resolucion de un pre-pedido por su codigo corto
' (PRE-000123) y la garantia de un token_web vigente, replicando
' la logica de PrePedido_Handler.ashx (GENERAR_TOKEN):
'   - token = Guid.NewGuid().ToString("N")
'   - token_expira = ahora + 24h
'   - reutiliza el token si aun esta vigente (< expira)
'
' Lo usan pp.aspx (router) y cliente/index.aspx (entrada por ?c=).
' Convencion del proyecto: App_Code SIN Namespace.
' ============================================================
Public Class PrePedidoLink

    ' Resultado de resolver un pre-pedido por codigo
    Public Class Info
        Public Property Encontrado As Boolean = False
        Public Property PrePedidoId As Integer = 0
        Public Property Codigo As String = ""
        Public Property ClienteNombre As String = ""
        Public Property Token As String = ""
    End Class

    ' ============================================================
    ' Resuelve un pre-pedido por codigo y ASEGURA un token_web vigente.
    ' usuarioId: id del agente si hay sesion; 0 si es el cliente (anonimo).
    ' Si no encuentra el codigo, devuelve Info.Encontrado = False.
    ' ============================================================
    Public Shared Function AsegurarTokenPorCodigo(codigo As String, usuarioId As Integer) As Info
        Dim r As New Info()
        If codigo Is Nothing Then Return r
        codigo = codigo.Trim().ToUpper()
        If codigo = "" Then Return r

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Dim tokenExistente As String = ""
                Dim tokenExpira As DateTime = DateTime.MinValue
                Dim nombre As String = ""
                Dim apellidos As String = ""

                Using cmd As New SqlCommand(
                    "SELECT prepedido_id, codigo, token_web, token_expira, cliente_nombre, cliente_apellidos " &
                    "FROM FLORERIA_PrePedido WHERE codigo = @c", conn)
                    cmd.Parameters.AddWithValue("@c", codigo)
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If Not dr.Read() Then Return r
                        r.Encontrado = True
                        r.PrePedidoId = CInt(dr("prepedido_id"))
                        r.Codigo = dr("codigo").ToString()
                        If Not IsDBNull(dr("token_web")) Then tokenExistente = dr("token_web").ToString()
                        If Not IsDBNull(dr("token_expira")) Then tokenExpira = CDate(dr("token_expira"))
                        nombre = If(IsDBNull(dr("cliente_nombre")), "", dr("cliente_nombre").ToString())
                        apellidos = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                    End Using
                End Using

                r.ClienteNombre = (nombre & " " & apellidos).Trim()

                ' Reutilizar token si esta vigente; si falta o expiro, generar uno nuevo
                Dim ahora As DateTime = DateTime.Now
                Dim vigente As Boolean = (tokenExistente <> "" AndAlso tokenExpira > ahora)

                If vigente Then
                    r.Token = tokenExistente
                Else
                    Dim token As String = Guid.NewGuid().ToString("N")
                    Dim nuevaExpira As DateTime = ahora.AddHours(24)
                    Using cmdUpd As New SqlCommand(
                        "UPDATE FLORERIA_PrePedido " &
                        "SET token_web = @t, token_expira = @exp, " &
                        "    token_abierto_en = NULL, token_confirmado_por_cliente_en = NULL, " &
                        "    modificado_por = ISNULL(@uid, modificado_por), modificado_en = GETDATE() " &
                        "WHERE prepedido_id = @id", conn)
                        cmdUpd.Parameters.AddWithValue("@t", token)
                        cmdUpd.Parameters.AddWithValue("@exp", nuevaExpira)
                        cmdUpd.Parameters.AddWithValue("@uid", If(usuarioId > 0, CObj(usuarioId), DBNull.Value))
                        cmdUpd.Parameters.AddWithValue("@id", r.PrePedidoId)
                        cmdUpd.ExecuteNonQuery()
                    End Using
                    r.Token = token
                End If
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR PrePedidoLink.AsegurarTokenPorCodigo: " & ex.Message)
        End Try

        Return r
    End Function

    ' ============================================================
    ' Lee URL_PUBLICA_BASE de FLORERIA_Config (con fallback seguro).
    ' Sin barra final.
    ' ============================================================
    Public Shared Function UrlPublicaBase() As String
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("SELECT valor FROM FLORERIA_Config WHERE clave='URL_PUBLICA_BASE' AND activo=1", conn)
                    Dim v As Object = cmd.ExecuteScalar()
                    If v IsNot Nothing AndAlso Not IsDBNull(v) Then
                        Dim s As String = v.ToString().Trim().TrimEnd("/"c)
                        If s <> "" Then Return s
                    End If
                End Using
            End Using
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR PrePedidoLink.UrlPublicaBase: " & ex.Message)
        End Try
        Return "https://www.floreria.somee.com"
    End Function

End Class
