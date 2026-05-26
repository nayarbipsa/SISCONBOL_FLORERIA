<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="TicketImprimir.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_TicketImprimir" %>
<!DOCTYPE html>
<html lang="es">
<head runat="server">
<meta charset="UTF-8">
<title>Ticket <%= CodigoPedido %></title>
<style>
@media print {
    @page {
        size: 80mm auto;
        margin: 0;
    }
    body { 
        margin: 0; 
        padding: 0;
    }
    .no-print { display: none !important; }
}

body {
    font-family: 'Courier New', Consolas, monospace;
    font-size: 11px;
    line-height: 1.35;
    color: #000;
    margin: 0;
    padding: 6px 8px;
    width: 80mm;
    background: white;
}

.center { text-align: center; }
.right { text-align: right; }
.bold { font-weight: bold; }
.big { font-size: 14px; font-weight: bold; }
.huge { font-size: 18px; font-weight: bold; }

.divider {
    border-top: 1px dashed #000;
    margin: 6px 0;
}

.divider-solid {
    border-top: 1px solid #000;
    margin: 4px 0;
}

.row {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 6px;
}

.row-label {
    font-weight: bold;
    flex-shrink: 0;
}

.row-value {
    text-align: right;
    word-break: break-word;
}

.section-title {
    font-weight: bold;
    background: #000;
    color: white;
    padding: 2px 4px;
    margin: 4px -2px;
    text-align: center;
    font-size: 10px;
    letter-spacing: 1px;
}

.product {
    margin: 4px 0;
}

.product-line {
    display: flex;
    justify-content: space-between;
    gap: 4px;
}

.product-name {
    flex: 1;
}

.product-extra {
    font-size: 10px;
    padding-left: 8px;
    font-style: italic;
}

.dedicatoria-box {
    border: 1px dashed #000;
    padding: 4px;
    margin: 4px 0;
    font-size: 10px;
    line-height: 1.5;
}

.nota-box {
    border-top: 1px solid #000;
    border-bottom: 1px solid #000;
    padding: 4px 0;
    margin: 4px 0;
    background: #f0f0f0;
}

.no-print {
    position: fixed;
    top: 10px;
    right: 10px;
    background: white;
    border: 1px solid #ccc;
    padding: 6px 10px;
    border-radius: 4px;
    font-family: Arial, sans-serif;
    cursor: pointer;
    font-size: 12px;
}

.codigo-grande {
    border: 2px solid #000;
    padding: 4px;
    margin: 4px 0;
    text-align: center;
}
</style>
</head>
<body onload="window.print()">
<form id="form1" runat="server">

<button type="button" class="no-print" onclick="window.print()">Imprimir</button>

<!-- HEADER -->
<div class="center bold big">MISS FLORES</div>
<div class="center" style="font-size:10px">Floreria Profesional</div>

<div class="divider"></div>

<!-- CODIGOS -->
<div class="codigo-grande">
    <div class="huge"><%= CodigoPedido %></div>
    <% If CodigoPrePedido <> "" Then %>
    <div style="font-size:10px">Pre-Pedido: <%= CodigoPrePedido %></div>
    <% End If %>
    <% If WcOrderNumber <> "" Then %>
    <div style="font-size:10px">WooCommerce: #<%= WcOrderNumber %></div>
    <% End If %>
</div>

<!-- ESTADO -->
<div class="row">
    <span class="row-label">Estado pago:</span>
    <span class="row-value bold"><%= EstadoPago %></span>
</div>
<div class="row">
    <span class="row-label">Estado op:</span>
    <span class="row-value"><%= EstadoOperativo %></span>
</div>
<% If EsExpress Then %>
<div class="center bold" style="margin:4px 0;border:1px solid #000;padding:2px">>>> EXPRESS <<<</div>
<% End If %>

<!-- ENTREGA -->
<div class="section-title">ENTREGA</div>

