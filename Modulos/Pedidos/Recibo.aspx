<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="Recibo.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_Recibo" %>

<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"/>
<title>Recibo <%=PedidoCodigo%></title>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<style>
* { box-sizing:border-box; margin:0; padding:0; }
html, body { background:#e0e0e0; font-family:'Courier New', Courier, monospace; color:#000; }
body { padding:20px 0; }

.ticket {
    width:72mm;
    background:white;
    margin:0 auto;
    padding:4mm 4mm 6mm;
    font-size:10pt;
    line-height:1.35;
    color:#000;
}

.sep  { border-top:1px dashed #000; margin:3mm 0; }
.sep2 { border-top:2px solid  #000; margin:3mm 0; }

.fila     { display:flex; justify-content:space-between; gap:2mm; font-size:9pt; margin-bottom:1mm; }
.fila .lbl{ font-weight:bold; min-width:18mm; flex-shrink:0; }
.fila .val{ text-align:right; word-break:break-word; }

.titBloque { font-size:9pt; font-weight:bold; text-transform:uppercase;
             letter-spacing:1px; margin-bottom:1.5mm; text-align:center; }

.alerta-box { text-align:center; border:2px solid #000; padding:1.5mm;
              font-weight:bold; font-size:10pt; letter-spacing:1px; margin:2mm 0; }

.prod      { margin-bottom:2mm; font-size:10pt; }
.prod .nom { font-weight:bold; }
.prod .pers{ font-size:9pt; padding-left:3mm; font-style:italic; }

.tarjeta     { font-size:9pt; border:1px dashed #000; padding:2mm; margin-top:1mm; }
.tarjeta .ded{ font-style:italic; word-break:break-word; }
.tarjeta .fir{ text-align:right; margin-top:1mm; font-weight:bold; }

.nota { font-size:9pt; padding:2mm; background:#f0f0f0; border-radius:2mm;
        margin-top:1mm; word-break:break-word; }

.pagoEst { display:inline-block; padding:0.5mm 2mm;
           border:1px solid #000; font-weight:bold; font-size:8pt; }

.footer { text-align:center; font-size:8pt; margin-top:3mm; }

.acciones { width:72mm; margin:0 auto 10px; display:flex; gap:6px; }
.acciones button {
    flex:1; padding:8px; font-size:13px; border:none;
    border-radius:4px; cursor:pointer; font-weight:500;
}
.btnPrint  { background:#1976d2; color:white; }
.btnVolver { background:#757575; color:white; }
.btnWC     { background:#7B5EA7; color:white; }
.btnWC-dis { background:#bdbdbd; color:white; cursor:not-allowed; }

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

<div class="acciones">
    <button type="button" class="btnPrint"  onclick="window.print()">Imprimir</button>
    <% If WcOrderIdVal > 0 Then %>
    <button type="button" class="btnWC" onclick="window.open('https://miss-flores.com/wp-admin/post.php?post=<%=WcOrderIdVal%>&action=edit','_blank')">Ver en WC</button>
    <% Else %>
    <button type="button" class="btnWC-dis" disabled title="Sin pedido en WooCommerce">Sin WC</button>
    <% End If %>
    <button type="button" class="btnVolver" onclick="window.close(); if(!window.closed) history.back();">Volver</button>
</div>

<div class="ticket">

    <div class="sep2"></div>

    <!-- ENCABEZADO: PED-XX a la izquierda, #WC grande a la derecha -->
    <div style="display:flex;justify-content:space-between;align-items:baseline;margin-bottom:1.5mm">
        <span style="font-size:13pt;font-weight:bold;letter-spacing:1px"><%=PedidoCodigo%></span>
        <span style="font-size:26pt;font-weight:bold;letter-spacing:2px;line-height:1"><%=WcNumero%></span>
    </div>

    <!-- FILA: PRE + fecha | recuadro sucursal -->
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1mm">
        <span style="font-size:8pt;color:#333"><%=LineaPreFecha%></span>
        <%=BloqueSucursalBadge%>
    </div>
    <div style="font-size:8pt;color:#333;margin-bottom:3mm"><%=LineaAgente%></div>

    <%=BloqueExpress%>
    <%=BloqueCobrar%>

    <div class="sep"></div>

    <!-- CLIENTE -->
    <div class="titBloque">Cliente</div>
    <div class="fila"><span class="lbl">Nombre:</span><span class="val"><%=ClienteNombre%></span></div>
    <div class="fila"><span class="lbl">Celular:</span><span class="val"><%=ClienteCelular%></span></div>

    <div class="sep"></div>

    <!-- ENTREGA -->
    <div class="titBloque">Entrega</div>
    <div class="fila"><span class="lbl">Fecha:</span><span class="val"><%=FechaEntrega%></span></div>
    <div class="fila"><span class="lbl">Horario:</span><span class="val"><%=Horario%></span></div>
    <div class="fila"><span class="lbl">Zona:</span><span class="val"><%=ZonaNombre%></span></div>

    <div class="sep"></div>

    <!-- PRODUCTOS -->
    <div class="titBloque">Productos</div>
    <%=HtmlProductos%>

    <%=BloqueNotaFloreria%>

    <div class="sep"></div>

    <!-- DESTINATARIO -->
    <div class="titBloque">Destinatario</div>
    <div class="fila"><span class="lbl">Recibe:</span><span class="val"><%=ReceptorNombre%></span></div>
    <div class="fila"><span class="lbl">Celular:</span><span class="val"><%=ReceptorCelular%></span></div>
    <%=BloqueDireccion%>
    <%=BloqueOcasion%>

    <%=BloqueTarjeta%>

    <div class="sep"></div>

    <!-- PAGO -->
    <div class="titBloque">Pago</div>
    <div class="fila"><span class="lbl">Metodo:</span><span class="val"><%=MetodoPago%></span></div>
    <div class="fila"><span class="lbl">Estado:</span><span class="val"><span class="pagoEst"><%=EstadoPago%></span></span></div>

    <div class="sep2"></div>

    <div class="footer"><%=LineaAgente%></div>

</div>
</body>
</html>
