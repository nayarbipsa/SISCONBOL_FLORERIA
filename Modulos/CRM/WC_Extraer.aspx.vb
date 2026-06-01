Imports System.Web

' ============================================================
' SISCONBOL_FLORERIA - WC_Extraer (code-behind)
' Extraccion del espejo crudo de WooCommerce. Todo server-side
' para que se pueda depurar y procesar por tramos.
' La sesion y el menu los maneja Site.Master (no aqui).
' ============================================================
Partial Public Class Modulos_CRM_WC_Extraer
    Inherits System.Web.UI.Page

    ' Filtros (se conservan en postback)
    Public Property Desde As String = ""
    Public Property Hasta As String = ""

    ' Resultado renderizado con <%= %>
    Public Property ResultadoDisplay As String = "display:none"
    Public Property RTotal As String = "0"
    Public Property RNuevos As String = "0"
    Public Property RActualizados As String = "0"
    Public Property RErrores As String = "0"
    Public Property RLog As String = ""

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            Desde = DateTime.Now.AddYears(-1).ToString("yyyy-MM-dd")
            Hasta = DateTime.Now.ToString("yyyy-MM-dd")
        Else
            Desde = LeerForm("txDesde")
            Hasta = LeerForm("txHasta")
        End If
    End Sub

    Protected Sub btnAccion_Click(sender As Object, e As EventArgs)
        Dim accion As String = LeerForm("hdAccion").Trim().ToUpper()
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)

        Select Case accion
            Case "ORDENES"
                Dim status As String = LeerForm("selStatus")
                Dim r As CrmWcExtractor.Resultado = CrmWcExtractor.ExtraerOrdenes(Desde, Hasta, status, uid)
                Pintar(r)
            Case "PRODUCTOS"
                Pintar(CrmWcExtractor.ExtraerProductos(uid))
            Case "CATEGORIAS"
                Pintar(CrmWcExtractor.ExtraerCategorias(uid))
            Case "RECALCULAR"
                Dim n As Integer = CrmWcExtractor.RecalcularClientes()
                Dim r As New CrmWcExtractor.Resultado()
                r.Ok = True
                r.Total = n
                r.Log = "Recalculo completado. " & n & " clientes en la base de analisis."
                Pintar(r)
        End Select
    End Sub

    Private Sub Pintar(r As CrmWcExtractor.Resultado)
        ResultadoDisplay = ""
        RTotal = r.Total.ToString()
        RNuevos = r.Nuevos.ToString()
        RActualizados = r.Actualizados.ToString()
        RErrores = r.Errores.ToString()
        RLog = Server.HtmlEncode(r.Log)
    End Sub

    Private Function LeerForm(campo As String) As String
        Dim v As String = Request.Form(campo)
        If v Is Nothing Then Return ""
        Return v
    End Function

End Class
