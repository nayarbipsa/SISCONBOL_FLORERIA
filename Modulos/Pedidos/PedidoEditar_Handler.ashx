<%@ WebHandler Language="VB" Class="PedidoEditar_Handler" %>

Imports System
Imports System.Web
Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web.Script.Serialization

' ============================================================
' SISCONBOL - Handler de edicion de Pedido (confirmado)
' Archivo: Modulos/Pedidos/PedidoEditar_Handler.ashx
' Tabla:   FLORERIA_Pedido
' Permisos: Solo Admin (tipo_id=1) o Gerente (tipo_id=2)
' ============================================================
Public Class PedidoEditar_Handler
    Implements IHttpHandler
    Implements System.Web.SessionState.IRequiresSessionState

    Public Sub ProcessRequest(context As HttpContext) Implements IHttpHandler.ProcessRequest
        context.Response.ContentType = "application/json"
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache)

        ' 1. Validar sesion
        If Not SesionHelper.VerificarSesion(context) Then
            context.Response.Write("{""ok"":false,""msg"":""Sesion expirada""}")
            Return
        End If

        ' 2. Validar permisos (solo Admin/Gerente)
        Dim tipoId As Integer = 3
        If context.Session("tipo_id") IsNot Nothing Then
            Integer.TryParse(context.Session("tipo_id").ToString(), tipoId)
        End If

        Dim esAdminOGerente As Boolean = (tipoId = 1 OrElse tipoId = 2)

        Dim accion As String = context.Request.Form("accion")
        If accion Is Nothing Then accion = ""

        Try
            Select Case accion
                Case "ACTUALIZAR_ENTREGA"
                    If Not esAdminOGerente Then
                        context.Response.Write("{""ok"":false,""msg"":""Sin permisos. Solo Admin/Gerente pueden editar.""}")
                        Return
                    End If
                    ActualizarEntrega(context)

                Case "LISTAR_ZONAS"
                    ListarZonas(context)

                Case Else
                    context.Response.Write("{""ok"":false,""msg"":""Accion no valida""}")
            End Select
        Catch ex As Exception
            Dim msg As String = ex.Message.Replace("""", "'").Replace(vbCr, " ").Replace(vbLf, " ")
            context.Response.Write("{""ok"":false,""msg"":""" & msg & """}")
        End Try
    End Sub

    ' ============================================================
    ' ACTUALIZAR_ENTREGA
    ' Recibe: pedido_id, fecha_entrega, slot_id, tipo_entrega,
    '         ciudad_id, zona_id, sucursal_id, direccion, referencia, motivo
    ' Llama: FLORERIA_sp_Pedido_ActualizarEntrega
    ' ============================================================
    Private Sub ActualizarEntrega(context As HttpContext)
        Dim pedidoIdStr As String = context.Request.Form("pedido_id")
        Dim pedidoId As Integer = 0
        If pedidoIdStr Is Nothing OrElse Not Integer.TryParse(pedidoIdStr, pedidoId) OrElse pedidoId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""ID de pedido invalido""}")
            Return
        End If

        ' Fecha
        Dim fechaStr As String = context.Request.Form("fecha_entrega")
        If fechaStr Is Nothing Then fechaStr = ""
        Dim fecha As DateTime
        If Not DateTime.TryParse(fechaStr, fecha) Then
            context.Response.Write("{""ok"":false,""msg"":""Fecha de entrega invalida""}")
            Return
        End If

        ' Tipo entrega
        Dim tipoEntrega As String = context.Request.Form("tipo_entrega")
        If tipoEntrega Is Nothing Then tipoEntrega = ""
        tipoEntrega = tipoEntrega.Trim().ToUpper()
        If tipoEntrega <> "DOMICILIO" AndAlso tipoEntrega <> "RECOJO_SUCURSAL" Then
            context.Response.Write("{""ok"":false,""msg"":""Tipo de entrega invalido""}")
            Return
        End If

        ' Ciudad obligatoria
        Dim ciudadId As Integer = ParsearIntPositivo(context.Request.Form("ciudad_id"))
        If ciudadId <= 0 Then
            context.Response.Write("{""ok"":false,""msg"":""Debe seleccionar una ciudad""}")
            Return
        End If

        ' Campos opcionales segun tipo
        Dim slotId As Integer       = ParsearIntPositivo(context.Request.Form("slot_id"))
        Dim zonaId As Integer       = ParsearIntPositivo(context.Request.Form("zona_id"))
        Dim sucursalId As Integer   = ParsearIntPositivo(context.Request.Form("sucursal_id"))
        Dim direccion As String     = LeerTexto(context, "direccion", 300)
        Dim referencia As String    = LeerTexto(context, "referencia", 300)
        Dim motivo As String        = LeerTexto(context, "motivo", 500)

        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(context)
        Dim ip As String = context.Request.UserHostAddress
        If ip Is Nothing Then ip = ""
        If ip.Length > 50 Then ip = ip.Substring(0, 50)

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_ActualizarEntrega", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@pedido_id",     pedidoId)
                cmd.Parameters.AddWithValue("@fecha_entrega", fecha.Date)

                If slotId > 0 Then
                    cmd.Parameters.AddWithValue("@slot_id", CType(slotId, Int16))
                Else
                    cmd.Parameters.AddWithValue("@slot_id", DBNull.Value)
                End If

                cmd.Parameters.AddWithValue("@tipo_entrega", tipoEntrega)
                cmd.Parameters.AddWithValue("@ciudad_id",    CType(ciudadId, Int16))

                If zonaId > 0 Then
                    cmd.Parameters.AddWithValue("@zona_id", zonaId)
                Else
                    cmd.Parameters.AddWithValue("@zona_id", DBNull.Value)
                End If

                If sucursalId > 0 Then
                    cmd.Parameters.AddWithValue("@sucursal_id", CType(sucursalId, Int16))
                Else
                    cmd.Parameters.AddWithValue("@sucursal_id", DBNull.Value)
                End If

                If direccion = "" Then
                    cmd.Parameters.AddWithValue("@direccion", DBNull.Value)
                Else
                    cmd.Parameters.AddWithValue("@direccion", direccion)
                End If

                If referencia = "" Then
                    cmd.Parameters.AddWithValue("@referencia", DBNull.Value)
                Else
                    cmd.Parameters.AddWithValue("@referencia", referencia)
                End If

                If motivo = "" Then
                    cmd.Parameters.AddWithValue("@motivo", DBNull.Value)
                Else
                    cmd.Parameters.AddWithValue("@motivo", motivo)
                End If

                cmd.Parameters.AddWithValue("@usuario_id", usuarioId)

                If ip = "" Then
                    cmd.Parameters.AddWithValue("@ip", DBNull.Value)
                Else
                    cmd.Parameters.AddWithValue("@ip", ip)
                End If

                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        Dim ok As Integer = 0
                        If Not IsDBNull(dr("ok")) Then ok = Convert.ToInt32(dr("ok"))
                        Dim mensaje As String = ""
                        If Not IsDBNull(dr("mensaje")) Then mensaje = dr("mensaje").ToString()

                        Dim okStr As String = If(ok = 1, "true", "false")
                        Dim msgEsc As String = mensaje.Replace("\", "\\").Replace("""", "\""")
                        context.Response.Write("{""ok"":" & okStr & ",""msg"":""" & msgEsc & """}")
                    Else
                        context.Response.Write("{""ok"":false,""msg"":""Sin respuesta del SP""}")
                    End If
                End Using
            End Using
        End Using
    End Sub

    ' ============================================================
    ' LISTAR_ZONAS
    ' Devuelve JSON de zonas activas (zona_id, ciudad_id, nombre)
    ' Usado por el datalist del modal
    ' ============================================================
    Private Sub ListarZonas(context As HttpContext)
        Dim zonasList As New List(Of Object)

        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Dim sql As String = "SELECT zona_id, ciudad_id, nombre " &
                                "FROM   FLORERIA_Zona " &
                                "WHERE  activo = 1 " &
                                "ORDER BY nombre"
            Using cmd As New SqlCommand(sql, conn)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        zonasList.Add(New With {
                            .zona_id   = CInt(dr("zona_id")),
                            .ciudad_id = CInt(dr("ciudad_id")),
                            .nombre    = dr("nombre").ToString()
                        })
                    End While
                End Using
            End Using
        End Using

        Dim serializer As New JavaScriptSerializer()
        Dim json As String = serializer.Serialize(zonasList)
        context.Response.Write("{""ok"":true,""zonas"":" & json & "}")
    End Sub

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Function ParsearIntPositivo(valor As String) As Integer
        If valor Is Nothing OrElse valor = "" Then Return 0
        Dim v As Integer = 0
        If Integer.TryParse(valor, v) AndAlso v > 0 Then Return v
        Return 0
    End Function

    Private Function LeerTexto(context As HttpContext, campo As String, maxLen As Integer) As String
        Dim v As String = context.Request.Form(campo)
        If v Is Nothing Then Return ""
        v = v.Trim()
        If v.Length > maxLen Then v = v.Substring(0, maxLen)
        Return v
    End Function

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class
