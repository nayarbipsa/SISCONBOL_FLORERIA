Imports System.Data
Imports System.Data.SqlClient
Imports System.Web
Imports System.Text
Imports System.Net
Imports System.IO
Imports System.Linq
Imports System.Web.UI.WebControls

' ============================================================
' SISCONBOL - Migracion masiva desde WooCommerce
' Archivo: Modulos/Config/Migrar.aspx.vb
' Mapeo basado en JSON real de miss-flores.com (Mayo 2026)
' ============================================================
Partial Public Class Modulos_Config_Migrar
    Inherits System.Web.UI.Page

    Public Property WcUrl As String = ""
    Public Property WcConsumerKey As String = ""
    Public Property WcConsumerSecret As String = ""
    Public Property FechaDesdeDefault As String = ""
    Public Property FechaHastaDefault As String = ""

    ' Propiedades del panel "Migracion 2" (renderizado HTML, sin controles asp)
    Public Property M2Desde As String = ""
    Public Property M2Hasta As String = ""
    Public Property M2Total As String = "0"
    Public Property M2Ok As String = "0"
    Public Property M2Pendientes As String = "0"
    Public Property M2Err As String = "0"
    Public Property M2ResumenDisplay As String = "display:none"
    Public Property M2TablaDisplay As String = "display:none"
    Public Property M2LogDisplay As String = "display:none"
    Public Property M2TablaHtml As String = ""
    Public Property M2LogHtml As String = ""
    Public Property M2BtnProcesarDisabled As String = "disabled"

    ' ============================================================
    ' Page_Load
    ' ============================================================
    Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load
        If Not IsPostBack Then
            CargarConfiguracion()
            FechaDesdeDefault = DateTime.Now.AddDays(-30).ToString("yyyy-MM-dd")
            FechaHastaDefault = DateTime.Now.ToString("yyyy-MM-dd")
            M2Desde = FechaDesdeDefault
            M2Hasta = FechaHastaDefault
        Else
            ' En postback: conservar lo que el usuario tenia en los inputs de fecha
            M2Desde = Request.Form("txM2Desde")
            M2Hasta = Request.Form("txM2Hasta")
            If M2Desde Is Nothing Then M2Desde = ""
            If M2Hasta Is Nothing Then M2Hasta = ""
            ' Y restaurar el resumen/tabla desde Session si ya hubo descarga previa
            M2_RestaurarEstadoDesdeSession()
        End If
    End Sub

    Private Sub CargarConfiguracion()
        WcUrl    = ValorConfig("WC_URL")
        WcConsumerKey    = ValorConfig("WC_CONSUMER_KEY")
        WcConsumerSecret = ValorConfig("WC_CONSUMER_SECRET")
        If WcUrl = "" OrElse WcConsumerKey = "" OrElse WcConsumerSecret = "" Then
            EscribirJS("cfgWarn", "mostrarAlerta('Configura las credenciales de WooCommerce en Configuracion.', 'warn');")
        End If
    End Sub

    Private Function ValorConfig(ByVal clave As String) As String
        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Using cmd As New SqlCommand("FLORERIA_sp_Config_Obtener", conn)
                    cmd.CommandType = CommandType.StoredProcedure
                    cmd.Parameters.AddWithValue("@clave", clave)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return r.ToString()
                End Using
            End Using
        Catch ex As Exception
            Log("ValorConfig", "ERROR leyendo clave '" & clave & "': " & ex.Message)
        End Try
        Return ""
    End Function

    ' ============================================================
    ' btnAccion_Click
    ' ============================================================
    Protected Sub btnAccion_Click(ByVal sender As Object, ByVal e As EventArgs)
        Dim accion As String = Request.Form("hdAccion")
        If accion Is Nothing Then accion = ""
        Select Case accion.Trim()
            Case "INSERTAR_CATEGORIAS" : ProcesarCategorias()
            Case "INSERTAR_PRODUCTOS"  : ProcesarProductos()
            Case "INSERTAR_PEDIDOS"    : ProcesarPedidos()
            Case "M2_DESCARGAR"        : M2_Descargar()
            Case "M2_PROCESAR_TODOS"   : M2_ProcesarTodos()
            Case "M2_PROCESAR_UNO"     : M2_ProcesarUno()
            Case "M2_LIMPIAR"          : M2_Limpiar()
        End Select
    End Sub

    ' ============================================================
    ' CATEGORIAS
    ' ============================================================
    Private Sub ProcesarCategorias()
        Dim lote As String = Request.Form("hdLote")
        Dim uid  As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        If lote Is Nothing OrElse lote.Trim() = "" Then
            EscribirJS("rcatsErr", "mostrarAlerta('ERROR: No se recibieron datos de categorias desde WooCommerce.', 'error');")
            Return
        End If
        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0
        Try
            Dim cats As List(Of WcCat) = ParsearCats(lote)
            If cats.Count = 0 Then
                EscribirJS("rcatsVacio", "mostrarAlerta('No se encontraron categorias validas en la respuesta de WooCommerce.', 'warn');")
                Return
            End If
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                For Each c In cats
                    Try
                        Dim r As String = InsertarCat(conn, c, uid)
                        If r = "I" Then ins += 1
                        If r = "A" Then act += 1
                        If r = "S" Then sin += 1
                        If r = "E" Then err += 1
                    Catch ex As Exception
                        err += 1
                        Log("InsertarCat", "ERROR en categoria WcId=" & c.WcId & " Nombre='" & c.Nombre & "': " & ex.Message)
                    End Try
                Next
            End Using
        Catch ex As Exception
            Log("ProcesarCategorias", "ERROR CRITICO: " & ex.Message)
            EscribirJS("rcatsExc", "mostrarAlerta('ERROR al procesar categorias: " & EscJs(ex.Message) & "', 'error');")
            Return
        End Try
        EscribirJS("rcats", "mostrarResultadoCats(" & ins & "," & act & "," & sin & "," & err & ");")
    End Sub

    ' ============================================================
    ' PRODUCTOS
    ' ============================================================
    Private Sub ProcesarProductos()
        Dim lote As String = Request.Form("hdLote")
        Dim uid  As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        If lote Is Nothing OrElse lote.Trim() = "" Then
            EscribirJS("rprodErr", "mostrarAlerta('ERROR: No se recibieron datos de productos desde WooCommerce.', 'error');")
            Return
        End If
        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0
        Try
            Dim prods As List(Of WcProd) = ParsearProds(lote)
            If prods.Count = 0 Then
                EscribirJS("rprodVacio", "mostrarAlerta('No se encontraron productos validos en la respuesta de WooCommerce.', 'warn');")
                Return
            End If
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                For Each p In prods
                    Try
                        Dim r As String = InsertarProd(conn, p, uid)
                        If r = "I" Then ins += 1
                        If r = "A" Then act += 1
                        If r = "S" Then sin += 1
                        If r = "E" Then err += 1
                    Catch ex As Exception
                        err += 1
                        Log("InsertarProd", "ERROR en producto WcId=" & p.WcId & " Nombre='" & p.Nombre & "': " & ex.Message)
                    End Try
                Next
            End Using
        Catch ex As Exception
            Log("ProcesarProductos", "ERROR CRITICO: " & ex.Message)
            EscribirJS("rprodExc", "mostrarAlerta('ERROR al procesar productos: " & EscJs(ex.Message) & "', 'error');")
            Return
        End Try
        EscribirJS("rprod", "mostrarResultadoProd(" & ins & "," & act & "," & sin & "," & err & ");")
    End Sub

    ' ============================================================
    ' PEDIDOS
    ' ============================================================
    Private Sub ProcesarPedidos()
        Dim lote As String = Request.Form("hdLote")
        Dim uid  As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Dim ip   As String  = If(Request.UserHostAddress Is Nothing, "", Request.UserHostAddress)
        If lote Is Nothing OrElse lote.Trim() = "" Then
            EscribirJS("rpedErr", "agregarLog('ERROR: No se recibieron datos de pedidos desde WooCommerce.', 'error'); finalizarMigracion(true);")
            Return
        End If
        Dim ins As Integer = 0, act As Integer = 0, sin As Integer = 0, err As Integer = 0
        Dim errDetalle As New StringBuilder()
        Try
            Dim pedidos As List(Of WcPedido) = ParsearPedidos(lote)
            If pedidos.Count = 0 Then
                EscribirJS("rpedVacio", "agregarLog('No se encontraron pedidos validos en el rango indicado.', 'warn'); finalizarMigracion(false);")
                Return
            End If

            ' IMPORTANTE: una conexion POR PEDIDO, no por lote
            ' Asi cada pedido libera sus locks inmediatamente al cerrar la conexion
            ' y si uno falla no afecta a los demas
            For Each p In pedidos
                Try
                    Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                        conn.Open()
                        Dim r As String = InsertarPedido(conn, p, uid, ip)
                        If r = "I" Then ins += 1
                        If r = "A" Then act += 1
                        If r = "S" Then sin += 1
                        If r = "E" Then
                            err += 1
                            errDetalle.Append("WC#" & p.WcId & " ")
                        End If
                    End Using
                Catch ex As Exception
                    err += 1
                    errDetalle.Append("WC#" & p.WcId & "(" & ex.Message.Substring(0, Math.Min(60, ex.Message.Length)) & ") ")
                    Log("InsertarPedido", "ERROR en pedido WcId=" & p.WcId & ": " & ex.Message)
                End Try
            Next
        Catch ex As Exception
            Log("ProcesarPedidos", "ERROR CRITICO: " & ex.Message)
            EscribirJS("rpedExc", "agregarLog('ERROR CRITICO: " & EscJs(ex.Message) & "', 'error'); finalizarMigracion(true);")
            Return
        End Try
        Dim jsExtra As String = ""
        If err > 0 AndAlso errDetalle.Length > 0 Then
            jsExtra = "console.error('Pedidos con error: " & EscJs(errDetalle.ToString()) & "');"
        End If
        EscribirJS("rped", jsExtra & "recibirResultadoLote(" & ins & "," & act & "," & sin & "," & err & ",'" & EscJs(errDetalle.ToString()) & "');")
    End Sub

    ' ============================================================
    ' MIGRACION 2 - handlers via btnPostBack + hidden fields
    ' Renderiza HTML en propiedades publicas, sin controles asp:*
    ' ============================================================

    ' Restaura los contadores/tabla/log desde Session en cada postback
    ' (porque el .aspx los renderiza con <%= ... %>)
    Private Sub M2_RestaurarEstadoDesdeSession()
        Dim pedidos As List(Of WcPedido) = TryCast(Session("M2_Pedidos"), List(Of WcPedido))
        If pedidos Is Nothing OrElse pedidos.Count = 0 Then
            M2BtnProcesarDisabled = "disabled"
            Return
        End If
        M2BtnProcesarDisabled = ""
        M2_PintarResumen()
        M2_PintarTabla()
        Dim logHtml As String = TryCast(Session("M2_LogHtml"), String)
        If logHtml IsNot Nothing AndAlso logHtml <> "" Then
            M2LogHtml = logHtml
            M2LogDisplay = ""
        End If
    End Sub

    ' --- Helper: pinta el bloque de 4 contadores leyendo Session ---
    Private Sub M2_PintarResumen()
        Dim pedidos As List(Of WcPedido) = TryCast(Session("M2_Pedidos"), List(Of WcPedido))
        Dim resultados As Dictionary(Of Integer, String) = TryCast(Session("M2_Resultados"), Dictionary(Of Integer, String))
        If pedidos Is Nothing Then Return
        Dim ok As Integer = 0, err As Integer = 0
        If resultados IsNot Nothing Then
            For Each kv In resultados
                If kv.Value.StartsWith("ERROR") Then err += 1 Else ok += 1
            Next
        End If
        M2Total       = pedidos.Count.ToString()
        M2Ok          = ok.ToString()
        M2Err         = err.ToString()
        M2Pendientes  = (pedidos.Count - ok - err).ToString()
        M2ResumenDisplay = ""
    End Sub

    ' --- Helper: pinta la tabla HTML de pedidos leyendo Session ---
    Private Sub M2_PintarTabla()
        Dim pedidos As List(Of WcPedido) = TryCast(Session("M2_Pedidos"), List(Of WcPedido))
        If pedidos Is Nothing OrElse pedidos.Count = 0 Then Return
        Dim resultados As Dictionary(Of Integer, String) = TryCast(Session("M2_Resultados"), Dictionary(Of Integer, String))
        If resultados Is Nothing Then resultados = New Dictionary(Of Integer, String)()

        Dim sb As New StringBuilder()
        sb.Append("<table class='grid-pedidos' style='width:100%;border-collapse:collapse'>")
        sb.Append("<thead><tr>")
        sb.Append("<th style='width:40px;text-align:center'>#</th>")
        sb.Append("<th style='width:80px'>WC #</th>")
        sb.Append("<th style='width:100px'>Estado</th>")
        sb.Append("<th>Receptor</th>")
        sb.Append("<th style='width:110px'>Fecha</th>")
        sb.Append("<th style='width:120px'>Hora</th>")
        sb.Append("<th>Pago</th>")
        sb.Append("<th style='width:90px;text-align:right'>Total</th>")
        sb.Append("<th style='width:120px'>Resultado</th>")
        sb.Append("<th style='width:100px;text-align:center'>Accion</th>")
        sb.Append("</tr></thead><tbody>")

        For idx As Integer = 0 To pedidos.Count - 1
            Dim p As WcPedido = pedidos(idx)
            Dim item As M2VistaItem = M2_AVistaItem(p)

            Dim rowStyle As String = ""
            Dim resultadoTxt As String = ""
            Dim resultadoTitle As String = ""
            If resultados.ContainsKey(p.WcId) Then
                Dim raw As String = resultados(p.WcId)
                Dim parts() As String = raw.Split(New Char() {"|"c}, 2)
                Dim accion As String = parts(0)
                Dim mensaje As String = If(parts.Length > 1, parts(1), "")
                resultadoTxt = accion
                If accion = "INSERT" OrElse accion = "UPDATE" Then
                    rowStyle = "background:#e8f5e9"
                ElseIf accion = "ERROR" Then
                    rowStyle = "background:#ffebee"
                    resultadoTitle = " title='" & Server.HtmlEncode(mensaje) & "'"
                End If
            End If

            sb.AppendFormat("<tr style='{0}'>", rowStyle)
            sb.AppendFormat("<td style='text-align:center'>{0}</td>", idx + 1)
            sb.AppendFormat("<td>{0}</td>", item.WcId)
            sb.AppendFormat("<td>{0}</td>", Server.HtmlEncode(item.WcOrderStatus))
            sb.AppendFormat("<td>{0}</td>", Server.HtmlEncode(item.ReceptorNombre))
            sb.AppendFormat("<td>{0}</td>", Server.HtmlEncode(item.FechaEntregaTexto))
            sb.AppendFormat("<td>{0}</td>", Server.HtmlEncode(item.HoraEntregaTexto))
            sb.AppendFormat("<td>{0}</td>", Server.HtmlEncode(item.MetodoPagoTexto))
            sb.AppendFormat("<td style='text-align:right'>{0:N2}</td>", item.TotalBs)
            sb.AppendFormat("<td><span{0}>{1}</span></td>", resultadoTitle, Server.HtmlEncode(resultadoTxt))
            sb.AppendFormat("<td style='text-align:center'><button type='button' class='btn btn-sm' style='padding:2px 8px;font-size:11px' onclick='m2ProcesarUno({0})'>Procesar</button></td>", idx)
            sb.Append("</tr>")
        Next

        sb.Append("</tbody></table>")
        M2TablaHtml = sb.ToString()
        M2TablaDisplay = ""
    End Sub

    ' --- Helper: guarda log en Session y lo pinta ---
    Private Sub M2_GuardarLog(html As String)
        Session("M2_LogHtml") = html
        M2LogHtml = html
        M2LogDisplay = ""
    End Sub

    Private Sub M2_MensajeLog(msg As String, tipo As String)
        Dim color As String = "#c9d1d9"
        If tipo = "error" Then color = "#ff7b72"
        If tipo = "ok"    Then color = "#7ee787"
        If tipo = "warn"  Then color = "#ffa657"
        If tipo = "info"  Then color = "#79c0ff"
        Dim html As String = "<div style='font-family:monospace;font-size:11px;background:#0d1117;color:#c9d1d9;padding:8px;border-radius:6px;max-height:300px;overflow-y:auto'>" &
                             "<div style='color:" & color & "'>[" & DateTime.Now.ToString("HH:mm:ss") & "] " & Server.HtmlEncode(msg) & "</div>" &
                             "</div>"
        M2_GuardarLog(html)
    End Sub

    ' ============================================================
    ' ACCION: Descargar pedidos desde WC
    ' ============================================================
    Private Sub M2_Descargar()
        Dim desde As String = Request.Form("txM2Desde")
        Dim hasta As String = Request.Form("txM2Hasta")
        If desde Is Nothing Then desde = ""
        If hasta Is Nothing Then hasta = ""
        desde = desde.Trim()
        hasta = hasta.Trim()
        M2Desde = desde
        M2Hasta = hasta

        Dim log As New StringBuilder()
        log.Append("<div style='font-family:monospace;font-size:11px;background:#0d1117;color:#c9d1d9;padding:8px;border-radius:6px;max-height:300px;overflow-y:auto'>")

        Try
            If desde = "" OrElse hasta = "" Then
                M2_MensajeLog("ERROR: Selecciona el rango de fechas.", "error")
                Return
            End If

            Dim url    As String = ValorConfig("WC_URL")
            Dim ckey   As String = ValorConfig("WC_CONSUMER_KEY")
            Dim csec   As String = ValorConfig("WC_CONSUMER_SECRET")
            If url = "" OrElse ckey = "" OrElse csec = "" Then
                M2_MensajeLog("ERROR: Faltan credenciales de WooCommerce en la configuracion.", "error")
                Return
            End If

            log.AppendFormat("<div style='color:#79c0ff'>[{0}] Descargando pedidos de {1} entre {2} y {3}...</div>",
                             DateTime.Now.ToString("HH:mm:ss"), Server.HtmlEncode(url), desde, hasta)

            Dim auth As String = Convert.ToBase64String(Encoding.UTF8.GetBytes(ckey & ":" & csec))

            Dim todos As New List(Of WcPedido)()
            Dim pagina As Integer = 1
            Dim continuar As Boolean = True

            While continuar AndAlso pagina <= 50
                Dim urlReq As String = url & "/wp-json/wc/v3/orders" &
                                       "?per_page=100&page=" & pagina &
                                       "&after="  & desde & "T00:00:00" &
                                       "&before=" & hasta & "T23:59:59" &
                                       "&status=any"
                Dim req As HttpWebRequest = DirectCast(WebRequest.Create(urlReq), HttpWebRequest)
                req.Method = "GET"
                req.Headers.Add("Authorization", "Basic " & auth)
                req.Timeout = 60000

                Try
                    Using resp As HttpWebResponse = DirectCast(req.GetResponse(), HttpWebResponse)
                        If resp.StatusCode <> HttpStatusCode.OK Then
                            log.AppendFormat("<div style='color:#ff7b72'>[{0}] HTTP {1} en pagina {2}</div>",
                                             DateTime.Now.ToString("HH:mm:ss"), CInt(resp.StatusCode), pagina)
                            Exit While
                        End If
                        Using sr As New StreamReader(resp.GetResponseStream())
                            Dim json As String = sr.ReadToEnd()
                            Dim parsed As List(Of WcPedido) = ParsearPedidos(json)
                            If parsed Is Nothing OrElse parsed.Count = 0 Then
                                continuar = False
                            Else
                                todos.AddRange(parsed)
                                log.AppendFormat("<div style='color:#8b949e'>[{0}] Pagina {1}: {2} pedidos (total {3})</div>",
                                                 DateTime.Now.ToString("HH:mm:ss"), pagina, parsed.Count, todos.Count)
                                If parsed.Count < 100 Then continuar = False
                            End If
                        End Using
                    End Using
                Catch wex As WebException
                    log.AppendFormat("<div style='color:#ff7b72'>[{0}] ERROR HTTP pagina {1}: {2}</div>",
                                     DateTime.Now.ToString("HH:mm:ss"), pagina, Server.HtmlEncode(wex.Message))
                    Exit While
                End Try

                pagina += 1
            End While

            ' --- Filtro: solo pedidos con fecha de entrega HOY o futura ---
            ' Los pasados o sin fecha no se sincronizan
            Dim hoy As DateTime = DateTime.Now.Date
            Dim descartados As Integer = 0
            Dim filtrados As New List(Of WcPedido)()
            For Each ped As WcPedido In todos
                Dim fechaRef As DateTime? = Nothing
                If ped.DeliveryDate.HasValue Then
                    fechaRef = ped.DeliveryDate.Value.Date
                ElseIf ped.PickupDate.HasValue Then
                    fechaRef = ped.PickupDate.Value.Date
                End If

                If fechaRef.HasValue AndAlso fechaRef.Value >= hoy Then
                    filtrados.Add(ped)
                Else
                    descartados += 1
                End If
            Next

            log.AppendFormat("<div style='color:#7ee787'>[{0}] Descarga completa: {1} pedidos totales, {2} con entrega hoy o futura, {3} descartados.</div>",
                             DateTime.Now.ToString("HH:mm:ss"), todos.Count, filtrados.Count, descartados)
            log.Append("</div>")

            Session("M2_Pedidos") = filtrados
            Session("M2_Resultados") = New Dictionary(Of Integer, String)()

            M2_GuardarLog(log.ToString())

            If filtrados.Count > 0 Then
                M2BtnProcesarDisabled = ""
                M2_PintarResumen()
                M2_PintarTabla()
            End If

        Catch ex As Exception
            log.AppendFormat("<div style='color:#ff7b72'>[{0}] ERROR CRITICO: {1}</div>",
                             DateTime.Now.ToString("HH:mm:ss"), Server.HtmlEncode(ex.Message))
            log.Append("</div>")
            M2_GuardarLog(log.ToString())
        End Try
    End Sub

    ' ============================================================
    ' ACCION: Procesar UN pedido
    ' ============================================================
    Private Sub M2_ProcesarUno()
        Dim idxStr As String = Request.Form("hdM2Indice")
        If idxStr Is Nothing Then idxStr = ""
        Dim idx As Integer = 0
        Integer.TryParse(idxStr.Trim(), idx)

        Dim pedidos As List(Of WcPedido) = TryCast(Session("M2_Pedidos"), List(Of WcPedido))
        If pedidos Is Nothing OrElse idx < 0 OrElse idx >= pedidos.Count Then
            M2_MensajeLog("ERROR: No hay pedidos en sesion. Descarga de nuevo.", "error")
            Return
        End If

        Dim p As WcPedido = pedidos(idx)
        Dim res As M2Resultado = M2_ProcesarPedidoEnTransaccion(p)

        Dim resultados As Dictionary(Of Integer, String) = TryCast(Session("M2_Resultados"), Dictionary(Of Integer, String))
        If resultados Is Nothing Then
            resultados = New Dictionary(Of Integer, String)()
            Session("M2_Resultados") = resultados
        End If
        resultados(p.WcId) = res.Accion & "|" & res.Mensaje

        M2_MensajeLog("WC#" & p.WcId & " -> " & res.Accion & " - " & res.Mensaje,
                      If(res.Accion = "ERROR", "error", "ok"))
        M2BtnProcesarDisabled = ""
        M2_PintarResumen()
        M2_PintarTabla()
    End Sub

    ' ============================================================
    ' ACCION: Procesar TODOS los pedidos descargados
    ' ============================================================
    Private Sub M2_ProcesarTodos()
        Dim pedidos As List(Of WcPedido) = TryCast(Session("M2_Pedidos"), List(Of WcPedido))
        If pedidos Is Nothing OrElse pedidos.Count = 0 Then
            M2_MensajeLog("ERROR: No hay pedidos descargados.", "error")
            Return
        End If

        Dim resultados As Dictionary(Of Integer, String) = TryCast(Session("M2_Resultados"), Dictionary(Of Integer, String))
        If resultados Is Nothing Then
            resultados = New Dictionary(Of Integer, String)()
            Session("M2_Resultados") = resultados
        End If

        Dim log As New StringBuilder()
        log.Append("<div style='font-family:monospace;font-size:11px;background:#0d1117;color:#c9d1d9;padding:8px;border-radius:6px;max-height:300px;overflow-y:auto'>")
        log.AppendFormat("<div style='color:#79c0ff'>[{0}] === INICIANDO PROCESAMIENTO DE {1} PEDIDOS ===</div>",
                         DateTime.Now.ToString("HH:mm:ss"), pedidos.Count)

        Dim cntOk As Integer = 0, cntErr As Integer = 0

        For idx As Integer = 0 To pedidos.Count - 1
            Dim p As WcPedido = pedidos(idx)
            Try
                Dim res As M2Resultado = M2_ProcesarPedidoEnTransaccion(p)
                resultados(p.WcId) = res.Accion & "|" & res.Mensaje
                Dim color As String = If(res.Accion = "ERROR", "#ff7b72", "#7ee787")
                log.AppendFormat("<div style='color:{0}'>[{1}] WC#{2} -> {3}: {4}</div>",
                                 color,
                                 DateTime.Now.ToString("HH:mm:ss"),
                                 p.WcId,
                                 res.Accion,
                                 Server.HtmlEncode(res.Mensaje))
                If res.Accion = "ERROR" Then cntErr += 1 Else cntOk += 1
            Catch ex As Exception
                cntErr += 1
                resultados(p.WcId) = "ERROR|" & ex.Message
                log.AppendFormat("<div style='color:#ff7b72'>[{0}] WC#{1} -> EXCEPCION: {2}</div>",
                                 DateTime.Now.ToString("HH:mm:ss"), p.WcId, Server.HtmlEncode(ex.Message))
            End Try
        Next

        log.AppendFormat("<div style='color:#7ee787;margin-top:6px'>[{0}] === FIN: {1} OK, {2} con errores ===</div>",
                         DateTime.Now.ToString("HH:mm:ss"), cntOk, cntErr)
        log.Append("</div>")

        M2_GuardarLog(log.ToString())
        M2BtnProcesarDisabled = ""
        M2_PintarResumen()
        M2_PintarTabla()
    End Sub

    ' ============================================================
    ' ACCION: Limpiar
    ' ============================================================
    Private Sub M2_Limpiar()
        Session("M2_Pedidos") = Nothing
        Session("M2_Resultados") = Nothing
        Session("M2_LogHtml") = Nothing
        M2Total = "0"
        M2Ok = "0"
        M2Pendientes = "0"
        M2Err = "0"
        M2ResumenDisplay = "display:none"
        M2TablaDisplay = "display:none"
        M2LogDisplay = "display:none"
        M2TablaHtml = ""
        M2LogHtml = ""
        M2BtnProcesarDisabled = "disabled"
    End Sub


    ' ============================================================
    ' Helper: convertir WcPedido a M2VistaItem (para GridView)
    ' ============================================================
    Private Function M2_AVistaItem(p As WcPedido) As M2VistaItem
        Dim item As New M2VistaItem()
        item.WcId           = p.WcId
        item.WcOrderStatus  = p.WcOrderStatus
        item.ReceptorNombre = If(p.ShippingNombre <> "", p.ShippingNombre, (p.BillingNombre & " " & p.BillingApellidos).Trim())

        If p.DeliveryDate.HasValue Then
            item.FechaEntregaTexto = p.DeliveryDate.Value.ToString("yyyy-MM-dd")
        ElseIf p.PickupDate.HasValue Then
            item.FechaEntregaTexto = p.PickupDate.Value.ToString("yyyy-MM-dd") & " (pickup)"
        Else
            item.FechaEntregaTexto = "(sin fecha)"
        End If

        If p.DeliveryTime <> "" Then
            item.HoraEntregaTexto = p.DeliveryTime
        ElseIf p.PickupTime <> "" Then
            item.HoraEntregaTexto = p.PickupTime & " (pickup)"
        Else
            item.HoraEntregaTexto = "(sin hora)"
        End If

        item.MetodoPagoTexto = If(p.PaymentMethodTitle <> "", p.PaymentMethodTitle, p.PaymentMethod)
        item.TotalBs = p.TotalBs
        Return item
    End Function

    ' ============================================================
    ' M2_ProcesarPedidoEnTransaccion - ejecuta UPSERT con transaccion
    ' Aqui es donde realmente pasa la migracion del pedido.
    ' BREAKPOINT 7 - inspecciona el pedido antes de procesarlo
    ' ============================================================
    Private Function M2_ProcesarPedidoEnTransaccion(p As WcPedido) As M2Resultado
        Dim res As New M2Resultado()
        res.Accion = "ERROR"
        Dim uid As Integer = SesionHelper.ObtenerUsuarioId(HttpContext.Current)
        Dim ip  As String  = If(Request.UserHostAddress Is Nothing, "", Request.UserHostAddress)

        Try
            Using conn As New SqlConnection(SesionHelper.ObtenerCadena())
                conn.Open()
                Dim tx As SqlTransaction = conn.BeginTransaction("M2_Uno")
                Try
                    res = M2_UpsertPedido(conn, tx, p, uid, ip)
                    If res.Accion = "ERROR" Then
                        tx.Rollback()
                        Log("M2_ProcesarPedidoEnTransaccion", "WC#" & p.WcId & " ROLLBACK: " & res.Mensaje)
                    Else
                        tx.Commit()
                        Log("M2_ProcesarPedidoEnTransaccion", "WC#" & p.WcId & " COMMIT (" & res.Accion & ") - " & res.Mensaje)
                    End If
                Catch ex As Exception
                    Try : tx.Rollback() : Catch : End Try
                    res.Accion = "ERROR"
                    res.Mensaje = ex.Message
                    Log("M2_ProcesarPedidoEnTransaccion", "WC#" & p.WcId & " ROLLBACK por excepcion: " & ex.Message)
                End Try
            End Using
        Catch ex As Exception
            res.Accion = "ERROR"
            res.Mensaje = "Conexion: " & ex.Message
            Log("M2_ProcesarPedidoEnTransaccion", "WC#" & p.WcId & " ERROR CONEXION: " & ex.Message)
        End Try

        Return res
    End Function

    Private Class M2VistaItem
        Public Property WcId As Integer
        Public Property WcOrderStatus As String
        Public Property ReceptorNombre As String
        Public Property FechaEntregaTexto As String
        Public Property HoraEntregaTexto As String
        Public Property MetodoPagoTexto As String
        Public Property TotalBs As Decimal
    End Class


    ' ============================================================
    ' M2_UpsertPedido - logica de UPSERT dentro de la transaccion
    '   Si NO existe → INSERT completo
    '   Si SI existe → UPDATE solo de: fecha_entrega, slot_id,
    '                  campos wc_* de pago, y reemplazo de line_items
    ' ============================================================
    Private Function M2_UpsertPedido(conn As SqlConnection, tx As SqlTransaction,
                                      p As WcPedido, uid As Integer, ip As String) As M2Resultado
        Dim res As New M2Resultado()
        res.Accion = "ERROR"

        Try
            ' --- 1. Buscar si existe ---
            Dim pedidoId As Integer = 0
            Using chk As New SqlCommand("SELECT pedido_id FROM FLORERIA_Pedido WHERE wc_order_id=@w", conn, tx)
                chk.CommandTimeout = 30
                chk.Parameters.AddWithValue("@w", p.WcId)
                Dim r As Object = chk.ExecuteScalar()
                If r IsNot Nothing AndAlso Not IsDBNull(r) Then pedidoId = CInt(r)
            End Using

            ' --- 2. Detectar pickup vs delivery y calcular fecha/slot ---
            Dim esPickup As Boolean = (p.DeliveryType.ToLower().Trim() = "pickup")
            Dim horarioStr As String = If(esPickup, p.PickupTime, p.DeliveryTime)
            Dim fechaParam As Object = DBNull.Value
            If esPickup AndAlso p.PickupDate.HasValue Then
                fechaParam = p.PickupDate.Value
            ElseIf p.DeliveryDate.HasValue Then
                fechaParam = p.DeliveryDate.Value
            ElseIf p.PickupDate.HasValue Then
                fechaParam = p.PickupDate.Value
            End If
            ' Si fechaParam es DBNull, NO se actualizara (preserva lo de BD)

            ' --- 3. Resolver slot_id (crear si no existe) ---
            Dim slotId As Object = DBNull.Value
            If horarioStr <> "" Then
                slotId = M2_ObtenerOCrearSlot(conn, tx, horarioStr)
            End If

            ' --- 4. Calcular datos de pago ---
            Dim methodLower As String = p.PaymentMethod.ToLower().Trim()
            Dim titleLower  As String = p.PaymentMethodTitle.ToLower().Trim()
            Dim esPayPal    As Boolean = methodLower.Contains("paypal") OrElse methodLower.Contains("ppcp") OrElse titleLower.Contains("paypal")
            Dim esLibelula  As Boolean = methodLower.Contains("libelula") OrElse titleLower.Contains("libelula")
            Dim estadoPago  As String = "PENDIENTE"
            If p.WcDatePaid.HasValue AndAlso (esPayPal OrElse esLibelula) Then estadoPago = "PAGADO"

            ' --- 5. INSERT o UPDATE ---
            If pedidoId > 0 Then
                ' ============================================================
                ' UPDATE — SOLO fecha, slot, datos WC de pago, estado_pago
                ' NO TOCA: direccion, receptor, dedicatoria, nota, tipo_entrega
                ' ============================================================
                Using upd As New SqlCommand(
                    "UPDATE FLORERIA_Pedido SET " &
                    "  fecha_entrega           = ISNULL(@fe, fecha_entrega), " &
                    "  slot_id                 = ISNULL(@sid, slot_id), " &
                    "  wc_order_status         = @wst, " &
                    "  wc_date_paid            = @wdp, " &
                    "  wc_date_modified        = @wdm, " &
                    "  wc_payment_method       = @wpm, " &
                    "  wc_payment_method_title = @wpmt, " &
                    "  wc_sync_estado          = 'SINCRONIZADO', " &
                    "  wc_sync_fecha           = GETDATE(), " &
                    "  estado_pago             = @ep, " &
                    "  modificado_por          = @u, " &
                    "  modificado_en           = GETDATE() " &
                    "WHERE pedido_id = @pid", conn, tx)
                    upd.CommandTimeout = 30
                    upd.Parameters.AddWithValue("@fe",   fechaParam)
                    upd.Parameters.AddWithValue("@sid",  slotId)
                    upd.Parameters.AddWithValue("@wst",  If(p.WcOrderStatus <> "",     CObj(p.WcOrderStatus),       DBNull.Value))
                    upd.Parameters.AddWithValue("@wdp",  If(p.WcDatePaid.HasValue,     CObj(p.WcDatePaid.Value),    DBNull.Value))
                    upd.Parameters.AddWithValue("@wdm",  If(p.WcDateModified.HasValue, CObj(p.WcDateModified.Value),DBNull.Value))
                    upd.Parameters.AddWithValue("@wpm",  If(p.PaymentMethod <> "",     CObj(p.PaymentMethod),       DBNull.Value))
                    upd.Parameters.AddWithValue("@wpmt", If(p.PaymentMethodTitle <> "",CObj(p.PaymentMethodTitle),  DBNull.Value))
                    upd.Parameters.AddWithValue("@ep",   estadoPago)
                    upd.Parameters.AddWithValue("@u",    uid)
                    upd.Parameters.AddWithValue("@pid",  pedidoId)
                    upd.ExecuteNonQuery()
                End Using

                ' --- Sincronizar pago en FLORERIA_Pedido_Pago ---
                M2_SincronizarPago(conn, tx, pedidoId, p, estadoPago, esPayPal, esLibelula, uid)

                ' --- Reemplazar line_items (borrar y volver a insertar) ---
                M2_ReemplazarDetalles(conn, tx, pedidoId, p)

                res.Accion = "UPDATE"
                res.Mensaje = "fecha=" & If(fechaParam Is DBNull.Value, "(no tocada)", DirectCast(fechaParam, DateTime).ToString("yyyy-MM-dd")) &
                              ", slot_id=" & If(slotId Is DBNull.Value, "(no tocado)", slotId.ToString()) &
                              ", estado_pago=" & estadoPago
            Else
                ' ============================================================
                ' INSERT — pedido nuevo
                ' ============================================================
                Dim tipoEntrega As String = If(esPickup, "RECOJO_SUCURSAL", "DOMICILIO")
                Dim direccion   As String = If(esPickup, "Recojo en sucursal", If(p.Direccion <> "", p.Direccion, "Sin direccion"))
                Dim receptor    As String = If(p.ShippingNombre <> "", p.ShippingNombre, If(p.BillingNombre <> "", (p.BillingNombre & " " & p.BillingApellidos).Trim(), "Sin nombre"))
                Dim celular     As String = If(p.ShippingPhone <> "", p.ShippingPhone, If(p.TelefonoRecibe <> "", p.TelefonoRecibe, If(p.BillingPhone <> "", p.BillingPhone, "00000000")))
                Dim fechaInsert As DateTime
                If fechaParam Is DBNull.Value Then
                    fechaInsert = If(p.WcDateCreated.HasValue, p.WcDateCreated.Value.Date, DateTime.Now.Date)
                Else
                    fechaInsert = DirectCast(fechaParam, DateTime)
                End If

                Dim zonaId As Object = DBNull.Value
                If Not esPickup AndAlso p.ShippingState <> "" Then
                    zonaId = M2_ObtenerOCrearZona(conn, tx, p.ShippingState)
                End If

                ' Totales y USD
                Dim tasa     As Decimal = If(p.WoocsRate > 0, p.WoocsRate, 0D)
                Dim totalUsd As Decimal = If(tasa > 0, Math.Round(p.TotalBs    * tasa, 2), 0D)
                Dim envioUsd As Decimal = If(tasa > 0, Math.Round(p.EnvioBs    * tasa, 2), 0D)
                Dim descUsd  As Decimal = If(tasa > 0, Math.Round(p.DescuentoBs * tasa, 2), 0D)

                Dim nuevoPedidoId As Integer = 0
                Using ins As New SqlCommand(
                    "INSERT INTO FLORERIA_Pedido(" &
                    "  codigo, wc_order_id, wc_order_number, wc_order_url, wc_order_status, " &
                    "  wc_date_paid, wc_date_modified, wc_payment_method, wc_payment_method_title, " &
                    "  receptor_nombre, receptor_celular, ciudad_id, zona_id, tipo_entrega, " &
                    "  direccion, fecha_entrega, slot_id, " &
                    "  dedicatoria, firma_tarjeta, tipo_ocacion, nota_floreria, gps, observaciones, " &
                    "  total_bs, total_usd, envio_bs, envio_usd, descuento_bs, descuento_usd, " &
                    "  estado_pago, estado_operativo, wc_sync_estado, wc_sync_fecha, " &
                    "  creado_por, creado_en) " &
                    "VALUES(" &
                    "  'TEMP', @wid, @wnum, @wurl, @wst, " &
                    "  @wdp, @wdm, @wpm, @wpmt, " &
                    "  @rn, @rc, 1, @zid, @te, " &
                    "  @dir, @fe, @sid, " &
                    "  @ded, @fir, @toc, @nf, @gps, @obs, " &
                    "  @tbs, @tusd, @ebs, @eusd, @dbs, @dusd, " &
                    "  @ep, 'PENDIENTE', 'SINCRONIZADO', GETDATE(), " &
                    "  @u, GETDATE()); SELECT SCOPE_IDENTITY();", conn, tx)
                    ins.CommandTimeout = 30
                    ins.Parameters.AddWithValue("@wid",  p.WcId)
                    ins.Parameters.AddWithValue("@wnum", If(p.WcOrderNumber <> "",      CObj(p.WcOrderNumber),       DBNull.Value))
                    ins.Parameters.AddWithValue("@wurl", If(p.WcOrderKey <> "",         CObj(p.WcOrderKey),          DBNull.Value))
                    ins.Parameters.AddWithValue("@wst",  If(p.WcOrderStatus <> "",      CObj(p.WcOrderStatus),       DBNull.Value))
                    ins.Parameters.AddWithValue("@wdp",  If(p.WcDatePaid.HasValue,      CObj(p.WcDatePaid.Value),    DBNull.Value))
                    ins.Parameters.AddWithValue("@wdm",  If(p.WcDateModified.HasValue,  CObj(p.WcDateModified.Value),DBNull.Value))
                    ins.Parameters.AddWithValue("@wpm",  If(p.PaymentMethod <> "",      CObj(p.PaymentMethod),       DBNull.Value))
                    ins.Parameters.AddWithValue("@wpmt", If(p.PaymentMethodTitle <> "", CObj(p.PaymentMethodTitle),  DBNull.Value))
                    ins.Parameters.AddWithValue("@rn",   receptor.Substring(0, Math.Min(200, receptor.Length)))
                    ins.Parameters.AddWithValue("@rc",   celular.Substring(0, Math.Min(20, celular.Length)))
                    ins.Parameters.AddWithValue("@zid",  zonaId)
                    ins.Parameters.AddWithValue("@te",   tipoEntrega)
                    ins.Parameters.AddWithValue("@dir",  direccion.Substring(0, Math.Min(300, direccion.Length)))
                    ins.Parameters.AddWithValue("@fe",   fechaInsert)
                    ins.Parameters.AddWithValue("@sid",  slotId)
                    ins.Parameters.AddWithValue("@ded",  If(p.MensajeTarjeta <> "", CObj(p.MensajeTarjeta), DBNull.Value))
                    ins.Parameters.AddWithValue("@fir",  If(p.FirmaTarjeta <> "",   CObj(p.FirmaTarjeta),   DBNull.Value))
                    ins.Parameters.AddWithValue("@toc",  MapearTipoOcacion(p.TipoOcacion))
                    ins.Parameters.AddWithValue("@nf",   If(p.NotaFloreria <> "",   CObj(p.NotaFloreria),   DBNull.Value))
                    ins.Parameters.AddWithValue("@gps",  If(p.Gps <> "",            CObj(p.Gps),            DBNull.Value))
                    ins.Parameters.AddWithValue("@obs",  If(p.Observaciones <> "",  CObj(p.Observaciones),  DBNull.Value))
                    ins.Parameters.AddWithValue("@tbs",  p.TotalBs)
                    ins.Parameters.AddWithValue("@tusd", totalUsd)
                    ins.Parameters.AddWithValue("@ebs",  p.EnvioBs)
                    ins.Parameters.AddWithValue("@eusd", envioUsd)
                    ins.Parameters.AddWithValue("@dbs",  p.DescuentoBs)
                    ins.Parameters.AddWithValue("@dusd", descUsd)
                    ins.Parameters.AddWithValue("@ep",   estadoPago)
                    ins.Parameters.AddWithValue("@u",    uid)
                    Dim r As Object = ins.ExecuteScalar()
                    nuevoPedidoId = Convert.ToInt32(r)
                End Using

                ' Generar codigo definitivo
                Dim codigo As String = "PED-" & Right("000000" & nuevoPedidoId.ToString(), 6)
                Using updCod As New SqlCommand("UPDATE FLORERIA_Pedido SET codigo=@c WHERE pedido_id=@pid", conn, tx)
                    updCod.CommandTimeout = 30
                    updCod.Parameters.AddWithValue("@c",   codigo)
                    updCod.Parameters.AddWithValue("@pid", nuevoPedidoId)
                    updCod.ExecuteNonQuery()
                End Using

                ' Insertar detalles
                M2_ReemplazarDetalles(conn, tx, nuevoPedidoId, p)

                ' Insertar pago
                M2_SincronizarPago(conn, tx, nuevoPedidoId, p, estadoPago, esPayPal, esLibelula, uid)

                res.Accion = "INSERT"
                res.Mensaje = "pedido_id=" & nuevoPedidoId & ", codigo=" & codigo & ", estado_pago=" & estadoPago
            End If

        Catch ex As Exception
            res.Accion = "ERROR"
            res.Mensaje = ex.Message
        End Try

        Return res
    End Function

    ' ============================================================
    ' M2_ReemplazarDetalles - borra los detalles existentes y los re-inserta desde WC
    ' ============================================================
    Private Sub M2_ReemplazarDetalles(conn As SqlConnection, tx As SqlTransaction, pedId As Integer, p As WcPedido)
        ' Borrar detalles existentes
        Using del As New SqlCommand("DELETE FROM FLORERIA_Pedido_Detalle WHERE pedido_id=@pid", conn, tx)
            del.CommandTimeout = 30
            del.Parameters.AddWithValue("@pid", pedId)
            del.ExecuteNonQuery()
        End Using

        ' Insertar los nuevos
        Dim tasa As Decimal = If(p.WoocsRate > 0, p.WoocsRate, 0D)
        For Each item As WcPedidoItem In p.Items
            Try
                Dim prodId As Object = DBNull.Value
                If item.WcProductId > 0 Then
                    Using pCmd As New SqlCommand("SELECT producto_id FROM FLORERIA_Producto WHERE wc_product_id=@w", conn, tx)
                        pCmd.CommandTimeout = 10
                        pCmd.Parameters.AddWithValue("@w", item.WcProductId)
                        Dim pObj As Object = pCmd.ExecuteScalar()
                        If pObj IsNot Nothing AndAlso Not IsDBNull(pObj) Then prodId = pObj
                    End Using
                End If

                Dim precioUsd As Decimal = If(tasa > 0, Math.Round(item.PrecioUnitarioBs * tasa, 2), 0D)
                Dim subBs     As Decimal = item.PrecioUnitarioBs * item.Cantidad
                Dim subUsd    As Decimal = If(tasa > 0, Math.Round(subBs * tasa, 2), 0D)

                Using ins As New SqlCommand(
                    "INSERT INTO FLORERIA_Pedido_Detalle(" &
                    "  pedido_id, producto_id, wc_line_item_id, es_personalizado, " &
                    "  nombre_producto, cantidad, precio_unitario_bs, precio_unitario_usd, " &
                    "  subtotal_bs, subtotal_usd, personalizacion, creado_en) " &
                    "VALUES(@pid, @prod, @wli, 0, @nom, @cant, @pbs, @pusd, @sbs, @susd, @per, GETDATE())", conn, tx)
                    ins.CommandTimeout = 30
                    ins.Parameters.AddWithValue("@pid",  pedId)
                    ins.Parameters.AddWithValue("@prod", prodId)
                    ins.Parameters.AddWithValue("@wli",  If(item.WcLineItemId > 0, CObj(item.WcLineItemId), DBNull.Value))
                    ins.Parameters.AddWithValue("@nom",  item.NombreProducto.Substring(0, Math.Min(200, item.NombreProducto.Length)))
                    ins.Parameters.AddWithValue("@cant", item.Cantidad)
                    ins.Parameters.AddWithValue("@pbs",  item.PrecioUnitarioBs)
                    ins.Parameters.AddWithValue("@pusd", precioUsd)
                    ins.Parameters.AddWithValue("@sbs",  subBs)
                    ins.Parameters.AddWithValue("@susd", subUsd)
                    ins.Parameters.AddWithValue("@per",  If(item.Personalizacion <> "", CObj(item.Personalizacion), DBNull.Value))
                    ins.ExecuteNonQuery()
                End Using
            Catch ex As Exception
                Log("M2_ReemplazarDetalles", "WC#" & p.WcId & " ERROR en item '" & item.NombreProducto & "': " & ex.Message)
                Throw  ' propagar para que la transaccion haga rollback
            End Try
        Next
    End Sub

    ' ============================================================
    ' M2_SincronizarPago - upsert del registro de pago
    ' ============================================================
    Private Sub M2_SincronizarPago(conn As SqlConnection, tx As SqlTransaction, pedId As Integer,
                                    p As WcPedido, estadoPago As String,
                                    esPayPal As Boolean, esLibelula As Boolean, uid As Integer)
        Dim metodo As String = MapearMetodoPago(p.PaymentMethod, p.PaymentMethodTitle)
        Dim referencia As String = If(p.PaypalOrderId <> "", p.PaypalOrderId,
                                       If(p.WcOrderNumber <> "", "WC#" & p.WcOrderNumber, ""))
        Dim estadoReg As String = "PENDIENTE"
        If p.WcDatePaid.HasValue AndAlso (esPayPal OrElse esLibelula) Then estadoReg = "VERIFICADO"

        ' Calcular total USD
        Dim tasa As Decimal = If(p.WoocsRate > 0, p.WoocsRate, 0D)
        Dim totalUsd As Decimal = If(tasa > 0, Math.Round(p.TotalBs * tasa, 2), 0D)

        ' Existe ya un pago?
        Dim existePago As Boolean = False
        Using chk As New SqlCommand("SELECT COUNT(1) FROM FLORERIA_Pedido_Pago WHERE pedido_id=@pid", conn, tx)
            chk.CommandTimeout = 30
            chk.Parameters.AddWithValue("@pid", pedId)
            existePago = (CInt(chk.ExecuteScalar()) > 0)
        End Using

        If existePago Then
            ' UPDATE: actualizar metodo, monto, referencia. Estado solo si mejora.
            Using upd As New SqlCommand(
                "UPDATE FLORERIA_Pedido_Pago SET " &
                "  metodo_pago = @mp, " &
                "  monto_bs    = @mbs, " &
                "  monto_usd   = @musd, " &
                "  referencia  = ISNULL(@ref, referencia), " &
                "  estado      = CASE WHEN @est='VERIFICADO' THEN 'VERIFICADO' ELSE estado END " &
                "WHERE pedido_id = @pid", conn, tx)
                upd.CommandTimeout = 30
                upd.Parameters.AddWithValue("@mp",   metodo)
                upd.Parameters.AddWithValue("@mbs",  p.TotalBs)
                upd.Parameters.AddWithValue("@musd", totalUsd)
                upd.Parameters.AddWithValue("@ref",  If(referencia <> "", CObj(referencia), DBNull.Value))
                upd.Parameters.AddWithValue("@est",  estadoReg)
                upd.Parameters.AddWithValue("@pid",  pedId)
                upd.ExecuteNonQuery()
            End Using
        Else
            ' INSERT
            Using ins As New SqlCommand(
                "INSERT INTO FLORERIA_Pedido_Pago(" &
                "  pedido_id, tipo_pago, metodo_pago, monto_bs, monto_usd, " &
                "  referencia, estado, observaciones, creado_por, creado_en) " &
                "VALUES(@pid, 'TOTAL', @mp, @mbs, @musd, @ref, @est, @obs, @u, GETDATE())", conn, tx)
                ins.CommandTimeout = 30
                ins.Parameters.AddWithValue("@pid",  pedId)
                ins.Parameters.AddWithValue("@mp",   metodo)
                ins.Parameters.AddWithValue("@mbs",  p.TotalBs)
                ins.Parameters.AddWithValue("@musd", totalUsd)
                ins.Parameters.AddWithValue("@ref",  If(referencia <> "", CObj(referencia), DBNull.Value))
                ins.Parameters.AddWithValue("@est",  estadoReg)
                ins.Parameters.AddWithValue("@obs",  If(p.WcOrderStatus <> "", CObj("WC: " & p.WcOrderStatus), DBNull.Value))
                ins.Parameters.AddWithValue("@u",    uid)
                ins.ExecuteNonQuery()
            End Using
        End If
    End Sub

    ' ============================================================
    ' M2_ObtenerOCrearSlot - usa la conexion/transaccion actual
    ' ============================================================
    Private Function M2_ObtenerOCrearSlot(conn As SqlConnection, tx As SqlTransaction, horario As String) As Object
        ' Buscar existente
        Using cmd As New SqlCommand("SELECT slot_id FROM FLORERIA_Slot_Horario WHERE wc_slot_value=@v", conn, tx)
            cmd.CommandTimeout = 10
            cmd.Parameters.AddWithValue("@v", horario)
            Dim r As Object = cmd.ExecuteScalar()
            If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return CInt(r)
        End Using

        ' Parsear horas "HH:mm - HH:mm"
        Dim partes() As String = horario.Split(New String() {" - "}, StringSplitOptions.RemoveEmptyEntries)
        Dim hi As String = If(partes.Length > 0, partes(0).Trim() & ":00", "00:00:00")
        Dim hf As String = If(partes.Length > 1, partes(1).Trim() & ":00", "00:00:00")
        Dim dur As Integer = 180
        Try
            Dim dtI As DateTime = DateTime.Parse(partes(0).Trim())
            Dim dtF As DateTime = DateTime.Parse(partes(1).Trim())
            dur = CInt((dtF - dtI).TotalMinutes)
            If dur <= 0 Then dur = 180
        Catch
        End Try

        ' Crear slot activo=0
        Using ins As New SqlCommand(
            "INSERT INTO FLORERIA_Slot_Horario(ciudad_id, etiqueta, hora_inicio, hora_fin, duracion_minutos, " &
            "recargo_bs, es_express, activo, orden_display, wc_slot_value, creado_en) " &
            "VALUES(1, @etq, @hi, @hf, @dur, 0, 0, 0, 0, @wv, GETDATE()); SELECT SCOPE_IDENTITY();", conn, tx)
            ins.CommandTimeout = 30
            ins.Parameters.AddWithValue("@etq", horario)
            ins.Parameters.AddWithValue("@hi",  hi)
            ins.Parameters.AddWithValue("@hf",  hf)
            ins.Parameters.AddWithValue("@dur", dur)
            ins.Parameters.AddWithValue("@wv",  horario)
            Return CInt(ins.ExecuteScalar())
        End Using
    End Function

    ' ============================================================
    ' M2_ObtenerOCrearZona - usa la conexion/transaccion actual
    ' ============================================================
    Private Function M2_ObtenerOCrearZona(conn As SqlConnection, tx As SqlTransaction, codigo As String) As Object
        Using cmd As New SqlCommand("SELECT zona_id FROM FLORERIA_Zona WHERE wc_zone_code=@c", conn, tx)
            cmd.CommandTimeout = 10
            cmd.Parameters.AddWithValue("@c", codigo)
            Dim r As Object = cmd.ExecuteScalar()
            If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return CInt(r)
        End Using

        Dim cod As String = codigo.Substring(0, Math.Min(20, codigo.Length))
        Using chkCod As New SqlCommand("SELECT COUNT(1) FROM FLORERIA_Zona WHERE codigo=@c AND ciudad_id=1", conn, tx)
            chkCod.CommandTimeout = 10
            chkCod.Parameters.AddWithValue("@c", cod)
            If CInt(chkCod.ExecuteScalar()) > 0 Then cod = codigo & "_WC"
        End Using

        Using ins As New SqlCommand(
            "INSERT INTO FLORERIA_Zona(ciudad_id, nombre, codigo, tipo, activo, orden_display, wc_zone_code, creado_en) " &
            "VALUES(1, @nom, @cod, 'DELIVERY', 0, 0, @wc, GETDATE()); SELECT SCOPE_IDENTITY();", conn, tx)
            ins.CommandTimeout = 30
            ins.Parameters.AddWithValue("@nom", codigo.Substring(0, Math.Min(150, codigo.Length)))
            ins.Parameters.AddWithValue("@cod", cod)
            ins.Parameters.AddWithValue("@wc",  codigo)
            Return CInt(ins.ExecuteScalar())
        End Using
    End Function

    Private Class M2Resultado
        Public Property Accion As String = ""
        Public Property Mensaje As String = ""
    End Class


    ' ============================================================
    ' InsertarCat
    ' ============================================================
    Private Function InsertarCat(conn As SqlConnection, c As WcCat, uid As Integer) As String
        Try
            Dim existe As Object = Nothing
            Using cmd As New SqlCommand("SELECT categoria_id FROM FLORERIA_Categoria WHERE wc_category_id=@w", conn)
                    cmd.CommandTimeout = 30
                cmd.Parameters.AddWithValue("@w", c.WcId)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then existe = dr("categoria_id")
                End Using
            End Using

            Dim padre As Object = DBNull.Value
            If c.PadreWcId > 0 Then
                Using cmd As New SqlCommand("SELECT categoria_id FROM FLORERIA_Categoria WHERE wc_category_id=@w", conn)
                    cmd.Parameters.AddWithValue("@w", c.PadreWcId)
                    Dim r As Object = cmd.ExecuteScalar()
                    If r IsNot Nothing AndAlso Not IsDBNull(r) Then padre = CInt(r)
                End Using
            End If

            Dim uidP  As Object = If(uid > 0, CObj(uid), DBNull.Value)
            Dim descP As Object = If(c.Descripcion <> "", CObj(c.Descripcion), DBNull.Value)
            Dim slugP As Object = If(c.Slug <> "", CObj(c.Slug), DBNull.Value)

            If existe IsNot Nothing Then
                Using cmd As New SqlCommand(
                    "UPDATE FLORERIA_Categoria SET nombre=@n,descripcion=@d,padre_id=@p,slug=@s," &
                    "wc_sync_estado='SINCRONIZADO',modificado_por=@u,modificado_en=GETDATE() " &
                    "WHERE categoria_id=@id AND (nombre<>@n OR ISNULL(descripcion,'')<>ISNULL(@d,''))", conn)
                    cmd.CommandTimeout = 30
                    cmd.Parameters.AddWithValue("@n", c.Nombre)
                    cmd.Parameters.AddWithValue("@d", descP)
                    cmd.Parameters.AddWithValue("@p", padre)
                    cmd.Parameters.AddWithValue("@s", slugP)
                    cmd.Parameters.AddWithValue("@u", uidP)
                    cmd.Parameters.AddWithValue("@id", CInt(existe))
                    Return If(cmd.ExecuteNonQuery() > 0, "A", "S")
                End Using
            Else
                Using cmd As New SqlCommand(
                    "INSERT INTO FLORERIA_Categoria(padre_id,nombre,descripcion,slug,orden,wc_category_id,wc_sync_estado,creado_por)" &
                    " VALUES(@p,@n,@d,@s,0,@w,'SINCRONIZADO',@u)", conn)
                    cmd.CommandTimeout = 30
                    cmd.Parameters.AddWithValue("@p", padre)
                    cmd.Parameters.AddWithValue("@n", c.Nombre)
                    cmd.Parameters.AddWithValue("@d", descP)
                    cmd.Parameters.AddWithValue("@s", slugP)
                    cmd.Parameters.AddWithValue("@w", c.WcId)
                    cmd.Parameters.AddWithValue("@u", uidP)
                    cmd.ExecuteNonQuery()
                    Return "I"
                End Using
            End If
        Catch ex As Exception
            Log("InsertarCat", "WcId=" & c.WcId & " - " & ex.Message)
            Return "E"
        End Try
    End Function

    ' ============================================================
    ' InsertarProd
    ' ============================================================
    Private Function InsertarProd(conn As SqlConnection, p As WcProd, uid As Integer) As String
        Try
            Dim existe As Object = Nothing
            Using cmd As New SqlCommand("SELECT producto_id FROM FLORERIA_Producto WHERE wc_product_id=@w", conn)
                cmd.Parameters.AddWithValue("@w", p.WcId)
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then existe = dr("producto_id")
                End Using
            End Using

            Dim uidP  As Object  = If(uid > 0, CObj(uid), DBNull.Value)
            Dim pb    As Decimal = 0D : Decimal.TryParse(p.PrecioBS, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, pb)
            Dim descP As Object  = If(p.Descripcion <> "", CObj(p.Descripcion), DBNull.Value)
            Dim iuP   As Object  = If(p.ImagenUrl <> "", CObj(p.ImagenUrl), DBNull.Value)

            Dim ppP As Object = DBNull.Value
            If p.PromoBS <> "" Then
                Dim ppVal As Decimal = 0D
                If Decimal.TryParse(p.PromoBS, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ppVal) Then ppP = ppVal
            End If
            Dim pdP As Object = DBNull.Value
            If p.PromoDesde <> "" Then
                Dim dtVal As DateTime
                If DateTime.TryParse(p.PromoDesde, dtVal) Then pdP = dtVal
            End If
            Dim phP As Object = DBNull.Value
            If p.PromoHasta <> "" Then
                Dim dtVal As DateTime
                If DateTime.TryParse(p.PromoHasta, dtVal) Then phP = dtVal
            End If

            If existe IsNot Nothing Then
                Using cmd As New SqlCommand(
                    "UPDATE FLORERIA_Producto SET nombre=@n,descripcion=@d,precio_base_bs=@pb," &
                    "precio_promo_bs=@pp,promo_desde=@pd,promo_hasta=@ph,destacado=@de,menu_order=@mo," &
                    "imagen_url=@iu,wc_sync_estado='SINCRONIZADO',modificado_por=@u,modificado_en=GETDATE() " &
                    "WHERE producto_id=@id", conn)
                cmd.CommandTimeout = 30
                    cmd.Parameters.AddWithValue("@n",  p.Nombre)
                    cmd.Parameters.AddWithValue("@d",  descP)
                    cmd.Parameters.AddWithValue("@pb", pb)
                    cmd.Parameters.AddWithValue("@pp", ppP)
                    cmd.Parameters.AddWithValue("@pd", pdP)
                    cmd.Parameters.AddWithValue("@ph", phP)
                    cmd.Parameters.AddWithValue("@de", If(p.Destacado, 1, 0))
                    cmd.Parameters.AddWithValue("@mo", p.MenuOrder)
                    cmd.Parameters.AddWithValue("@iu", iuP)
                    cmd.Parameters.AddWithValue("@u",  uidP)
                    cmd.Parameters.AddWithValue("@id", CInt(existe))
                    Return If(cmd.ExecuteNonQuery() > 0, "A", "S")
                End Using
            Else
                Dim sk As String = If(p.Sku <> "", p.Sku, "WC" & p.WcId.ToString())
                Using cmd As New SqlCommand(
                    "INSERT INTO FLORERIA_Producto(sku,nombre,descripcion,precio_base_bs,precio_promo_bs," &
                    "promo_desde,promo_hasta,destacado,menu_order,imagen_url,wc_product_id,wc_sync_estado,creado_por)" &
                    " VALUES(@sk,@n,@d,@pb,@pp,@pd,@ph,@de,@mo,@iu,@w,'SINCRONIZADO',@u)", conn)
                    cmd.CommandTimeout = 30
                    cmd.Parameters.AddWithValue("@sk", sk)
                    cmd.Parameters.AddWithValue("@n",  p.Nombre)
                    cmd.Parameters.AddWithValue("@d",  descP)
                    cmd.Parameters.AddWithValue("@pb", pb)
                    cmd.Parameters.AddWithValue("@pp", ppP)
                    cmd.Parameters.AddWithValue("@pd", pdP)
                    cmd.Parameters.AddWithValue("@ph", phP)
                    cmd.Parameters.AddWithValue("@de", If(p.Destacado, 1, 0))
                    cmd.Parameters.AddWithValue("@mo", p.MenuOrder)
                    cmd.Parameters.AddWithValue("@iu", iuP)
                    cmd.Parameters.AddWithValue("@w",  p.WcId)
                    cmd.Parameters.AddWithValue("@u",  uidP)
                    cmd.ExecuteNonQuery()
                    Return "I"
                End Using
            End If
        Catch ex As Exception
            Log("InsertarProd", "WcId=" & p.WcId & " - " & ex.Message)
            Return "E"
        End Try
    End Function

    ' ============================================================
    ' InsertarPedido — UPSERT via SPs
    '   Llama 3 SPs:
    '     1. sp_Pedido_UpsertWC          → INSERT o UPDATE del pedido
    '     2. sp_Pedido_Detalle_SyncWC    → por cada producto del pedido
    '     3. sp_Pedido_Pago_UpsertWC     → registro de pago
    '
    '   Los SPs validan todos los CHECK constraints internamente
    '   y nunca se cuelgan (XACT_ABORT ON)
    '   Retorna: I=insertado, A=actualizado, E=error
    ' ============================================================
    Private Function InsertarPedido(conn As SqlConnection, p As WcPedido, uid As Integer, ip As String) As String
        Try
            ' --- 1. Calcular totales ---
            Dim totalBs  As Decimal = p.TotalBs
            Dim envioBs  As Decimal = p.EnvioBs
            Dim descBs   As Decimal = p.DescuentoBs
            Dim tasa     As Decimal = If(p.WoocsRate > 0, p.WoocsRate, 0D)
            Dim totalUsd As Decimal = If(tasa > 0, Math.Round(totalBs * tasa, 2), 0D)
            Dim envioUsd As Decimal = If(tasa > 0, Math.Round(envioBs * tasa, 2), 0D)
            Dim descUsd  As Decimal = If(tasa > 0, Math.Round(descBs  * tasa, 2), 0D)

            ' --- 2. Calcular estado_pago ---
            ' SOLO PAGADO si PayPal o Libelula con date_paid confirmado
            Dim estadoPago As String = "PENDIENTE"
            Dim methodLower As String = p.PaymentMethod.ToLower().Trim()
            Dim titleLower  As String = p.PaymentMethodTitle.ToLower().Trim()
            Dim esPayPal    As Boolean = methodLower.Contains("paypal") OrElse methodLower.Contains("ppcp") OrElse titleLower.Contains("paypal")
            Dim esLibelula  As Boolean = methodLower.Contains("libelula") OrElse titleLower.Contains("libelula")
            If p.WcDatePaid.HasValue AndAlso (esPayPal OrElse esLibelula) Then
                estadoPago = "PAGADO"
            End If
            ' estado_operativo: SIEMPRE PENDIENTE para pedidos migrados
            Dim estadoOperativo As String = "PENDIENTE"

            ' --- 3. Detectar PICKUP vs DOMICILIO ---
            Dim esPickup As Boolean = (p.DeliveryType.ToLower().Trim() = "pickup")
            Dim tipoEntrega As String = If(esPickup, "RECOJO_SUCURSAL", "DOMICILIO")
            Dim direccion   As String = If(esPickup, "Recojo en sucursal", If(p.Direccion <> "", p.Direccion, "Sin direccion"))
            ' --- Fecha entrega ---
            ' Prioridad: pickup_date (si es pickup) > delivery_date > date_created
            ' IMPORTANTE: si WC NO mando ninguna fecha relevante, se envia NULL
            ' al SP. El SP detecta NULL y NO pisa la fecha que ya este en la BD.
            Dim fechaEntregaParam As Object = DBNull.Value
            If esPickup AndAlso p.PickupDate.HasValue Then
                fechaEntregaParam = p.PickupDate.Value
            ElseIf p.DeliveryDate.HasValue Then
                fechaEntregaParam = p.DeliveryDate.Value
            ElseIf p.PickupDate.HasValue Then
                fechaEntregaParam = p.PickupDate.Value
            ElseIf p.WcDateCreated.HasValue Then
                ' Solo si es un pedido NUEVO (no tiene fecha en BD), usar date_created como fallback
                ' El SP se encarga de no pisar la fecha si ya existe
                fechaEntregaParam = p.WcDateCreated.Value.Date
            End If
            ' Si fechaEntregaParam queda en DBNull, el SP lo manejara

            ' --- 4. Resolver slot y zona ---
            Dim horarioSlot As String = If(esPickup, p.PickupTime, p.DeliveryTime)
            Dim slotId As Object = DBNull.Value
            If horarioSlot <> "" Then slotId = ObtenerOCrearSlot(conn, horarioSlot)

            Dim zonaId As Object = DBNull.Value
            If Not esPickup AndAlso p.ShippingState <> "" Then zonaId = ObtenerOCrearZona(conn, p.ShippingState)

            ' --- 5. Calcular receptor ---
            Dim receptorNombre As String = If(p.ShippingNombre <> "", p.ShippingNombre, If(p.BillingNombre <> "", (p.BillingNombre & " " & p.BillingApellidos).Trim(), "Sin nombre"))
            Dim receptorCel    As String = If(p.ShippingPhone <> "", p.ShippingPhone, If(p.TelefonoRecibe <> "", p.TelefonoRecibe, If(p.BillingPhone <> "", p.BillingPhone, "00000000")))

            ' --- 6. Llamar sp_Pedido_UpsertWC ---
            Dim pedId As Integer = 0
            Dim accion As String = ""
            Dim mensajeError As String = ""

            Using cmd As New SqlCommand("FLORERIA_sp_Pedido_UpsertWC", conn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.CommandTimeout = 30

                cmd.Parameters.AddWithValue("@wc_order_id",             p.WcId)
                cmd.Parameters.AddWithValue("@wc_order_number",         If(p.WcOrderNumber <> "",      CObj(p.WcOrderNumber),      DBNull.Value))
                cmd.Parameters.AddWithValue("@wc_order_key",            If(p.WcOrderKey <> "",         CObj(p.WcOrderKey),         DBNull.Value))
                cmd.Parameters.AddWithValue("@wc_order_status",         If(p.WcOrderStatus <> "",      CObj(p.WcOrderStatus),      DBNull.Value))
                cmd.Parameters.AddWithValue("@wc_date_paid",            If(p.WcDatePaid.HasValue,      CObj(p.WcDatePaid.Value),   DBNull.Value))
                cmd.Parameters.AddWithValue("@wc_date_modified",        If(p.WcDateModified.HasValue,  CObj(p.WcDateModified.Value), DBNull.Value))
                cmd.Parameters.AddWithValue("@wc_payment_method",       If(p.PaymentMethod <> "",      CObj(p.PaymentMethod),      DBNull.Value))
                cmd.Parameters.AddWithValue("@wc_payment_method_title", If(p.PaymentMethodTitle <> "", CObj(p.PaymentMethodTitle), DBNull.Value))

                cmd.Parameters.AddWithValue("@receptor_nombre",  receptorNombre.Substring(0, Math.Min(200, receptorNombre.Length)))
                cmd.Parameters.AddWithValue("@receptor_celular", receptorCel.Substring(0, Math.Min(20, receptorCel.Length)))
                cmd.Parameters.AddWithValue("@ciudad_id",        CShort(1))
                cmd.Parameters.AddWithValue("@zona_id",          zonaId)
                cmd.Parameters.AddWithValue("@slot_id",          slotId)
                cmd.Parameters.AddWithValue("@tipo_entrega",     tipoEntrega)
                cmd.Parameters.AddWithValue("@direccion",        direccion.Substring(0, Math.Min(300, direccion.Length)))
                cmd.Parameters.AddWithValue("@fecha_entrega",    fechaEntregaParam)
                cmd.Parameters.AddWithValue("@dedicatoria",      If(p.MensajeTarjeta <> "", CObj(p.MensajeTarjeta), DBNull.Value))
                cmd.Parameters.AddWithValue("@firma_tarjeta",    If(p.FirmaTarjeta <> "",   CObj(p.FirmaTarjeta),   DBNull.Value))
                cmd.Parameters.AddWithValue("@tipo_ocacion",     MapearTipoOcacion(p.TipoOcacion))
                cmd.Parameters.AddWithValue("@nota_floreria",    If(p.NotaFloreria <> "",   CObj(p.NotaFloreria),   DBNull.Value))
                cmd.Parameters.AddWithValue("@gps",              If(p.Gps <> "",            CObj(p.Gps),            DBNull.Value))
                cmd.Parameters.AddWithValue("@observaciones",    If(p.Observaciones <> "",  CObj(p.Observaciones),  DBNull.Value))

                cmd.Parameters.AddWithValue("@total_bs",      totalBs)
                cmd.Parameters.AddWithValue("@total_usd",     totalUsd)
                cmd.Parameters.AddWithValue("@envio_bs",      envioBs)
                cmd.Parameters.AddWithValue("@envio_usd",     envioUsd)
                cmd.Parameters.AddWithValue("@descuento_bs",  descBs)
                cmd.Parameters.AddWithValue("@descuento_usd", descUsd)

                cmd.Parameters.AddWithValue("@estado_pago",      estadoPago)
                cmd.Parameters.AddWithValue("@estado_operativo", estadoOperativo)
                cmd.Parameters.AddWithValue("@creado_por",       uid)
                cmd.Parameters.AddWithValue("@ip",               ip)

                Dim pId  As New SqlParameter("@pedido_id",     SqlDbType.Int)            With {.Direction = ParameterDirection.Output}
                Dim pCod As New SqlParameter("@codigo",        SqlDbType.VarChar,  20)   With {.Direction = ParameterDirection.Output}
                Dim pAcc As New SqlParameter("@accion",        SqlDbType.VarChar,  10)   With {.Direction = ParameterDirection.Output}
                Dim pErr As New SqlParameter("@mensaje_error", SqlDbType.NVarChar, 500)  With {.Direction = ParameterDirection.Output}
                cmd.Parameters.Add(pId)
                cmd.Parameters.Add(pCod)
                cmd.Parameters.Add(pAcc)
                cmd.Parameters.Add(pErr)

                cmd.ExecuteNonQuery()

                pedId        = If(IsDBNull(pId.Value),  0,  Convert.ToInt32(pId.Value))
                accion       = If(IsDBNull(pAcc.Value), "", Convert.ToString(pAcc.Value))
                mensajeError = If(IsDBNull(pErr.Value), "", Convert.ToString(pErr.Value))
            End Using

            If accion = "ERROR" OrElse pedId = 0 Then
                Log("InsertarPedido", "WC#" & p.WcId & " - SP devolvio ERROR: " & mensajeError)
                Return "E"
            End If

            ' --- 7. Sincronizar productos (line_items) ---
            For Each item As WcPedidoItem In p.Items
                Try
                    Dim prodId As Object = DBNull.Value
                    If item.WcProductId > 0 Then
                        Using pCmd As New SqlCommand("SELECT producto_id FROM FLORERIA_Producto WHERE wc_product_id=@w", conn)
                            pCmd.CommandTimeout = 10
                            pCmd.Parameters.AddWithValue("@w", item.WcProductId)
                            Dim pObj As Object = pCmd.ExecuteScalar()
                            If pObj IsNot Nothing AndAlso Not IsDBNull(pObj) Then prodId = pObj
                        End Using
                    End If

                    Dim precioBs  As Decimal = item.PrecioUnitarioBs
                    Dim precioUsd As Decimal = If(tasa > 0, Math.Round(precioBs * tasa, 2), 0D)

                    Using dCmd As New SqlCommand("FLORERIA_sp_Pedido_Detalle_SyncWC", conn)
                        dCmd.CommandType = CommandType.StoredProcedure
                        dCmd.CommandTimeout = 30
                        dCmd.Parameters.AddWithValue("@pedido_id",           pedId)
                        dCmd.Parameters.AddWithValue("@wc_line_item_id",     item.WcLineItemId)
                        dCmd.Parameters.AddWithValue("@producto_id",         prodId)
                        dCmd.Parameters.AddWithValue("@nombre_producto",     item.NombreProducto.Substring(0, Math.Min(200, item.NombreProducto.Length)))
                        dCmd.Parameters.AddWithValue("@cantidad",            item.Cantidad)
                        dCmd.Parameters.AddWithValue("@precio_unitario_bs",  precioBs)
                        dCmd.Parameters.AddWithValue("@precio_unitario_usd", precioUsd)
                        dCmd.Parameters.AddWithValue("@personalizacion",     If(item.Personalizacion <> "", CObj(item.Personalizacion), DBNull.Value))

                        Dim pAccD As New SqlParameter("@accion",        SqlDbType.VarChar,  10)  With {.Direction = ParameterDirection.Output}
                        Dim pErrD As New SqlParameter("@mensaje_error", SqlDbType.NVarChar, 500) With {.Direction = ParameterDirection.Output}
                        dCmd.Parameters.Add(pAccD)
                        dCmd.Parameters.Add(pErrD)

                        dCmd.ExecuteNonQuery()

                        Dim accD As String = If(IsDBNull(pAccD.Value), "", Convert.ToString(pAccD.Value))
                        If accD = "ERROR" Then
                            Log("InsertarPedido", "WC#" & p.WcId & " - detalle ERROR: " & Convert.ToString(pErrD.Value))
                        End If
                    End Using
                Catch ex As Exception
                    Log("InsertarPedido", "WC#" & p.WcId & " - ERROR line_item: " & ex.Message)
                End Try
            Next

            ' --- 8. Registrar pago via SP ---
            Try
                Dim metodoPago As String = MapearMetodoPago(p.PaymentMethod, p.PaymentMethodTitle)
                Dim referencia As String = If(p.PaypalOrderId <> "", p.PaypalOrderId, If(p.WcOrderNumber <> "", "WC#" & p.WcOrderNumber, ""))
                Dim estadoRegistro As String = "PENDIENTE"
                If p.WcDatePaid.HasValue AndAlso (esPayPal OrElse esLibelula) Then
                    estadoRegistro = "VERIFICADO"
                End If

                Using pCmd As New SqlCommand("FLORERIA_sp_Pedido_Pago_UpsertWC", conn)
                    pCmd.CommandType = CommandType.StoredProcedure
                    pCmd.CommandTimeout = 30
                    pCmd.Parameters.AddWithValue("@pedido_id",     pedId)
                    pCmd.Parameters.AddWithValue("@metodo_pago",   metodoPago)
                    pCmd.Parameters.AddWithValue("@monto_bs",      totalBs)
                    pCmd.Parameters.AddWithValue("@monto_usd",     totalUsd)
                    pCmd.Parameters.AddWithValue("@referencia",    If(referencia <> "", CObj(referencia), DBNull.Value))
                    pCmd.Parameters.AddWithValue("@estado",        estadoRegistro)
                    pCmd.Parameters.AddWithValue("@observaciones", If(p.WcOrderStatus <> "", CObj("WC status: " & p.WcOrderStatus), DBNull.Value))
                    pCmd.Parameters.AddWithValue("@creado_por",    uid)

                    Dim pAccP As New SqlParameter("@accion",        SqlDbType.VarChar,  10)  With {.Direction = ParameterDirection.Output}
                    Dim pErrP As New SqlParameter("@mensaje_error", SqlDbType.NVarChar, 500) With {.Direction = ParameterDirection.Output}
                    pCmd.Parameters.Add(pAccP)
                    pCmd.Parameters.Add(pErrP)

                    pCmd.ExecuteNonQuery()

                    Dim accP As String = If(IsDBNull(pAccP.Value), "", Convert.ToString(pAccP.Value))
                    If accP = "ERROR" Then
                        Log("InsertarPedido", "WC#" & p.WcId & " - pago ERROR: " & Convert.ToString(pErrP.Value))
                    End If
                End Using
            Catch ex As Exception
                Log("InsertarPedido", "WC#" & p.WcId & " - ERROR registrando pago: " & ex.Message)
            End Try

            Log("InsertarPedido", "WC#" & p.WcId & " " & accion & " OK → pedido_id=" & pedId & " estado_pago=" & estadoPago)
            Return If(accion = "INSERT", "I", "A")

        Catch ex As Exception
            Log("InsertarPedido", "WC#" & p.WcId & " - ERROR CRITICO: " & ex.Message)
            Return "E"
        End Try
    End Function


    ' ============================================================
    ' ObtenerOCrearSlot
    '   Busca slot por wc_slot_value. Si no existe lo crea activo=0
    ' ============================================================
    ' ============================================================
    ' MapearMetodoPago
    '   Convierte el valor de WC al CHECK constraint de FLORERIA_Pedido_Pago
    '   BD acepta: PAYPAL, QR, TRANSFERENCIA, TARJETA, EFECTIVO,
    '              PIX, YAPE, CRIPTO, PAGOMOVIL
    ' ============================================================
    Private Function MapearMetodoPago(method As String, title As String) As String
        Dim m As String = If(method, "").ToLower().Trim()
        Dim t As String = If(title,  "").ToLower().Trim()

        If m.Contains("paypal") OrElse t.Contains("paypal") Then Return "PAYPAL"
        If m.Contains("ppcp")   OrElse m.Contains("ppec")   Then Return "PAYPAL"
        If m.Contains("card")   OrElse t.Contains("tarjeta") OrElse t.Contains("card") Then Return "TARJETA"
        If m.Contains("bnb")    OrElse m.Contains("banconacional") OrElse m.Contains("qr") OrElse t.Contains("qr") Then Return "QR"
        If m.Contains("libelula") OrElse t.Contains("libelula") Then Return "TRANSFERENCIA"
        If m.Contains("bacs")   OrElse m.Contains("transfer") OrElse t.Contains("transfer") Then Return "TRANSFERENCIA"
        If m.Contains("cod")    OrElse m.Contains("cash") OrElse t.Contains("efectivo") OrElse t.Contains("contra entrega") Then Return "EFECTIVO"
        Return "TRANSFERENCIA"
    End Function

    ' ============================================================
    ' MapearTipoOcacion
    '   Convierte el valor libre de WC al CHECK constraint
    '   BD acepta: CUMPLEANOS, ANIVERSARIO, AMOR, AGRADECIMIENTO,
    '              CONDOLENCIAS, GRADUACION, NACIMIENTO, OTRO
    ' ============================================================
    Private Function MapearTipoOcacion(valorWC As String) As String
        If valorWC Is Nothing OrElse valorWC.Trim() = "" Then Return "OTRO"
        Select Case valorWC.Trim().ToLower()
            Case "cumpleaños", "cumpleanos", "cumpleano", "birthday"
                Return "CUMPLEANOS"
            Case "aniversario", "anniversary", "anniversario"
                Return "ANIVERSARIO"
            Case "amor", "te amo", "love", "san valentin", "san valentín", "valentín", "valentin"
                Return "AMOR"
            Case "agradecimiento", "gracias", "thank you", "thanks"
                Return "AGRADECIMIENTO"
            Case "condolencias", "pesames", "pésames", "funeral", "sepelio"
                Return "CONDOLENCIAS"
            Case "graduacion", "graduación", "graduation", "grado", "titulacion", "titulación"
                Return "GRADUACION"
            Case "nacimiento", "bebe", "bebé", "baby shower", "bienvenida"
                Return "NACIMIENTO"
            Case Else
                Return "OTRO"
        End Select
    End Function

    ' ============================================================
    ' ObtenerOCrearSlot
    '   Busca slot por wc_slot_value. Si no existe lo crea activo=0
    ' ============================================================
    Private Function ObtenerOCrearSlot(conn As SqlConnection, deliveryTime As String) As Object
        Try
            ' Buscar existente
            Using cmd As New SqlCommand("SELECT slot_id FROM FLORERIA_Slot_Horario WHERE wc_slot_value=@v", conn)
                cmd.Parameters.AddWithValue("@v", deliveryTime)
                Dim r As Object = cmd.ExecuteScalar()
                If r IsNot Nothing AndAlso Not IsDBNull(r) Then
                    Return CInt(r)
                End If
            End Using

            ' Parsear horas del string "HH:mm - HH:mm"
            Dim partes() As String = deliveryTime.Split(New String() {" - "}, StringSplitOptions.RemoveEmptyEntries)
            Dim horaInicio As String = If(partes.Length > 0, partes(0).Trim() & ":00", "00:00:00")
            Dim horaFin    As String = If(partes.Length > 1, partes(1).Trim() & ":00", "00:00:00")

            ' Calcular duracion en minutos
            Dim duracion As Integer = 180
            Try
                Dim dtIn  As DateTime = DateTime.Parse(partes(0).Trim())
                Dim dtFin As DateTime = DateTime.Parse(partes(1).Trim())
                duracion = CInt((dtFin - dtIn).TotalMinutes)
                If duracion <= 0 Then duracion = 180
            Catch
            End Try

            ' Crear slot deshabilitado
            Using cmd As New SqlCommand(
                "INSERT INTO FLORERIA_Slot_Horario(ciudad_id,etiqueta,hora_inicio,hora_fin,duracion_minutos," &
                "recargo_bs,es_express,activo,orden_display,wc_slot_value,creado_en) " &
                "VALUES(1,@etq,@hi,@hf,@dur,0,0,0,0,@wv,GETDATE()); SELECT SCOPE_IDENTITY();", conn)
                cmd.CommandTimeout = 30
                cmd.Parameters.AddWithValue("@etq", deliveryTime)
                cmd.Parameters.AddWithValue("@hi",  horaInicio)
                cmd.Parameters.AddWithValue("@hf",  horaFin)
                cmd.Parameters.AddWithValue("@dur", duracion)
                cmd.Parameters.AddWithValue("@wv",  deliveryTime)
                Dim newId As Object = cmd.ExecuteScalar()
                Log("ObtenerOCrearSlot", "Slot creado activo=0 para '" & deliveryTime & "' → slot_id=" & newId.ToString())
                Return CInt(newId)
            End Using
        Catch ex As Exception
            Log("ObtenerOCrearSlot", "ERROR con '" & deliveryTime & "': " & ex.Message)
            Return DBNull.Value
        End Try
    End Function

    ' ============================================================
    ' ObtenerOCrearZona
    '   Busca zona por wc_zone_code. Si no existe la crea activo=0
    '   Usa la misma conexion (ahora cada pedido tiene su propia conexion limpia)
    ' ============================================================
    Private Function ObtenerOCrearZona(conn As SqlConnection, wcZoneCode As String) As Object
        Try
            ' Buscar existente
            Using cmd As New SqlCommand("SELECT zona_id FROM FLORERIA_Zona WHERE wc_zone_code=@c", conn)
                cmd.CommandTimeout = 10
                cmd.Parameters.AddWithValue("@c", wcZoneCode)
                Dim r As Object = cmd.ExecuteScalar()
                If r IsNot Nothing AndAlso Not IsDBNull(r) Then Return CInt(r)
            End Using

            ' No existe — crear
            Dim codigoFinal As String = wcZoneCode.Substring(0, Math.Min(20, wcZoneCode.Length))

            ' Verificar que el codigo no exista ya
            Using chk As New SqlCommand("SELECT COUNT(1) FROM FLORERIA_Zona WHERE codigo=@c AND ciudad_id=1", conn)
                chk.CommandTimeout = 10
                chk.Parameters.AddWithValue("@c", codigoFinal)
                If CInt(chk.ExecuteScalar()) > 0 Then codigoFinal = wcZoneCode & "_WC"
            End Using

            ' Insertar
            Using ins As New SqlCommand(
                "INSERT INTO FLORERIA_Zona(ciudad_id,nombre,codigo,tipo,activo,orden_display,wc_zone_code,creado_en) " &
                "VALUES(1,@nom,@cod,'DELIVERY',0,0,@wc,GETDATE()); SELECT SCOPE_IDENTITY();", conn)
                ins.CommandTimeout = 10
                ins.Parameters.AddWithValue("@nom", wcZoneCode.Substring(0, Math.Min(150, wcZoneCode.Length)))
                ins.Parameters.AddWithValue("@cod", codigoFinal)
                ins.Parameters.AddWithValue("@wc",  wcZoneCode)
                Dim newId As Object = ins.ExecuteScalar()
                Log("ObtenerOCrearZona", "Zona creada activo=0 para '" & wcZoneCode & "' → zona_id=" & newId.ToString())
                Return CInt(newId)
            End Using

        Catch ex As Exception
            Log("ObtenerOCrearZona", "ERROR con '" & wcZoneCode & "': " & ex.Message)
            Return DBNull.Value
        End Try
    End Function

    ' ============================================================
    ' ParsearCats
    ' ============================================================
    Private Function ParsearCats(json As String) As List(Of WcCat)
        Dim lista As New List(Of WcCat)()
        Try
            Dim items As String = ExtraerArray(json, "data")
            If items = "" Then items = json
            Dim idx As Integer = 1
            While idx < items.Length
                Dim obj As String = ExtraerObjeto(items, idx)
                If obj = "" Then Exit While
                Dim cat As New WcCat()
                cat.WcId       = ExtraerEntero(obj, "id")
                cat.PadreWcId  = ExtraerEntero(obj, "parent")
                cat.Nombre     = ExtraerStr(obj, "name")
                cat.Slug       = ExtraerStr(obj, "slug")
                cat.Descripcion = LimpiarHtml(ExtraerStr(obj, "description"))
                If cat.WcId > 0 AndAlso cat.Nombre <> "" Then lista.Add(cat)
                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            Log("ParsearCats", "ERROR: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ParsearProds
    ' ============================================================
    Private Function ParsearProds(json As String) As List(Of WcProd)
        Dim lista As New List(Of WcProd)()
        Try
            Dim items As String = ExtraerArray(json, "data")
            If items = "" Then items = json
            Dim idx As Integer = 1
            While idx < items.Length
                Dim obj As String = ExtraerObjeto(items, idx)
                If obj = "" Then Exit While
                Dim prod As New WcProd()
                prod.WcId       = ExtraerEntero(obj, "id")
                prod.Nombre     = ExtraerStr(obj, "name")
                prod.Sku        = ExtraerStr(obj, "sku")
                prod.Descripcion = LimpiarHtml(ExtraerStr(obj, "description"))
                prod.PrecioBS   = ExtraerStr(obj, "price")
                prod.PromoBS    = ExtraerStr(obj, "sale_price")
                prod.PromoDesde = ExtraerStr(obj, "date_on_sale_from")
                prod.PromoHasta = ExtraerStr(obj, "date_on_sale_to")
                prod.Tipo       = ExtraerStr(obj, "type")
                prod.Destacado  = (ExtraerStr(obj, "featured") = "true")
                prod.MenuOrder  = ExtraerEntero(obj, "menu_order")
                Dim imgArr As String = ExtraerArray(obj, "images")
                If imgArr <> "" Then
                    Dim primerImg As String = ExtraerObjeto(imgArr, 1)
                    If primerImg <> "" Then prod.ImagenUrl = ExtraerStr(primerImg, "src")
                End If
                If prod.WcId > 0 AndAlso prod.Nombre <> "" Then lista.Add(prod)
                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            Log("ParsearProds", "ERROR: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ParsearPedidos - mapeo basado en JSON real de miss-flores.com
    ' ============================================================
    Private Function ParsearPedidos(json As String) As List(Of WcPedido)
        Dim lista As New List(Of WcPedido)()
        Try
            Dim items As String = ExtraerArray(json, "data")
            If items = "" Then items = json
            Dim idx As Integer = 1
            While idx < items.Length
                Dim obj As String = ExtraerObjeto(items, idx)
                If obj = "" Then Exit While

                Dim ped As New WcPedido()

                ' --- Campos raiz ---
                ped.WcId               = ExtraerEntero(obj, "id")
                ped.WcOrderNumber      = ExtraerStr(obj, "number")
                ped.WcOrderKey         = ExtraerStr(obj, "order_key")
                ped.WcOrderStatus      = ExtraerStr(obj, "status")
                ped.PaymentMethod      = ExtraerStr(obj, "payment_method")
                ped.PaymentMethodTitle = ExtraerStr(obj, "payment_method_title")
                ped.Observaciones      = ExtraerStr(obj, "customer_note")

                ' date_paid (null si no pago)
                Dim datePaidStr As String = ExtraerStr(obj, "date_paid")
                If datePaidStr <> "" AndAlso datePaidStr <> "null" Then
                    Dim dtPaid As DateTime
                    If DateTime.TryParse(datePaidStr, dtPaid) Then ped.WcDatePaid = dtPaid
                End If

                ' date_modified (para detectar cambios en reruns)
                Dim dateModStr As String = ExtraerStr(obj, "date_modified")
                If dateModStr <> "" Then
                    Dim dtMod As DateTime
                    If DateTime.TryParse(dateModStr, dtMod) Then ped.WcDateModified = dtMod
                End If

                ' date_created (fallback si no hay delivery_date ni pickup_date)
                Dim dateCreStr As String = ExtraerStr(obj, "date_created")
                If dateCreStr <> "" Then
                    Dim dtCre As DateTime
                    If DateTime.TryParse(dateCreStr, dtCre) Then ped.WcDateCreated = dtCre
                End If

                Dim totalStr As String = ExtraerStr(obj, "total")
                Decimal.TryParse(totalStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ped.TotalBs)

                Dim envioStr As String = ExtraerStr(obj, "shipping_total")
                Decimal.TryParse(envioStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ped.EnvioBs)

                Dim descStr As String = ExtraerStr(obj, "discount_total")
                Decimal.TryParse(descStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ped.DescuentoBs)

                ' --- Billing (quien compra) ---
                Dim posBilling As Integer = obj.IndexOf("""billing""")
                If posBilling >= 0 Then
                    Dim billingObj As String = ExtraerObjeto(obj, posBilling)
                    If billingObj <> "" Then
                        ped.BillingNombre    = ExtraerStr(billingObj, "first_name").Trim()
                        ped.BillingApellidos = ExtraerStr(billingObj, "last_name").Trim()
                        ped.BillingEmail     = ExtraerStr(billingObj, "email").Trim()
                        ped.BillingPhone     = ExtraerStr(billingObj, "phone").Trim()
                    End If
                End If

                ' --- Shipping (quien recibe) ---
                Dim posShipping As Integer = obj.IndexOf("""shipping""")
                If posShipping >= 0 Then
                    Dim shippingObj As String = ExtraerObjeto(obj, posShipping)
                    If shippingObj <> "" Then
                        Dim sNom  As String = ExtraerStr(shippingObj, "first_name").Trim()
                        Dim sApe  As String = ExtraerStr(shippingObj, "last_name").Trim()
                        ped.ShippingNombre = If(sApe <> "", sNom & " " & sApe, sNom).Trim()
                        ped.ShippingPhone  = ExtraerStr(shippingObj, "phone").Trim()
                        Dim dir1 As String = ExtraerStr(shippingObj, "address_1").Trim()
                        Dim dir2 As String = ExtraerStr(shippingObj, "address_2").Trim()
                        ped.Direccion      = If(dir2 <> "", dir1 & " " & dir2, dir1).Trim()
                        ped.ShippingState  = ExtraerStr(shippingObj, "state").Trim()
                    End If
                End If

                ' --- Meta_data ---
                Dim metaArr As String = ExtraerArray(obj, "meta_data")
                If metaArr <> "" Then
                    ped.TelefonoRecibe = ExtraerMetaValor(metaArr, "TelefonoRecibe")
                    ped.DeliveryType   = ExtraerMetaValor(metaArr, "delivery_type")
                    ped.DeliveryTime   = ExtraerMetaValor(metaArr, "delivery_time")
                    ped.PickupTime     = ExtraerMetaValor(metaArr, "pickup_time")
                    ped.MensajeTarjeta = ExtraerMetaValor(metaArr, "mensaje_tarjeta")
                    ped.FirmaTarjeta   = ExtraerMetaValor(metaArr, "firma_tarjeta")
                    ped.TipoOcacion    = ExtraerMetaValor(metaArr, "tipo_de_ocacion")
                    ped.NotaFloreria   = ExtraerMetaValor(metaArr, "nota_floreria")
                    ped.Gps            = ExtraerMetaValor(metaArr, "gps")
                    ped.PaypalOrderId  = ExtraerMetaValor(metaArr, "_ppcp_paypal_order_id")

                    ' Tasa de cambio BOB→USD
                    Dim rateStr As String = ExtraerMetaValor(metaArr, "_woocs_order_rate")
                    If rateStr <> "" Then
                        Decimal.TryParse(rateStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, ped.WoocsRate)
                    End If

                    ' Fecha de entrega real (delivery_date, NO date_created)
                    Dim fechaStr As String = ExtraerMetaValor(metaArr, "delivery_date")
                    If fechaStr <> "" Then
                        Dim dtParsed As DateTime
                        If DateTime.TryParse(fechaStr, dtParsed) Then ped.DeliveryDate = dtParsed
                    End If

                    ' Fecha de recojo (si delivery_type=pickup)
                    Dim pickupFechaStr As String = ExtraerMetaValor(metaArr, "pickup_date")
                    If pickupFechaStr <> "" Then
                        Dim dtPickup As DateTime
                        If DateTime.TryParse(pickupFechaStr, dtPickup) Then ped.PickupDate = dtPickup
                    End If
                End If

                ' Fallback telefono receptor: shipping.phone > TelefonoRecibe > billing.phone
                If ped.ShippingPhone = "" AndAlso ped.TelefonoRecibe <> "" Then
                    ped.ShippingPhone = ped.TelefonoRecibe
                End If

                ' --- Line items ---
                Dim lineItemsJson As String = ExtraerArray(obj, "line_items")
                If lineItemsJson <> "" Then
                    ped.Items = ParsearLineItems(lineItemsJson)
                End If

                ' Filtro: orden basura si no tiene wc_order_number
                ' (WC genera estos registros vacios; no valen para migrar)
                If ped.WcId > 0 AndAlso ped.WcOrderNumber.Trim() <> "" Then
                    lista.Add(ped)
                Else
                    Log("ParsearPedidos", "Descartado WcId=" & ped.WcId & " sin wc_order_number")
                End If

                idx = items.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            Log("ParsearPedidos", "ERROR: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ParsearLineItems
    ' ============================================================
    Private Function ParsearLineItems(json As String) As List(Of WcPedidoItem)
        Dim lista As New List(Of WcPedidoItem)()
        Try
            Dim idx As Integer = 1
            While idx < json.Length
                Dim obj As String = ExtraerObjeto(json, idx)
                If obj = "" Then Exit While
                Dim item As New WcPedidoItem()
                item.WcLineItemId   = ExtraerEntero(obj, "id")
                item.WcProductId    = ExtraerEntero(obj, "product_id")
                item.NombreProducto = ExtraerStr(obj, "name")
                item.Cantidad       = ExtraerEntero(obj, "quantity")
                If item.Cantidad <= 0 Then item.Cantidad = 1

                Dim precStr As String = ExtraerStr(obj, "price")
                If precStr <> "" Then Decimal.TryParse(precStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, item.PrecioUnitarioBs)
                If item.PrecioUnitarioBs <= 0 Then item.PrecioUnitarioBs = 1

                Dim subStr As String = ExtraerStr(obj, "subtotal")
                If subStr <> "" Then Decimal.TryParse(subStr, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, item.SubtotalBs)
                If item.SubtotalBs <= 0 Then item.SubtotalBs = item.PrecioUnitarioBs * item.Cantidad

                ' Meta del item (personalizacion)
                Dim metaJson As String = ExtraerArray(obj, "meta_data")
                If metaJson <> "" Then
                    item.Personalizacion = ExtraerMetaValor(metaJson, "personalizacion")
                End If

                If item.NombreProducto <> "" Then lista.Add(item)
                idx = json.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch ex As Exception
            Log("ParsearLineItems", "ERROR: " & ex.Message)
        End Try
        Return lista
    End Function

    ' ============================================================
    ' ExtraerMetaValor - busca key en array meta_data
    ' ============================================================
    Private Function ExtraerMetaValor(metaJson As String, clave As String) As String
        Try
            Dim idx As Integer = 1
            While idx < metaJson.Length
                Dim obj As String = ExtraerObjeto(metaJson, idx)
                If obj = "" Then Exit While
                Dim k As String = ExtraerStr(obj, "key")
                If k.ToLower() = clave.ToLower() Then
                    Return ExtraerStr(obj, "value")
                End If
                idx = metaJson.IndexOf("{"c, idx + obj.Length)
                If idx < 0 Then Exit While
            End While
        Catch
        End Try
        Return ""
    End Function

    ' ============================================================
    ' Utilidades JSON minimal
    ' ============================================================
    Private Function ExtraerObjeto(json As String, start As Integer) As String
        Try
            Dim idx   As Integer = json.IndexOf("{"c, start)
            If idx < 0 Then Return ""
            Dim depth As Integer = 0
            Dim ini   As Integer = idx
            While idx < json.Length
                If json(idx) = "{"c Then depth += 1
                If json(idx) = "}"c Then
                    depth -= 1
                    If depth = 0 Then Return json.Substring(ini, idx - ini + 1)
                End If
                idx += 1
            End While
        Catch
        End Try
        Return ""
    End Function

    Private Function ExtraerArray(json As String, campo As String) As String
        Try
            Dim patron As String = """" & campo & """"
            Dim idx    As Integer = json.IndexOf(patron)
            If idx < 0 Then Return ""
            idx += patron.Length
            While idx < json.Length AndAlso (json(idx) = " "c OrElse json(idx) = ":"c)
                idx += 1
            End While
            If idx >= json.Length OrElse json(idx) <> "["c Then Return ""
            Dim depth As Integer = 0
            Dim ini   As Integer = idx
            While idx < json.Length
                If json(idx) = "["c Then depth += 1
                If json(idx) = "]"c Then
                    depth -= 1
                    If depth = 0 Then Return json.Substring(ini, idx - ini + 1)
                End If
                idx += 1
            End While
        Catch
        End Try
        Return ""
    End Function

    Private Function ExtraerStr(json As String, campo As String) As String
        Try
            Dim patron As String = """" & campo & """"
            Dim idx    As Integer = json.IndexOf(patron)
            If idx < 0 Then Return ""
            idx += patron.Length
            While idx < json.Length AndAlso (json(idx) = " "c OrElse json(idx) = ":"c)
                idx += 1
            End While
            If idx >= json.Length Then Return ""
            If json(idx) = """"c Then
                idx += 1
                Dim sb As New StringBuilder()
                While idx < json.Length AndAlso json(idx) <> """"c
                    If json(idx) = "\"c AndAlso idx + 1 < json.Length Then
                        idx += 1
                        Select Case json(idx)
                            Case "n"c, "r"c, "t"c : sb.Append(" ")
                            Case "u"c
                                If idx + 4 < json.Length Then
                                    Dim hex  As String  = json.Substring(idx + 1, 4)
                                    Dim code As Integer = 0
                                    If Integer.TryParse(hex, System.Globalization.NumberStyles.HexNumber, Nothing, code) Then
                                        sb.Append(ChrW(code))
                                    End If
                                    idx += 4
                                End If
                            Case Else : sb.Append(json(idx))
                        End Select
                    Else
                        sb.Append(json(idx))
                    End If
                    idx += 1
                End While
                Return sb.ToString()
            End If
            Dim sb2 As New StringBuilder()
            While idx < json.Length AndAlso json(idx) <> ","c AndAlso json(idx) <> "}"c
                sb2.Append(json(idx))
                idx += 1
            End While
            Return sb2.ToString().Trim()
        Catch
            Return ""
        End Try
    End Function

    Private Function ExtraerEntero(json As String, campo As String) As Integer
        Dim v As String  = ExtraerStr(json, campo)
        Dim r As Integer = 0
        Integer.TryParse(v, r)
        Return r
    End Function

    Private Function LimpiarHtml(html As String) As String
        If html = "" Then Return ""
        Return HttpUtility.HtmlDecode(
            Text.RegularExpressions.Regex.Replace(html, "<[^>]+>", "")
        ).Trim()
    End Function

    ' ============================================================
    ' Helpers
    ' ============================================================
    Private Sub EscribirJS(key As String, script As String)
        ClientScript.RegisterStartupScript(Me.GetType(), key, script, True)
    End Sub

    Private Function EscJs(texto As String) As String
        If texto Is Nothing Then Return ""
        Return texto.Replace("\", "\\").Replace("'", "\'").Replace("""", "\""").
                     Replace(vbCr, "").Replace(vbLf, " ").Replace(vbTab, " ").
                     Substring(0, Math.Min(200, texto.Length))
    End Function

    Private Sub Log(origen As String, mensaje As String)
        System.Diagnostics.Debug.WriteLine("[MIGRAR][" & origen & "] " & mensaje)
    End Sub

    ' ============================================================
    ' Clases internas
    ' ============================================================
    Private Class WcCat
        Public Property WcId        As Integer
        Public Property PadreWcId   As Integer
        Public Property Nombre      As String = ""
        Public Property Slug        As String = ""
        Public Property Descripcion As String = ""
    End Class

    Private Class WcProd
        Public Property WcId        As Integer
        Public Property Nombre      As String = ""
        Public Property Sku         As String = ""
        Public Property Descripcion As String = ""
        Public Property PrecioBS    As String = ""
        Public Property PromoBS     As String = ""
        Public Property PromoDesde  As String = ""
        Public Property PromoHasta  As String = ""
        Public Property Tipo        As String = "simple"
        Public Property Destacado   As Boolean = False
        Public Property MenuOrder   As Integer = 0
        Public Property ImagenUrl   As String = ""
    End Class

    Private Class WcPedido
        ' Raiz
        Public Property WcId               As Integer
        Public Property WcOrderNumber      As String = ""
        Public Property WcOrderKey         As String = ""
        Public Property WcOrderStatus      As String = ""   ' on-hold, processing, entregado, failed...
        Public Property WcDatePaid         As DateTime?     ' date_paid de WC
        Public Property WcDateModified     As DateTime?     ' date_modified de WC
        Public Property WcDateCreated      As DateTime?     ' date_created de WC (fallback para fecha_entrega)
        Public Property PaymentMethod      As String = ""   ' banconacionalboliviapay, paypal...
        Public Property PaymentMethodTitle As String = ""   ' Paga con QR, PayPal...
        Public Property PaypalOrderId      As String = ""   ' _ppcp_paypal_order_id
        Public Property Observaciones      As String = ""
        Public Property TotalBs            As Decimal
        Public Property EnvioBs            As Decimal
        Public Property DescuentoBs        As Decimal
        Public Property WoocsRate          As Decimal       ' tasa BOB→USD
        ' Billing (quien compra)
        Public Property BillingNombre      As String = ""
        Public Property BillingApellidos   As String = ""
        Public Property BillingEmail       As String = ""
        Public Property BillingPhone       As String = ""
        ' Shipping (quien recibe)
        Public Property ShippingNombre     As String = ""
        Public Property ShippingPhone      As String = ""
        Public Property Direccion          As String = ""
        Public Property ShippingState      As String = ""   ' BO164 → zona
        ' Meta_data
        Public Property TelefonoRecibe     As String = ""
        Public Property DeliveryType       As String = ""   ' "delivery" o "pickup"
        Public Property DeliveryTime       As String = ""   ' 15:00 - 18:00 → slot
        Public Property DeliveryDate       As DateTime?     ' fecha REAL de entrega
        Public Property PickupDate         As DateTime?     ' fecha de recojo (si delivery_type=pickup)
        Public Property PickupTime         As String = ""   ' hora de recojo (si delivery_type=pickup)
        Public Property MensajeTarjeta     As String = ""   ' → dedicatoria
        Public Property FirmaTarjeta       As String = ""   ' → firma_tarjeta
        Public Property TipoOcacion        As String = ""   ' → tipo_ocacion
        Public Property NotaFloreria       As String = ""   ' → nota_floreria
        Public Property Gps                As String = ""   ' → gps
        ' Items
        Public Property Items As New List(Of WcPedidoItem)()
    End Class

    Private Class WcPedidoItem
        Public Property WcLineItemId    As Integer
        Public Property WcProductId     As Integer
        Public Property NombreProducto  As String  = ""
        Public Property Cantidad        As Integer = 1
        Public Property PrecioUnitarioBs As Decimal
        Public Property SubtotalBs       As Decimal
        Public Property Personalizacion  As String = ""
    End Class

End Class
