Imports System.Data
Imports System.Data.SqlClient
Imports System.Web.Script.Serialization

Partial Public Class _Default
    Inherits System.Web.UI.Page

    Public Property TotalPrePedidos As String = "0"
    Public Property PrePedidosHoy As String = "+0 hoy"
    Public Property VentasHoy As String = "0.00"
    Public Property VentasIncremento As String = "+0 Bs"
    Public Property PorEntregar As String = "0"
    Public Property PendientesPago As String = "0"
    Public Property PorVencer As String = "0 por vencer"
    Public Property JsonPrePedidosRecientes As String = ""
    Public Property JsonPedidosRecientes As String = ""

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            CargarEstadisticas()
            CargarPrePedidosRecientes()
            CargarPedidosRecientes()
        End If
    End Sub

    ' ============================================================
    ' ESTADÍSTICAS (sin cambios respecto a versión anterior)
    ' ============================================================
    Private Sub CargarEstadisticas()
        Dim conn As SqlConnection = Nothing
        Dim cmd As SqlCommand = Nothing
        Dim reader As SqlDataReader = Nothing

        Try
            conn = New SqlConnection(SesionHelper.ObtenerCadena())
            cmd = New SqlCommand("FLORERIA_sp_Dashboard_Estadisticas", conn)
            cmd.CommandType = CommandType.StoredProcedure

            Dim usuarioId As Integer = ObtenerUsuarioId()
            cmd.Parameters.AddWithValue("@usuario_id", usuarioId)

            conn.Open()
            reader = cmd.ExecuteReader()

            If reader.Read() Then
                Dim totalPP As Integer = LeerInt(reader, "total_prepedidos")
                Dim ppHoy As Integer = LeerInt(reader, "prepedidos_hoy")
                Dim ventasHoyVal As Decimal = LeerDecimal(reader, "ventas_hoy_bs")
                Dim ventasAyer As Decimal = LeerDecimal(reader, "ventas_ayer_bs")
                Dim porEntregarVal As Integer = LeerInt(reader, "por_entregar_manana")
                Dim pendPagoVal As Integer = LeerInt(reader, "pendientes_pago")
                Dim porVencerVal As Integer = LeerInt(reader, "por_vencer_48h")

                TotalPrePedidos = totalPP.ToString()
                PrePedidosHoy = If(ppHoy > 0, "+" & ppHoy.ToString() & " hoy", "Sin nuevos hoy")

                VentasHoy = ventasHoyVal.ToString("N2")
                Dim incremento As Decimal = ventasHoyVal - ventasAyer
                If incremento > 0 Then
                    VentasIncremento = "+" & incremento.ToString("N2") & " Bs"
                ElseIf incremento < 0 Then
                    VentasIncremento = incremento.ToString("N2") & " Bs"
                Else
                    VentasIncremento = "Sin cambios"
                End If

                PorEntregar = porEntregarVal.ToString()
                PendientesPago = pendPagoVal.ToString()
                PorVencer = If(porVencerVal > 0, porVencerVal.ToString() & " por vencer", "Ninguno por vencer")
            End If

        Catch ex As SqlException
            TotalPrePedidos = "Error"
            VentasHoy = "Error"
        Finally
            If reader IsNot Nothing Then reader.Close()
            If conn IsNot Nothing Then conn.Close()
        End Try
    End Sub

    ' ============================================================
    ' PRE-PEDIDOS RECIENTES
    ' Usa FLORERIA_sp_Dashboard_PrePedidosRecientes
    ' Devuelve: prepedido_id, codigo, tipo_registro, cliente_celular,
    '           cliente_nombre, cliente_apellidos, estado,
    '           token_web, token_expira, total_general_bs,
    '           creado_en, estado_pago, pago_verificado_por
    ' ============================================================
    Private Sub CargarPrePedidosRecientes()
        Dim conn As SqlConnection = Nothing
        Dim cmd As SqlCommand = Nothing
        Dim reader As SqlDataReader = Nothing
        Dim lista As New List(Of PrePedidoItem)()

        Try
            conn = New SqlConnection(SesionHelper.ObtenerCadena())
            cmd = New SqlCommand("FLORERIA_sp_Dashboard_PrePedidosRecientes", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@usuario_id", ObtenerUsuarioId())
            cmd.Parameters.AddWithValue("@cantidad", 6)

            conn.Open()
            reader = cmd.ExecuteReader()

            While reader.Read()
                Dim item As New PrePedidoItem()
                item.prepedido_id = LeerInt(reader, "prepedido_id")
                item.codigo = reader("codigo").ToString()
                item.cliente_celular = reader("cliente_celular").ToString()
                item.estado = reader("estado").ToString()
                item.total_general_bs = LeerDecimal(reader, "total_general_bs")
                item.estado_pago = reader("estado_pago").ToString()

                ' Nombre completo
                Dim nombre As String = ""
                If Not IsDBNull(reader("cliente_nombre")) Then
                    nombre = reader("cliente_nombre").ToString().Trim()
                End If
                If Not IsDBNull(reader("cliente_apellidos")) AndAlso reader("cliente_apellidos").ToString().Trim() <> "" Then
                    nombre = (nombre & " " & reader("cliente_apellidos").ToString().Trim()).Trim()
                End If
                item.cliente_nombre = If(nombre = "", Nothing, nombre)

                ' Token
                If Not IsDBNull(reader("token_web")) Then
                    item.token_web = reader("token_web").ToString()
                End If
                If Not IsDBNull(reader("token_expira")) Then
                    item.token_expira = Convert.ToDateTime(reader("token_expira")).ToString("yyyy-MM-ddTHH:mm:ss")
                End If

                ' Quien verificó el pago
                If Not IsDBNull(reader("pago_verificado_por")) Then
                    item.pago_verificado_por = reader("pago_verificado_por").ToString()
                End If

                ' creado_en
                item.creado_en = Convert.ToDateTime(reader("creado_en")).ToString("yyyy-MM-ddTHH:mm:ss")

                lista.Add(item)
            End While

            Dim serializer As New JavaScriptSerializer()
            JsonPrePedidosRecientes = serializer.Serialize(lista)

        Catch ex As SqlException
            JsonPrePedidosRecientes = "[]"
        Finally
            If reader IsNot Nothing Then reader.Close()
            If conn IsNot Nothing Then conn.Close()
        End Try
    End Sub

    ' ============================================================
    ' PEDIDOS RECIENTES
    ' Usa FLORERIA_sp_Dashboard_PedidosRecientes
    ' Devuelve: pedido_id, codigo, receptor_nombre, receptor_celular,
    '           fecha_entrega, es_express, total_bs, anticipo_bs,
    '           saldo_bs, estado_pago, origen, wc_order_number,
    '           prepedido_codigo, zona_nombre, creado_en
    ' ============================================================
    Private Sub CargarPedidosRecientes()
        Dim conn As SqlConnection = Nothing
        Dim cmd As SqlCommand = Nothing
        Dim reader As SqlDataReader = Nothing
        Dim lista As New List(Of PedidoItem)()

        Try
            conn = New SqlConnection(SesionHelper.ObtenerCadena())
            cmd = New SqlCommand("FLORERIA_sp_Dashboard_PedidosRecientes", conn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.AddWithValue("@usuario_id", ObtenerUsuarioId())
            cmd.Parameters.AddWithValue("@cantidad", 5)

            conn.Open()
            reader = cmd.ExecuteReader()

            While reader.Read()
                Dim item As New PedidoItem()
                item.pedido_id = LeerInt(reader, "pedido_id")
                item.codigo = reader("codigo").ToString()
                item.receptor_nombre = reader("receptor_nombre").ToString()
                item.receptor_celular = reader("receptor_celular").ToString()
                item.fecha_entrega = Convert.ToDateTime(reader("fecha_entrega")).ToString("yyyy-MM-dd")
                item.es_express = Convert.ToBoolean(reader("es_express"))
                item.total_bs = LeerDecimal(reader, "total_bs")
                item.anticipo_bs = LeerDecimal(reader, "anticipo_bs")
                item.saldo_bs = LeerDecimal(reader, "saldo_bs")
                item.estado_pago = reader("estado_pago").ToString()
                item.origen = reader("origen").ToString()
                item.creado_en = Convert.ToDateTime(reader("creado_en")).ToString("yyyy-MM-ddTHH:mm:ss")

                If Not IsDBNull(reader("wc_order_number")) Then
                    item.wc_order_number = reader("wc_order_number").ToString()
                End If
                If Not IsDBNull(reader("prepedido_codigo")) Then
                    item.prepedido_codigo = reader("prepedido_codigo").ToString()
                End If
                If Not IsDBNull(reader("zona_nombre")) Then
                    item.zona_nombre = reader("zona_nombre").ToString()
                End If

                lista.Add(item)
            End While

            Dim serializer As New JavaScriptSerializer()
            JsonPedidosRecientes = serializer.Serialize(lista)

        Catch ex As SqlException
            JsonPedidosRecientes = "[]"
        Finally
            If reader IsNot Nothing Then reader.Close()
            If conn IsNot Nothing Then conn.Close()
        End Try
    End Sub

    ' ============================================================
    ' HELPERS
    ' ============================================================
    Private Function ObtenerUsuarioId() As Integer
        If Session("usuario_id") IsNot Nothing Then
            Return Convert.ToInt32(Session("usuario_id"))
        End If
        Return 0
    End Function

    Private Function LeerInt(ByVal reader As SqlDataReader, ByVal col As String) As Integer
        If IsDBNull(reader(col)) Then Return 0
        Return Convert.ToInt32(reader(col))
    End Function

    Private Function LeerDecimal(ByVal reader As SqlDataReader, ByVal col As String) As Decimal
        If IsDBNull(reader(col)) Then Return 0D
        Return Convert.ToDecimal(reader(col))
    End Function

    ' ============================================================
    ' CLASES DE DATOS
    ' ============================================================
    Public Class PrePedidoItem
        Public Property prepedido_id As Integer
        Public Property codigo As String
        Public Property cliente_celular As String
        Public Property cliente_nombre As String
        Public Property estado As String
        Public Property token_web As String
        Public Property token_expira As String
        Public Property total_general_bs As Decimal
        Public Property estado_pago As String
        Public Property pago_verificado_por As String
        Public Property creado_en As String
    End Class

    Public Class PedidoItem
        Public Property pedido_id As Integer
        Public Property codigo As String
        Public Property receptor_nombre As String
        Public Property receptor_celular As String
        Public Property fecha_entrega As String
        Public Property es_express As Boolean
        Public Property total_bs As Decimal
        Public Property anticipo_bs As Decimal
        Public Property saldo_bs As Decimal
        Public Property estado_pago As String
        Public Property origen As String
        Public Property wc_order_number As String
        Public Property prepedido_codigo As String
        Public Property zona_nombre As String
        Public Property creado_en As String
    End Class

End Class