<div class="row">
    <span class="row-label">Fecha:</span>
    <span class="row-value bold"><%= FechaEntrega %></span>
</div>
<div class="row">
    <span class="row-label">Horario:</span>
    <span class="row-value"><%= SlotEtiqueta %></span>
</div>
<% If TipoOcasion <> "" Then %>
<div class="row">
    <span class="row-label">Ocasion:</span>
    <span class="row-value"><%= TipoOcasion %></span>
</div>
<% End If %>

<!-- RECEPTOR -->
<div class="section-title">RECEPTOR</div>

<div class="bold"><%= ReceptorNombre %></div>
<div>Tel: <%= ReceptorCelular %></div>
<div style="margin-top:3px"><%= Direccion %></div>
<% If Zona <> "" Then %>
<div style="font-size:10px"><%= Zona %><% If Ciudad <> "" Then %>, <%= Ciudad %><% End If %></div>
<% End If %>
<% If Referencia <> "" Then %>
<div style="font-size:10px; font-style:italic">Ref: <%= Referencia %></div>
<% End If %>
<% If Gps <> "" Then %>
<div style="font-size:10px">GPS: <%= Gps %></div>
<% End If %>

<!-- PRODUCTOS -->
<div class="section-title">PRODUCTOS</div>

<%= ProductosHtml %>

<!-- TOTALES -->
<div class="divider"></div>

<% If SubtotalProductos > 0 Then %>
<div class="row">
    <span>Subtotal productos:</span>
    <span class="row-value">Bs <%= SubtotalProductos.ToString("N2") %></span>
</div>
<% End If %>

<% If EnvioBs > 0 Then %>
<div class="row">
    <span>Envio:</span>
    <span class="row-value">Bs <%= EnvioBs.ToString("N2") %></span>
</div>
<% End If %>

<% If RecargoExpress > 0 Then %>
<div class="row">
    <span>Recargo express:</span>
    <span class="row-value">Bs <%= RecargoExpress.ToString("N2") %></span>
</div>
<% End If %>

<% If RecargoHorario > 0 Then %>
<div class="row">
    <span>Recargo horario:</span>
    <span class="row-value">Bs <%= RecargoHorario.ToString("N2") %></span>
</div>
<% End If %>

<% If DescuentoBs > 0 Then %>
<div class="row">
    <span>Descuento:</span>
    <span class="row-value">-Bs <%= DescuentoBs.ToString("N2") %></span>
</div>
<% End If %>

<div class="divider-solid"></div>

<div class="row big">
    <span>TOTAL:</span>
    <span class="row-value">Bs <%= TotalBs.ToString("N2") %></span>
</div>

<!-- DEDICATORIA -->
<% If Dedicatoria <> "" Then %>
<div class="section-title">TARJETA</div>
<div class="dedicatoria-box">
    "<%= Dedicatoria %>"
    <% If FirmaTarjeta <> "" Then %>
    <div style="text-align:right;margin-top:3px">--- <%= FirmaTarjeta %></div>
    <% End If %>
</div>
<% End If %>

<!-- NOTA INTERNA FLORERIA -->
<% If NotaFloreria <> "" Then %>
<div class="section-title">NOTA INTERNA</div>
<div class="nota-box">
    <%= NotaFloreria %>
</div>
<% End If %>

<!-- DELIVERY -->
<% If DeliveryNombre <> "" Then %>
<div class="divider"></div>
<div class="row">
    <span class="row-label">Delivery:</span>
    <span class="row-value bold"><%= DeliveryNombre %></span>
</div>
<% End If %>

<!-- FOOTER -->
<div class="divider"></div>
<div class="center" style="font-size:9px">
    Impreso: <%= FechaImpresion %><br>
    Por: <%= ImpresoPor %><br>
    <br>
    Gracias por confiar en Miss Flores!
</div>

<!-- Espacio para corte -->
<div style="height:30mm"></div>

</form>
</body>
</html>
