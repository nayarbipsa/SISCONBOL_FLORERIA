Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

' ============================================================
' MODULO: Crear Pre-Pedido
' Archivo: Modulos/Pedidos/PrePedidos.aspx.vb
' ============================================================
Partial Public Class Modulos_Pedidos_PrePedidos
    Inherits System.Web.UI.Page

    Public Property MenuHtml As String = ""
    Public Property ResultData As String = ""

    ' ====================================
    ' PAGE LOAD
    ' ====================================
    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' 1. Verificar sesión
        If Not SesionHelper.VerificarSesion(Context) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If

        ' 2. Generar menú
        MenuHtml = SesionHelper.GenerarMenuHtml(Context, Me)

        ' 3. Si es postback, procesar acción
        If IsPostBack Then
            ProcesarAccion()
        End If
    End Sub

    ' ====================================
    ' PROCESAR ACCIÓN
    ' ====================================
    Private Sub ProcesarAccion()
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""

        If accion = "CREAR" Then
            CrearPrePedido()
        End If
    End Sub

    ' ====================================
    ' CREAR PRE-PEDIDO
    ' ====================================
    Private Sub CrearPrePedido()
        ' Obtener datos del formulario
        Dim celular As String = Request.Form("hdCelular")
        If celular Is Nothing Then celular = ""
        celular = celular.Trim()

        Dim nombre As String = Request.Form("hdNombre")
        If nombre Is Nothing Then nombre = ""
        nombre = nombre.Trim()

        Dim apellidos As String = Request.Form("hdApellidos")
        If apellidos Is Nothing Then apellidos = ""
        apellidos = apellidos.Trim()

        Dim email As String = Request.Form("hdEmail")
        If email Is Nothing Then email = ""
        email = email.Trim()

        Dim tipo As String = Request.Form("hdTipo")
        If tipo Is Nothing Then tipo = "PRE_PEDIDO"

        ' Validar celular
        If celular = "" Then
            EnviarResultado(False, "El celular es obligatorio", 0)
            Return
        End If

        If celular.Length < 7 OrElse celular.Length > 8 Then
            EnviarResultado(False, "El celular debe tener 7 u 8 dígitos", 0)
            Return
        End If

        ' Obtener datos de sesión
        Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(Context)
        Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
        If ip Is Nothing Then ip = "127.0.0.1"

        ' Crear pre-pedido
        Dim prepedidoId As Integer = 0
        Dim codigo As String = ""

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                ' Llamar al SP
                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_Crear", conn)
                    cmd.CommandType = CommandType.StoredProcedure

                    cmd.Parameters.AddWithValue("@tipo_registro", tipo)
                    cmd.Parameters.AddWithValue("@cliente_celular", celular)
                    cmd.Parameters.AddWithValue("@agente_id", usuarioId)
                    cmd.Parameters.AddWithValue("@ip", ip)

                    ' Parámetros OUTPUT
                    Dim paramId As New SqlParameter("@prepedido_id", SqlDbType.Int)
                    paramId.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(paramId)

                    Dim paramCodigo As New SqlParameter("@codigo", SqlDbType.VarChar, 20)
                    paramCodigo.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(paramCodigo)

                    cmd.ExecuteNonQuery()

                    ' Obtener valores OUTPUT
                    If paramId.Value IsNot Nothing AndAlso Not IsDBNull(paramId.Value) Then
                        prepedidoId = CInt(paramId.Value)
                    End If

                    If paramCodigo.Value IsNot Nothing AndAlso Not IsDBNull(paramCodigo.Value) Then
                        codigo = paramCodigo.Value.ToString()
                    End If
                End Using

                ' Si se creó, actualizar datos del cliente si se proporcionaron
                If prepedidoId > 0 AndAlso (nombre <> "" OrElse apellidos <> "" OrElse email <> "") Then
                    Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_ActualizarCliente", conn)
                        cmd.CommandType = CommandType.StoredProcedure

                        cmd.Parameters.AddWithValue("@prepedido_id", prepedidoId)
                        cmd.Parameters.AddWithValue("@cliente_nombre", If(nombre = "", DBNull.Value, CObj(nombre)))
                        cmd.Parameters.AddWithValue("@cliente_apellidos", If(apellidos = "", DBNull.Value, CObj(apellidos)))
                        cmd.Parameters.AddWithValue("@cliente_email", If(email = "", DBNull.Value, CObj(email)))
                        cmd.Parameters.AddWithValue("@cliente_pais_id", DBNull.Value)
                        cmd.Parameters.AddWithValue("@cliente_ciudad_id", DBNull.Value)
                        cmd.Parameters.AddWithValue("@modificado_por", usuarioId)
                        cmd.Parameters.AddWithValue("@ip", ip)

                        cmd.ExecuteNonQuery()
                    End Using
                End If
            End Using

            ' Enviar resultado exitoso
            If prepedidoId > 0 Then
                EnviarResultado(True, "Pre-pedido " & codigo & " creado exitosamente", prepedidoId)
            Else
                EnviarResultado(False, "Error al crear el pre-pedido", 0)
            End If

        Catch ex As SqlException
            ' Error de SQL Server (ej: validación de unicidad)
            EnviarResultado(False, ex.Message, 0)
        Catch ex As Exception
            ' Error general
            EnviarResultado(False, "Error al crear el pre-pedido: " & ex.Message, 0)
        End Try
    End Sub

    ' ====================================
    ' CLASE RESULTADO
    ' ====================================
    Public Class ResultadoCreacion
        Public Property exito As Boolean
        Public Property mensaje As String
        Public Property prepedido_id As Integer
    End Class

    ' ====================================
    ' ENVIAR RESULTADO
    ' ====================================
    Private Sub EnviarResultado(exito As Boolean, mensaje As String, prepedidoId As Integer)
        Dim resultado As New ResultadoCreacion()
        resultado.exito = exito
        resultado.mensaje = mensaje
        resultado.prepedido_id = prepedidoId

        Dim serializer As New JavaScriptSerializer()
        ResultData = serializer.Serialize(resultado)
    End Sub

    ' ====================================
    ' POSTBACK BUTTON CLICK
    ' ====================================
    Protected Sub btnPostBack_Click(sender As Object, e As EventArgs)
        ' Este método se ejecuta automáticamente
        ' La lógica está en Page_Load cuando IsPostBack = True
    End Sub

End Class