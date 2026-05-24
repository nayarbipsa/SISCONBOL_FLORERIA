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

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            CargarEstadisticas()
            CargarPrePedidosRecientes()
        End If
    End Sub

    Private Sub CargarEstadisticas()
        Dim conn As SqlConnection = Nothing
        Dim cmd As SqlCommand = Nothing
        Dim reader As SqlDataReader = Nothing

        Try
            conn = New SqlConnection(SesionHelper.ObtenerCadena())
            cmd = New SqlCommand("FLORERIA_sp_Dashboard_Estadisticas", conn)
            cmd.CommandType = CommandType.StoredProcedure

            Dim usuarioId As Integer = 0
            If Session("usuario_id") IsNot Nothing Then
                usuarioId = Convert.ToInt32(Session("usuario_id"))
            End If

            cmd.Parameters.AddWithValue("@usuario_id", usuarioId)

            conn.Open()
            reader = cmd.ExecuteReader()

            If reader.Read() Then
                Dim totalPP As Integer = If(IsDBNull(reader("total_prepedidos")), 0, Convert.ToInt32(reader("total_prepedidos")))
                Dim ppHoy As Integer = If(IsDBNull(reader("prepedidos_hoy")), 0, Convert.ToInt32(reader("prepedidos_hoy")))
                Dim ventasHoyVal As Decimal = If(IsDBNull(reader("ventas_hoy_bs")), 0, Convert.ToDecimal(reader("ventas_hoy_bs")))
                Dim ventasAyer As Decimal = If(IsDBNull(reader("ventas_ayer_bs")), 0, Convert.ToDecimal(reader("ventas_ayer_bs")))
                Dim porEntregarVal As Integer = If(IsDBNull(reader("por_entregar_manana")), 0, Convert.ToInt32(reader("por_entregar_manana")))
                Dim pendPagoVal As Integer = If(IsDBNull(reader("pendientes_pago")), 0, Convert.ToInt32(reader("pendientes_pago")))
                Dim porVencerVal As Integer = If(IsDBNull(reader("por_vencer_48h")), 0, Convert.ToInt32(reader("por_vencer_48h")))

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

    Private Sub CargarPrePedidosRecientes()
        Dim conn As SqlConnection = Nothing
        Dim cmd As SqlCommand = Nothing
        Dim reader As SqlDataReader = Nothing
        Dim lista As New List(Of PrePedidoItem)()

        Try
            conn = New SqlConnection(SesionHelper.ObtenerCadena())
            cmd = New SqlCommand("FLORERIA_sp_PrePedido_ListarRecientes", conn)
            cmd.CommandType = CommandType.StoredProcedure

            Dim usuarioId As Integer = 0
            If Session("usuario_id") IsNot Nothing Then
                usuarioId = Convert.ToInt32(Session("usuario_id"))
            End If

            cmd.Parameters.AddWithValue("@usuario_id", usuarioId)
            cmd.Parameters.AddWithValue("@cantidad", 5)

            conn.Open()
            reader = cmd.ExecuteReader()

            While reader.Read()
                Dim item As New PrePedidoItem()
                item.prepedido_id = Convert.ToInt32(reader("prepedido_id"))
                item.codigo = reader("codigo").ToString()
                item.cliente_celular = reader("cliente_celular").ToString()
                
                Dim nombre As String = ""
                If Not IsDBNull(reader("cliente_nombre")) Then
                    nombre = reader("cliente_nombre").ToString().Trim()
                End If
                If Not IsDBNull(reader("cliente_apellidos")) AndAlso reader("cliente_apellidos").ToString().Trim() <> "" Then
                    nombre = nombre & " " & reader("cliente_apellidos").ToString().Trim()
                End If
                item.cliente_nombre = If(nombre.Trim() = "", Nothing, nombre.Trim())

                item.estado = reader("estado").ToString()
                item.total_bs = Convert.ToDecimal(reader("total_general_bs"))

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

    Public Class PrePedidoItem
        Public Property prepedido_id As Integer
        Public Property codigo As String
        Public Property cliente_celular As String
        Public Property cliente_nombre As String
        Public Property estado As String
        Public Property total_bs As Decimal
    End Class

End Class
