<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="Recibo.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_Recibo" %>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"/>
<title>Recibo <%=PedidoCodigo%></title>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<style>
/* ============================================================
   RECIBO TICKET TERMICO 80mm
   - Ancho de papel: 80mm. Margen impresion ~4mm c/lado -> util ~72mm.
   - Font monospace para que se vea como ticket clasico.
   - Todo en negro, sin colores (las impresoras termicas no imprimen color).
   ============================================================ */
* { box-sizing:border-box; margin:0; padding:0; }
html, body { background:#e0e0e0; font-family:'Courier New', Courier, monospace; color:#000; }
body { padding:20px 0; }

.ticket {
    width:72mm;
    background:white;
    margin:0 auto;
    padding:4mm 4mm 6mm;
    font-size:11pt;
    line-height:1.35;
    color:#000;
}

.ticket h1 { font-size:14pt; text-align:center; font-weight:bold; letter-spacing:1px; margin-bottom:2mm; }
.ticket .sub  { text-align:center; font-size:9pt; margin-bottom:3mm; }

.numWc   { text-align:center; font-size:26pt; font-weight:bold; letter-spacing:2px; line-height:1.1; margin:2mm 0 0; }
.numWcL  { text-align:center; font-size:8pt; letter-spacing:1px; margin-bottom:2mm; text-transform:uppercase; }
.numPed  { text-align:center; font-size:14pt; font-weight:bold; letter-spacing:1px; margin:1mm 0; }
.numPedL { text-align:center; font-size:8pt; text-transform:uppercase; margin-bottom:2mm; }

.fechaCreado { text-align:center; font-size:9pt; margin-bottom:3mm; }

.sep   { border-top:1px dashed #000; margin:3mm 0; }
.sep2  { border-top:2px solid  #000; margin:3mm 0; }

.titBloque { font-size:11pt; font-weight:bold; text-transform:uppercase; letter-spacing:1px; margin-bottom:1.5mm; text-align:center; }
.fila      { display:flex; justify-content:space-between; gap:2mm; font-size:10pt; margin-bottom:1mm; }
.fila .lbl { font-weight:bold; min-width:18mm; flex-shrink:0; }
.fila .val { text-align:right; word-break:break-word; }
.bloque    { margin-bottom:1mm; font-size:10pt; }

.prod        { margin-bottom:2mm; font-size:10pt; }
.prod .nom   { font-weight:bold; }
.prod .det   { font-size:9pt; padding-left:3mm; }
.prod .pers  { font-size:9pt; padding-left:3mm; font-style:italic; }
.prod .pre   { display:flex; justify-content:space-between; }

.totales        { font-size:10pt; }
.totales .fila  { margin-bottom:0.5mm; }
.totales .grand { border-top:1px solid #000; margin-top:1mm; padding-top:1mm; font-size:14pt; font-weight:bold; }

.tarjeta     { font-size:10pt; border:1px dashed #000; padding:2mm; margin-top:1mm; }
.tarjeta .ded { font-style:italic; word-break:break-word; }
.tarjeta .fir { text-align:right; margin-top:1mm; font-weight:bold; }

.nota { font-size:10pt; padding:2mm; background:#f0f0f0; border-radius:2mm; margin-top:1mm; word-break:break-word; }

.express { text-align:center; border:2px solid #000; padding:1.5mm; font-weight:bold; font-size:11pt; letter-spacing:2px; margin:2mm 0; }

.pagoBox   { font-size:10pt; }
.pagoEst   { display:inline-block; padding:0.5mm 2mm; border:1px solid #000; font-weight:bold; font-size:9pt; }

.footer { text-align:center; font-size:8pt; margin-top:4mm; line-height:1.3; }
.footer .ln1 { font-weight:bold; }

/* Barra de acciones (NO se imprime) */
.acciones { width:72mm; margin:0 auto 10px; display:flex; gap:6px; }
.acciones button {
    flex:1; padding:8px; font-size:13px; border:none; border-radius:4px;
    cursor:pointer; font-weight:500;
}
.btnPrint { background:#1976d2; color:white; }
.btnPrint:hover { background:#1565c0; }
.btnVolver { background:#757575; color:white; }
.btnVolver:hover { background:#616161; }

/* ============================================================
   IMPRESION: la barra superior desaparece, papel 80mm
   ============================================================ */
@media print {
    @page { size:80mm auto; margin:0; }
    html, body { background:white; padding:0; margin:0; }
    body * { visibility:hidden; }
    .ticket, .ticket * { visibility:visible; }
    .ticket { position:absolute; top:0; left:0; width:80mm; padding:3mm; margin:0; }
    .acciones { display:none !important; }
}
</style>
</head>
<body>

<!-- BARRA DE ACCIONES (no se imprime) -->
<div class="acciones">
    <button type="button" class="btnPrint" onclick="window.print()">🖨 Imprimir</button>
    <button type="button" class="btnVolver" onclick="window.close(); if(!window.closed) history.back();">Volver</button>
</div>

<!-- ============================================================
     TICKET
============================================================ -->
<div class="ticket">

    <h1>MISS FLORES</h1>
    <div class="sub">Recibo de Pedido</div>

    <div class="sep2"></div>

    <!-- NUMERO WOOCOMMERCE (grande) -->
    <div class="numWcL">WooCommerce</div>
    <div class="numWc"><%=WcNumero%></div>

    <!-- NUMERO PEDIDO (mediano) -->
    <div class="numPedL">Codigo interno</div>
    <div class="numPed"><%=PedidoCodigo%></div>

    <div class="fechaCreado">Creado: <%=FechaCreado%></div>

    <%=BloqueExpress%>

    <div class="sep"></div>

    <!-- ENTREGA -->
    <div class="titBloque">Entrega</div>
    <div class="fila"><span class="lbl">Fecha:</span><span class="val"><%=FechaEntrega%></span></div>
    <div class="fila"><span class="lbl">Horario:</span><span class="val"><%=Horario%></span></div>
    <div class="fila"><span class="lbl">Tipo:</span><span class="val"><%=TipoEntrega%></span></div>

    <div class="sep"></div>

    <!-- DESTINATARIO -->
    <div class="titBloque">Destinatario</div>
    <div class="fila"><span class="lbl">Recibe:</span><span class="val"><%=ReceptorNombre%></span></div>
    <div class="fila"><span class="lbl">Celular:</span><span class="val"><%=ReceptorCelular%></span></div>
    <%=BloqueDireccion%>
    <%=BloqueOcasion%>

    <div class="sep"></div>

    <!-- PRODUCTOS -->
    <div class="titBloque">Productos</div>
    <%=HtmlProductos%>

    <%=BloqueTarjeta%>

    <%=BloqueNotaFloreria%>

    <div class="sep"></div>

    <!-- TOTALES -->
    <div class="titBloque">Montos</div>
    <div class="totales">
        <div class="fila"><span>Subtotal productos:</span><span>Bs <%=SubtotalBs%></span></div>
        <%=BloqueEnvio%>
        <%=BloqueRecargoHor%>
        <%=BloqueRecargoExp%>
        <%=BloqueDescuento%>
        <div class="fila grand"><span>TOTAL:</span><span>Bs <%=TotalBs%></span></div>
    </div>

    <div class="sep"></div>

    <!-- PAGO -->
    <div class="titBloque">Pago</div>
    <div class="pagoBox">
        <div class="fila"><span class="lbl">Metodo:</span><span class="val"><%=MetodoPago%></span></div>
        <div class="fila"><span class="lbl">Estado:</span><span class="val"><span class="pagoEst"><%=EstadoPago%></span></span></div>
        <div class="fila"><span class="lbl">Pagado:</span><span class="val">Bs <%=MontoPagadoBs%></span></div>
        <%=BloqueSaldo%>
    </div>

    <div class="sep2"></div>

    <!-- CLIENTE QUE COMPRO -->
    <div class="titBloque">Cliente</div>
    <div class="fila"><span class="lbl">Nombre:</span><span class="val"><%=ClienteNombre%></span></div>
    <div class="fila"><span class="lbl">Celular:</span><span class="val"><%=ClienteCelular%></span></div>

    <div class="sep"></div>

    <!-- FOOTER -->
    <div class="footer">
        <div class="ln1">Floreria Miss Flores</div>
        <div>Sistema SISCONBOL</div>
        <div>Pre-pedido: <%=PrePedidoCodigo%></div>
        <%=BloqueAgente%>
    </div>

</div>

</body>
</html>
