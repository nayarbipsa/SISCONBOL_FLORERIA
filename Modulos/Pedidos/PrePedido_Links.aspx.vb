Imports System.Data.SqlClient
Imports System.Web

' ============================================================
' SISCONBOL - Modal Links Pre-Pedido (CORREGIDO PARA WHATSAPP)
' Archivo: Modulos/Pedidos/PrePedido_Links.aspx.vb
' MasterPage: Site.Master
' ============================================================
Partial Public Class Modulos_Pedidos_PrePedido_Links
    Inherits System.Web.UI.Page

    ' Propiedades públicas para la vista
    Public Property PrePedidoId As Integer = 0
    Public Property Codigo As String = ""
    Public Property ClienteNombre As String = ""
    Public Property ClienteCelular As String = ""
    Public Property LinkCliente As String = ""
    Public Property LinkClienteCorto As String = ""
    Public Property LinkInterno As String = ""
    Public Property LinkInternoCorto As String = ""
    Public Property MensajeSugerido As String = ""
    Public Property FechaExpiracion As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Dim idStr As String = Request.QueryString("id")
            
            If String.IsNullOrEmpty(idStr) Then
                Response.Redirect("PrePedidos.aspx")
                Return
            End If

            Dim id As Integer = 0
            If Not Integer.TryParse(idStr, id) OrElse id <= 0 Then
                Response.Redirect("PrePedidos.aspx")
                Return
            End If

            CargarDatos(id)
        End If
    End Sub

    Private Sub CargarDatos(prepedidoId As Integer)
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Dim sql As String = "SELECT codigo, cliente_nombre, cliente_apellidos, cliente_celular, token_web, token_expira " &
                    "FROM FLORERIA_PrePedido WHERE prepedido_id = @id"

                Using cmd As New SqlCommand(sql, conn)
                    cmd.Parameters.AddWithValue("@id", prepedidoId)

                    Using dr As SqlDataReader = cmd.ExecuteReader()
                        If dr.Read() Then
                            Codigo = dr("codigo").ToString()
                            
                            Dim nombre As String = If(IsDBNull(dr("cliente_nombre")), "", dr("cliente_nombre").ToString())
                            Dim apellidos As String = If(IsDBNull(dr("cliente_apellidos")), "", dr("cliente_apellidos").ToString())
                            
                            If nombre.Trim() <> "" Then
                                ClienteNombre = nombre.Trim()
                                If apellidos.Trim() <> "" Then
                                    ClienteNombre &= " " & apellidos.Trim()
                                End If
                            Else
                                ClienteNombre = "Cliente"
                            End If
                            
                            ' Normalizar celular para WhatsApp (quitar espacios, guiones, paréntesis)
                            Dim celularRaw As String = dr("cliente_celular").ToString()
                            ClienteCelular = celularRaw.Replace(" ", "").Replace("-", "").Replace("(", "").Replace(")", "").Replace("+", "")
                            
                            ' Si es un número boliviano (empieza con 6 o 7 y tiene 8 dígitos), agregar 591
                            If ClienteCelular.Length = 8 AndAlso (ClienteCelular.StartsWith("6") OrElse ClienteCelular.StartsWith("7")) Then
                                ClienteCelular = "591" & ClienteCelular
                            End If
                            
                            ' Si es peruano (empieza con 9 y tiene 9 dígitos), agregar 51
                            If ClienteCelular.Length = 9 AndAlso ClienteCelular.StartsWith("9") Then
                                ClienteCelular = "51" & ClienteCelular
                            End If
                            
                            Dim token As String = ""
                            If Not IsDBNull(dr("token_web")) Then
                                token = dr("token_web").ToString()
                            End If
                            
                            ' ============================================================
                            ' GENERAR LINKS CORRECTOS PARA WHATSAPP
                            ' ============================================================
                            
                            If token <> "" Then
                                ' Link cliente (formulario web)
                                ' CORREGIDO: https:// + www. para que WhatsApp lo detecte
                                LinkCliente = "https://www.floreria.somee.com/formulario.aspx?t=" & token
                                LinkClienteCorto = "floreria.somee.com/formulario"
                                
                                ' Link interno (sistema) - PARA SOMEE.COM
                                ' CORREGIDO: https:// + www. para que WhatsApp lo detecte
                                LinkInterno = "https://www.floreria.somee.com/pp.aspx?c=" & Codigo
                                LinkInternoCorto = "floreria.somee.com/pp?c=" & Codigo
                                
                                ' Fecha expiracion
                                If Not IsDBNull(dr("token_expira")) Then
                                    Dim expira As DateTime = CDate(dr("token_expira"))
                                    FechaExpiracion = expira.ToString("dd/MM/yyyy HH:mm")
                                Else
                                    FechaExpiracion = "48 horas"
                                End If
                                
                                ' ============================================================
                                ' MENSAJE SUGERIDO PARA WHATSAPP (SIN EMOJIS)
                                ' ============================================================
                                MensajeSugerido = "Hola " & ClienteNombre & "!" & vbCrLf & vbCrLf &
                                                 "Tu pre-pedido " & Codigo & " esta listo." & vbCrLf & vbCrLf &
                                                 "Por favor completa tu pedido aqui:" & vbCrLf &
                                                 LinkCliente & vbCrLf & vbCrLf &
                                                 "Valido hasta: " & FechaExpiracion & vbCrLf & vbCrLf &
                                                 "Cualquier duda, estamos para ayudarte!"
                            Else
                                ' Si no hay token, generar uno
                                GenerarToken(prepedidoId)
                                ' Recargar la pagina para mostrar el token nuevo
                                Response.Redirect("PrePedido_Links.aspx?id=" & prepedidoId)
                            End If
                        Else
                            Response.Redirect("PrePedidos.aspx")
                        End If
                    End Using
                End Using
            End Using

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR PrePedido_Links.CargarDatos: " & ex.Message)
            Response.Redirect("PrePedidos.aspx?error=" & Server.UrlEncode(ex.Message))
        End Try
    End Sub

    Private Sub GenerarToken(prepedidoId As Integer)
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()

                Using cmd As New SqlCommand("FLORERIA_sp_PrePedido_GenerarLink", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@prepedido_id", prepedidoId)
                    cmd.Parameters.AddWithValue("@moneda_formulario", "BOB")
                    cmd.Parameters.AddWithValue("@descuento_bs", 0)
                    cmd.Parameters.AddWithValue("@descuento_motivo", DBNull.Value)
                    cmd.Parameters.AddWithValue("@modificado_por", SesionHelper.ObtenerUsuarioId(HttpContext.Current))
                    cmd.Parameters.AddWithValue("@ip", Request.UserHostAddress)

                    Dim pToken As New SqlParameter("@token", SqlDbType.VarChar, 100)
                    pToken.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(pToken)

                    Dim pUrl As New SqlParameter("@url_completa", SqlDbType.VarChar, 500)
                    pUrl.Direction = ParameterDirection.Output
                    cmd.Parameters.Add(pUrl)

                    cmd.ExecuteNonQuery()
                End Using
            End Using

        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR PrePedido_Links.GenerarToken: " & ex.Message)
        End Try
    End Sub

End Class
