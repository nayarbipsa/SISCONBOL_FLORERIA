Imports System.Data
Imports System.Data.SqlClient
Imports System.Text
Imports System.Web

Partial Public Class Modulos_Pedidos_TicketImprimir
    Inherits System.Web.UI.Page

    ' Propiedades publicas para el .aspx
    Public Property CodigoPedido As String = ""
    Public Property CodigoPrePedido As String = ""
    Public Property WcOrderNumber As String = ""
    
    Public Property EstadoPago As String = ""
    Public Property EstadoOperativo As String = ""
    Public Property EsExpress As Boolean = False
    
    Public Property FechaEntrega As String = ""
    Public Property SlotEtiqueta As String = ""
    Public Property TipoOcasion As String = ""
    
    Public Property ReceptorNombre As String = ""
    Public Property ReceptorCelular As String = ""
    Public Property Direccion As String = ""
    Public Property Referencia As String = ""
    Public Property Zona As String = ""
    Public Property Ciudad As String = ""
    Public Property Gps As String = ""
    
    Public Property ProductosHtml As String = ""
    
    Public Property SubtotalProductos As Decimal = 0
    Public Property EnvioBs As Decimal = 0
    Public Property RecargoExpress As Decimal = 0
    Public Property RecargoHorario As Decimal = 0
    Public Property DescuentoBs As Decimal = 0
    Public Property TotalBs As Decimal = 0
    
    Public Property Dedicatoria As String = ""
    Public Property FirmaTarjeta As String = ""
    Public Property NotaFloreria As String = ""
    
    Public Property DeliveryNombre As String = ""
    
    Public Property FechaImpresion As String = ""
    Public Property ImpresoPor As String = ""

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not SesionHelper.VerificarSesion(Context) Then
            Response.Redirect("~/Login.aspx")
            Return
        End If

        Dim idStr As String = Request.QueryString("id")
        Dim pedidoId As Integer = 0
        If idStr Is Nothing OrElse Not Integer.TryParse(idStr, pedidoId) OrElse pedidoId <= 0 Then
            Response.Write("Pedido invalido")
            Response.End()
            Return
        End If

        Try
            CargarPedido(pedidoId)
            MarcarComoImpreso(pedidoId)
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("ERROR TicketImprimir: " & ex.Message)
            Response.Write("Error: " & ex.Message)
            Response.End()
        End Try
    End Sub

    Private Sub CargarPedido(pedidoId As Integer)
        Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
            conn.Open()
            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_ObtenerParaTicket", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@pedido_id", pedidoId)
                
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    ' 1. CABECERA
                    If dr.Read() Then
                        CodigoPedido = LeerStr(dr, "codigo_pedido")
                        CodigoPrePedido = LeerStr(dr, "codigo_prepedido")
                        WcOrderNumber = LeerStr(dr, "wc_order_number")
                        
                        EstadoPago = LeerStr(dr, "estado_pago")
                        EstadoOperativo = LeerStr(dr, "estado_operativo")
                        EsExpress = LeerBool(dr, "es_express")
                        
                        Dim fEntrega As DateTime = LeerFecha(dr, "fecha_entrega")
                        If fEntrega <> DateTime.MinValue Then
                            FechaEntrega = fEntrega.ToString("dd/MM/yyyy") & " (" & ObtenerDiaSemana(fEntrega) & ")"
                        End If
                        
                        Dim slotEtq As String = LeerStr(dr, "slot_etiqueta")
                        Dim slotIni As String = LeerHora(dr, "slot_hora_inicio")
                        Dim slotFin As String = LeerHora(dr, "slot_hora_fin")
                        If slotIni <> "" AndAlso slotFin <> "" Then
                            SlotEtiqueta = slotIni & " - " & slotFin
                            If slotEtq <> "" Then SlotEtiqueta &= " (" & slotEtq & ")"
                        ElseIf slotEtq <> "" Then
                            SlotEtiqueta = slotEtq
                        End If
                        
                        TipoOcasion = LeerStr(dr, "tipo_ocacion")
                        
                        ReceptorNombre = LeerStr(dr, "receptor_nombre")
                        ReceptorCelular = LeerStr(dr, "receptor_celular")
                        Direccion = LeerStr(dr, "direccion")
                        Referencia = LeerStr(dr, "referencia")
                        Zona = LeerStr(dr, "zona_nombre")
                        Ciudad = LeerStr(dr, "ciudad_nombre")
                        Gps = LeerStr(dr, "gps")
                        
                        SubtotalProductos = LeerDec(dr, "subtotal_productos_bs")
                        EnvioBs = LeerDec(dr, "envio_bs")
                        RecargoExpress = LeerDec(dr, "recargo_express_bs")
                        RecargoHorario = LeerDec(dr, "recargo_horario_bs")
                        DescuentoBs = LeerDec(dr, "descuento_bs")
                        TotalBs = LeerDec(dr, "total_bs")
                        
                        Dedicatoria = LeerStr(dr, "dedicatoria")
                        FirmaTarjeta = LeerStr(dr, "firma_tarjeta")
                        NotaFloreria = LeerStr(dr, "nota_floreria")
                        
                        DeliveryNombre = LeerStr(dr, "delivery_nombre")
                    End If
                    
                    ' 2. PRODUCTOS
                    Dim sbProd As New StringBuilder()
                    If dr.NextResult() Then
                        While dr.Read()
                            Dim nombre As String = LeerStr(dr, "nombre_producto")
                            Dim descripcion As String = LeerStr(dr, "descripcion")
                            Dim cantidad As Integer = LeerInt(dr, "cantidad")
                            Dim subtotal As Decimal = LeerDec(dr, "subtotal_bs")
                            Dim personalizacion As String = LeerStr(dr, "personalizacion")
                            
                            sbProd.Append("<div class=""product"">")
                            sbProd.Append("<div class=""product-line"">")
                            sbProd.Append("<span class=""product-name""><strong>" & cantidad & "x</strong> " & HE(nombre) & "</span>")
                            sbProd.Append("<span>Bs " & subtotal.ToString("N2") & "</span>")
                            sbProd.Append("</div>")
                            If descripcion <> "" Then
                                sbProd.Append("<div class=""product-extra"">" & HE(descripcion) & "</div>")
                            End If
                            If personalizacion <> "" Then
                                sbProd.Append("<div class=""product-extra"">Nota: " & HE(personalizacion) & "</div>")
                            End If
                            sbProd.Append("</div>")
                        End While
                    End If
                    ProductosHtml = sbProd.ToString()
                End Using
            End Using
        End Using
        
        ' Datos de impresion
        FechaImpresion = DateTime.Now.ToString("dd/MM/yyyy HH:mm")
        ImpresoPor = SesionHelper.ObtenerUsuarioNombre(Context)
    End Sub

    Private Sub MarcarComoImpreso(pedidoId As Integer)
        Try
            Dim usuarioId As Integer = SesionHelper.ObtenerUsuarioId(Context)
            Dim ip As String = Request.ServerVariables("REMOTE_ADDR")
            If ip Is Nothing Then ip = ""
            
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Pedido_MarcarImpreso", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@pedido_id", pedidoId)
                    cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
                    cmd.Parameters.AddWithValue("@ip", ip)
                    cmd.ExecuteNonQuery()
                End Using
            End Using
        Catch ex As Exception
            ' Solo log, no romper la impresion
            System.Diagnostics.Debug.WriteLine("WARN MarcarComoImpreso: " & ex.Message)
        End Try
    End Sub

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Function LeerStr(dr As SqlDataReader, campo As String) As String
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return ""
            Return dr(idx).ToString()
        Catch
            Return ""
        End Try
    End Function

    Private Function LeerInt(dr As SqlDataReader, campo As String) As Integer
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return 0
            Return CInt(dr(idx))
        Catch
            Return 0
        End Try
    End Function

    Private Function LeerDec(dr As SqlDataReader, campo As String) As Decimal
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return 0D
            Return CDec(dr(idx))
        Catch
            Return 0D
        End Try
    End Function

    Private Function LeerBool(dr As SqlDataReader, campo As String) As Boolean
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return False
            Return CBool(dr(idx))
        Catch
            Return False
        End Try
    End Function

    Private Function LeerFecha(dr As SqlDataReader, campo As String) As DateTime
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return DateTime.MinValue
            Return CDate(dr(idx))
        Catch
            Return DateTime.MinValue
        End Try
    End Function

    Private Function LeerHora(dr As SqlDataReader, campo As String) As String
        Try
            Dim idx As Integer = dr.GetOrdinal(campo)
            If dr.IsDBNull(idx) Then Return ""
            Dim val As Object = dr(idx)
            If TypeOf val Is TimeSpan Then
                Dim ts As TimeSpan = CType(val, TimeSpan)
                Return ts.Hours.ToString("D2") & ":" & ts.Minutes.ToString("D2")
            End If
            Return val.ToString()
        Catch
            Return ""
        End Try
    End Function

    Private Function HE(texto As String) As String
        If texto Is Nothing Then Return ""
        Return HttpUtility.HtmlEncode(texto)
    End Function

    Private Function ObtenerDiaSemana(fecha As DateTime) As String
        Select Case fecha.DayOfWeek
            Case DayOfWeek.Monday : Return "Lun"
            Case DayOfWeek.Tuesday : Return "Mar"
            Case DayOfWeek.Wednesday : Return "Mie"
            Case DayOfWeek.Thursday : Return "Jue"
            Case DayOfWeek.Friday : Return "Vie"
            Case DayOfWeek.Saturday : Return "Sab"
            Case DayOfWeek.Sunday : Return "Dom"
            Case Else : Return ""
        End Select
    End Function

End Class
