Imports System.Data
Imports System.Data.SqlClient
Imports System.Web

' ============================================================
' SISCONBOL - Crear Pre-Pedido (CON DETECCIÓN DUPLICADOS)
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
        ' Capturar valores del formulario
        Dim tipoRegistro As String = "PRE_PEDIDO"
        Dim celular As String = Request.Form("txCelular")
        If celular Is Nothing Then celular = ""
        celular = celular.Trim()

        Dim nombre As String = Request.Form("txNombre")
        If nombre Is Nothing Then nombre = ""
        nombre = nombre.Trim()

        Dim apellidos As String = Request.Form("txApellidos")
        If apellidos Is Nothing Then apellidos = ""
        apellidos = apellidos.Trim()

        Dim email As String = Request.Form("txEmail")
        If email Is Nothing Then email = ""
        email = email.Trim()

        ' Validar celular obligatorio
        If celular = "" Then
            MensajeAlerta = "El número de celular es obligatorio"
            ValorCelular = celular
            ValorNombre = nombre
            ValorApellidos = apellidos
            ValorEmail = email
            Return
        End If

        ' ============================================================
        ' NORMALIZAR CELULAR: quitar espacios, guiones, paréntesis
        ' para que no supere los 20 chars del campo en BD
        ' Ejemplo: "+591 72 020 979" → "+59172020979"
        ' ============================================================
        Dim celularNormalizado As String = celular.Replace(" ", "")
        celularNormalizado = celularNormalizado.Replace("-", "")
        celularNormalizado = celularNormalizado.Replace("(", "")
        celularNormalizado = celularNormalizado.Replace(")", "")

        ' Validar longitud máxima después de normalizar (campo VARCHAR(20))
        If celularNormalizado.Length > 20 Then
            MensajeAlerta = "El número de celular es demasiado largo. Máximo 20 caracteres sin espacios."
            ValorCelular = celular
            ValorNombre = nombre
            ValorApellidos = apellidos
            ValorEmail = email
            Return
        End If

        ' ============================================================
        ' DETERMINAR PAÍS según celular normalizado
        ' paisId = DBNull.Value cuando no se puede determinar el país
        ' (evita el error de INTEGER 0 que no existe en FLORERIA_Pais)
        ' ============================================================
        Dim paisIdObj As Object = DBNull.Value

        If celularNormalizado.Length > 0 Then
            If celularNormalizado.StartsWith("+591") OrElse celularNormalizado.StartsWith("591") Then
                ' Bolivia con prefijo
                paisIdObj = 1
            ElseIf (celularNormalizado.StartsWith("6") OrElse celularNormalizado.StartsWith("7")) AndAlso
                   (celularNormalizado.Length = 7 OrElse celularNormalizado.Length = 8) Then
                ' Bolivia sin prefijo (número local)
                paisIdObj = 1
            ElseIf celularNormalizado.StartsWith("+51") OrElse celularNormalizado.StartsWith("51") Then
                ' Perú
                paisIdObj = DBNull.Value  ' País 2 (Perú) puede no existir en BD aún
            Else
                ' Internacional u otro país → NULL en BD
                paisIdObj = DBNull.Value
            End If
        End If

        Dim prepedidoId As Integer = 0
        Dim codigoGenerado As String = ""
        Dim ip As String = Request.UserHostAddress
        If ip Is Nothing Then ip = ""

        ' ============================================================
        ' DECLARAR VARIABLE ANTES DEL TRY (para usarla después)
        ' ============================================================
        Dim yaExistia As Boolean = False

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                ' ============================================================
                ' CREAR PRE-PEDIDO (O DETECTAR DUPLICADO)
                ' Usamos celularNormalizado para no superar VARCHAR(20)
                ' ============================================================
                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_Crear", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@tipo_registro", tipoRegistro)
                    cmd.Parameters.AddWithValue("@cliente_celular", celularNormalizado)
                    cmd.Parameters.AddWithValue("@agente_id", SesionHelper.ObtenerUsuarioId(HttpContext.Current))
                    cmd.Parameters.AddWithValue("@ip", ip)

                    Dim pId As New SqlParameter("@prepedido_id", SqlDbType.Int)
                    pId.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(pId)

                    Dim pCod As New SqlParameter("@codigo", SqlDbType.VarChar, 20)
                    pCod.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(pCod)

                    ' ============================================================
                    ' LEER RESULTADO CON DataReader (para obtener ya_existia)
                    ' ============================================================
                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            prepedidoId = Convert.ToInt32(dr("prepedido_id"))
                            codigoGenerado = dr("codigo").ToString()

                            ' Leer flag ya_existia de forma defensiva
                            Try
                                Dim idxYaExistia As Integer = dr.GetOrdinal("ya_existia")
                                If Not dr.IsDBNull(idxYaExistia) Then
                                    yaExistia = Convert.ToBoolean(dr(idxYaExistia))
                                End If
                            Catch
                                ' Columna no existe en el resultset -> asumir false
                                yaExistia = False
                            End Try
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

                ' ============================================================
                ' ACTUALIZAR DATOS DEL CLIENTE (SOLO SI NO ES DUPLICADO)
                ' ============================================================
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

                        ' paisIdObj ya es DBNull.Value si no se pudo determinar el país
                        cmd2.Parameters.AddWithValue("@cliente_pais_id", paisIdObj)
                        cmd2.Parameters.AddWithValue("@cliente_ciudad_id", DBNull.Value)
                        cmd2.Parameters.AddWithValue("@modificado_por", SesionHelper.ObtenerUsuarioId(HttpContext.Current))
                        cmd2.Parameters.AddWithValue("@ip", ip)
                        cmd2.ExecuteNonQuery()
                    End Using
                End If
            End Using

            ' ============================================================
            ' REDIRIGIR CON PARÁMETRO ADICIONAL SI ES DUPLICADO
            ' ============================================================
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
