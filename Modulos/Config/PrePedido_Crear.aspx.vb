Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

' ============================================================
' SISCONBOL - Crear Pre-Pedido
' Archivo: Modulos/Pedidos/PrePedido_Crear.aspx.vb
' MasterPage: Site.Master (sesión verificada automáticamente)
' ============================================================
Partial Public Class Modulos_Pedidos_PrePedido_Crear
    Inherits System.Web.UI.Page

    ' Propiedades públicas para contenido dinámico
    Public Property MensajeAlerta As String = ""
    Public Property ValorCelular As String = ""
    Public Property ValorNombre As String = ""
    Public Property ValorApellidos As String = ""
    Public Property ValorEmail As String = ""

    ' ============================================================
    ' Page_Load - NO verificar sesión, lo hace Site.Master
    ' ============================================================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        ' Site.Master ya verificó sesión - esta página solo carga si hay sesión válida
        If Not IsPostBack Then
            ' Limpiar valores
            ValorCelular = ""
            ValorNombre = ""
            ValorApellidos = ""
            ValorEmail = ""
        End If
    End Sub

    ' ============================================================
    ' btnAccion_Click - Procesar formulario
    ' ============================================================
    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        accion = accion.Trim()

        If accion = "CREAR" Then
            CrearPrePedido()
        End If
    End Sub

    ' ============================================================
    ' CrearPrePedido - Lógica de creación
    ' ============================================================
    Private Sub CrearPrePedido()
        ' Leer formulario
        Dim celular As String = Request.Form("txCelular")
        Dim nombre As String = Request.Form("txNombre")
        Dim apellidos As String = Request.Form("txApellidos")
        Dim email As String = Request.Form("txEmail")
        Dim tipoRegistro As String = Request.Form("selTipo")
        Dim paisIdStr As String = Request.Form("hdPaisId")

        ' Normalizar nulls
        If celular Is Nothing Then celular = ""
        If nombre Is Nothing Then nombre = ""
        If apellidos Is Nothing Then apellidos = ""
        If email Is Nothing Then email = ""
        If tipoRegistro Is Nothing Then tipoRegistro = "PRE_PEDIDO"
        If paisIdStr Is Nothing Then paisIdStr = ""

        celular = celular.Trim()
        nombre = nombre.Trim()
        apellidos = apellidos.Trim()
        email = email.Trim()
        tipoRegistro = tipoRegistro.Trim()
        paisIdStr = paisIdStr.Trim()

        ' ============================================================
        ' VALIDACIONES CON CLASE VALIDADOR
        ' ============================================================
        Dim resultadoValidacion = Validador.ValidarFormularioPrePedido(celular, nombre, apellidos, email)
        
        If Not resultadoValidacion.EsValido Then
            MensajeAlerta = resultadoValidacion.Mensaje
            ' Mantener valores para que usuario no pierda lo que escribió
            ValorCelular = celular
            ValorNombre = nombre
            ValorApellidos = apellidos
            ValorEmail = email
            Return
        End If

        ' Detectar país (fallback si JavaScript no detectó)
        Dim paisId As Object = DBNull.Value
        If paisIdStr <> "" Then
            Dim tmp As Integer = 0
            If Integer.TryParse(paisIdStr, tmp) Then
                paisId = tmp
            End If
        End If

        ' Fallback manual si no se detectó
        If paisId Is DBNull.Value Then
            If celular.StartsWith("+591") OrElse celular.StartsWith("591") Then
                paisId = 1
            ElseIf celular.StartsWith("+51") OrElse celular.StartsWith("51") Then
                paisId = 2
            ElseIf (celular.StartsWith("6") OrElse celular.StartsWith("7")) AndAlso _
                   (celular.Length = 7 OrElse celular.Length = 8) Then
                paisId = 1
            End If
        End If

        Dim prepedidoId As Integer = 0
        Dim codigoGenerado As String = ""
        Dim ip As String = Request.UserHostAddress
        If ip Is Nothing Then ip = ""

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                ' Crear pre-pedido (o detectar duplicado)
                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_Crear", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@tipo_registro", tipoRegistro)
                    cmd.Parameters.AddWithValue("@cliente_celular", celular)
                    cmd.Parameters.AddWithValue("@agente_id", SesionHelper.ObtenerUsuarioId(HttpContext.Current))
                    cmd.Parameters.AddWithValue("@ip", ip)

                    Dim pId As New SqlParameter("@prepedido_id", SqlDbType.Int)
                    pId.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(pId)

                    Dim pCod As New SqlParameter("@codigo", SqlDbType.VarChar, 20)
                    pCod.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(pCod)

                    ' Leer resultado con DataReader para obtener flag ya_existia
                    Dim yaExistia As Boolean = False
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            prepedidoId = Convert.ToInt32(dr("prepedido_id"))
                            codigoGenerado = dr("codigo").ToString()
                            
                            ' Leer flag ya_existia
                            If Not IsDBNull(dr("ya_existia")) Then
                                yaExistia = Convert.ToBoolean(dr("ya_existia"))
                            End If
                        End If
                    End Using

                    ' Verificar si se obtuvo ID
                    If prepedidoId <= 0 Then
                        MensajeAlerta = "Error: No se pudo crear el pre-pedido"
                        ValorCelular = celular
                        ValorNombre = nombre
                        ValorApellidos = apellidos
                        ValorEmail = email
                        Return
                    End If
                End Using

                ' Si NO es duplicado, actualizar datos del cliente
                If prepedidoId > 0 AndAlso Not yaExistia Then
                    Using cmd2 As New SqlCommand("FLORERIA_sp_PrePedido_ActualizarCliente", conn)
                        cmd2.CommandType = CommandType.StoredProcedure
                        cmd2.Parameters.AddWithValue("@prepedido_id", prepedidoId)

                        ' Campos opcionales - usar DBNull si están vacíos
                        If nombre = "" Then
                            cmd2.Parameters.AddWithValue("@cliente_nombre", DBNull.Value)
                        Else
                            cmd2.Parameters.AddWithValue("@cliente_nombre", nombre)
                        End If

                        If apellidos = "" Then
                            cmd2.Parameters.AddWithValue("@cliente_apellidos", DBNull.Value)
                        Else
                            cmd2.Parameters.AddWithValue("@cliente_apellidos", apellidos)
                        End If

                        If email = "" Then
                            cmd2.Parameters.AddWithValue("@cliente_email", DBNull.Value)
                        Else
                            cmd2.Parameters.AddWithValue("@cliente_email", email)
                        End If

                        cmd2.Parameters.AddWithValue("@cliente_pais_id", paisId)
                        cmd2.Parameters.AddWithValue("@cliente_ciudad_id", DBNull.Value)
                        cmd2.Parameters.AddWithValue("@modificado_por", SesionHelper.ObtenerUsuarioId(HttpContext.Current))
                        cmd2.Parameters.AddWithValue("@ip", ip)
                        cmd2.ExecuteNonQuery()
                    End Using
                End If
            End Using

            ' Redirigir a página de links con parámetro adicional si es duplicado
            Dim url As String = "PrePedido_Links.aspx?id=" & prepedidoId
            If yaExistia Then
                url &= "&existia=1"
            End If
            
            SesionHelper.RedirectSeguro(HttpContext.Current, url)
            Return

        Catch ex As Exception
            ' Error - mantener valores para que usuario no pierda lo que escribió
            MensajeAlerta = "Error: " & ex.Message.Replace("'", "").Replace("""", "")
            ValorCelular = celular
            ValorNombre = nombre
            ValorApellidos = apellidos
            ValorEmail = email
        End Try
    End Sub

End Class