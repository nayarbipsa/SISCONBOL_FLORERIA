<%@ Page Title="Detalle Pre-Pedido" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="PrePedido_Detalle.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_PrePedido_Detalle" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
.header-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 12px;
    padding: 1.5rem;
    color: white;
    margin-bottom: 1.5rem;
}
.header-top {
    display: flex;
    justify-content: space-between;
    align-items: start;
    margin-bottom: 1rem;
}
.header-info h2 {
    margin: 0 0 0.5rem 0;
    font-size: 24px;
    font-weight: 500;
}
.header-meta {
    font-size: 13px;
    opacity: 0.9;
}
.cliente-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin-top: 1rem;
}
.cliente-item {
    background: rgba(255,255,255,0.15);
    padding: 0.75rem;
    border-radius: 8px;
}
.cliente-label {
    font-size: 11px;
    opacity: 0.8;
    text-transform: uppercase;
    margin-bottom: 0.25rem;
}
.cliente-value {
    font-size: 15px;
    font-weight: 500;
}
.pedidos-section {
    margin-bottom: 1.5rem;
}
.pedido-card {
    background: white;
    border: 2px solid #e0e0e0;
    border-radius: 12px;
    padding: 1.25rem;
    margin-bottom: 1rem;
    transition: all 0.2s;
}
.pedido-card:hover {
    border-color: #667eea;
    box-shadow: 0 4px 12px rgba(102,126,234,0.15);
}
.pedido-card.activo {
    border-color: #667eea;
    background: #f8f9ff;
}
.pedido-numero {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    background: #667eea;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 16px;
    font-weight: 500;
    flex-shrink: 0;
}
.pedido-header {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #e0e0e0;
}
.pedido-info {
    flex: 1;
}
.pedido-codigo {
    font-size: 16px;
    font-weight: 500;
    margin: 0 0 0.25rem 0;
}
.pedido-desc {
    font-size: 13px;
    color: #757575;
    margin: 0;
}
.pedido-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin-bottom: 1rem;
}
.pedido-field {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
}
.pedido-field-label {
    font-size: 11px;
    color: #757575;
    text-transform: uppercase;
}
.pedido-field-value {
    font-size: 14px;
    font-weight: 500;
    color: #212121;
}
.productos-lista {
    background: #fafafa;
    border-radius: 8px;
    padding: 1rem;
    margin-bottom: 1rem;
}
.producto-item {
    display: flex;
    gap: 1rem;
    padding: 0.75rem;
    background: white;
    border-radius: 6px;
    margin-bottom: 0.5rem;
}
.producto-item:last-child {
    margin-bottom: 0;
}
.producto-icon {
    width: 50px;
    height: 50px;
    background: #f0f0f0;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}
.producto-info {
    flex: 1;
}
.producto-nombre {
    font-size: 14px;
    font-weight: 500;
    margin: 0 0 0.25rem 0;
}
.producto-sku {
    font-size: 12px;
    color: #757575;
    margin: 0;
}
.producto-precio {
    text-align: right;
}
.producto-cantidad {
    font-size: 12px;
    color: #757575;
    margin-bottom: 0.25rem;
}
.producto-subtotal {
    font-size: 15px;
    font-weight: 500;
    color: #667eea;
}
.totales-box {
    background: rgba(102,126,234,0.1);
    border-radius: 8px;
    padding: 1rem;
    border: 1px solid rgba(102,126,234,0.2);
}
.total-line {
    display: flex;
    justify-content: space-between;
    padding: 0.5rem 0;
}
.total-line.main {
    border-top: 2px solid rgba(102,126,234,0.3);
    padding-top: 0.75rem;
    margin-top: 0.5rem;
}
.total-label {
    font-size: 13px;
    color: #424242;
}
.total-value {
    font-size: 14px;
    font-weight: 500;
}
.total-line.main .total-label {
    font-size: 15px;
    font-weight: 500;
}
.total-line.main .total-value {
    font-size: 18px;
    font-weight: 500;
    color: #667eea;
}
.link-section {
    background: #E8F5E9;
    border: 1px solid #4CAF50;
    border-left: 4px solid #4CAF50;
    border-radius: 8px;
    padding: 1rem;
    margin-bottom: 1.5rem;
}
.link-header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
}
.link-title {
    font-size: 14px;
    font-weight: 500;
    color: #2E7D32;
}
.link-url {
    background: white;
    border: 1px solid #C8E6C9;
    border-radius: 6px;
    padding: 0.75rem;
    font-family: monospace;
    font-size: 12px;
    color: #333;
    word-break: break-all;
    margin-bottom: 0.75rem;
}
.link-actions {
    display: flex;
    gap: 0.5rem;
}
.empty-state {
    text-align: center;
    padding: 3rem 1rem;
    color: #9e9e9e;
}
.empty-icon {
    font-size: 48px;
    margin-bottom: 1rem;
    opacity: 0.3;
}
.empty-text {
    font-size: 15px;
    margin-bottom: 1.5rem;
}
</style>
</asp:Content>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-file-text" style="vertical-align:-2px"></i> Detalle Pre-Pedido
</asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

<div class="alerta" id="divAlerta"><%=MensajeAlerta%></div>

<!-- HEADER CON INFO DEL PRE-PEDIDO -->
<div class="header-card">
    <div class="header-top">
        <div class="header-info">
            <h2>Pre-Pedido <%=Codigo%></h2>
            <div class="header-meta">
                Creado <%=FechaCreacion%> por <%=NombreAgente%>
            </div>
        </div>
        <div>
            <%=BadgeEstado%>
        </div>
    </div>
    
    <div class="cliente-grid">
        <div class="cliente-item">
            <div class="cliente-label">Cliente</div>
            <div class="cliente-value"><%=ClienteNombre%></div>
        </div>
        <div class="cliente-item">
            <div class="cliente-label">Celular</div>
            <div class="cliente-value"><%=ClienteCelular%></div>
        </div>
        <div class="cliente-item">
            <div class="cliente-label">Email</div>
            <div class="cliente-value"><%=ClienteEmail%></div>
        </div>
        <div class="cliente-item">
            <div class="cliente-label">Tipo</div>
            <div class="cliente-value"><%=TipoRegistro%></div>
        </div>
    </div>
</div>

<!-- LINK WEB GENERADO -->
<%If LinkWebGenerado Then%>
<div class="link-section">
    <div class="link-header">
        <i class="ti ti-link" style="font-size: 18px; color: #2E7D32;"></i>
        <h3 class="link-title">Link generado para el cliente</h3>
    </div>
    <div class="link-url"><%=LinkCompleto%></div>
    <div class="link-actions">
        <button type="button" class="btn btn-sm" onclick="copiarLink()">
            <i class="ti ti-copy"></i>
            Copiar
        </button>
        <button type="button" class="btn btn-sm" onclick="enviarWhatsApp()" style="background: #25D366; color: white; border-color: #25D366;">
            <i class="ti ti-brand-whatsapp"></i>
            Enviar WhatsApp
        </button>
        <button type="button" class="btn btn-sm" onclick="verEnNavegador()">
            <i class="ti ti-external-link"></i>
            Abrir
        </button>
    </div>
    <div style="margin-top: 0.5rem; font-size: 12px; color: #2E7D32;">
        <i class="ti ti-clock" style="font-size: 14px; vertical-align: -2px;"></i>
        Valido hasta: <%=FechaExpiracion%>
    </div>
</div>
<%End If%>

<!-- PEDIDOS (ENTREGAS) -->
<div class="panel">
    <div class="panel-head">
        <div class="panel-title">
            <i class="ti ti-truck-delivery"></i>
            Pedidos (Entregas)
            <span style="background: #e0e0e0; padding: 2px 8px; border-radius: 4px; font-size: 11px; margin-left: 8px;">
                <%=CantidadPedidos%> entregas
            </span>
        </div>
        <button type="button" class="btn btn-primary btn-sm" onclick="agregarPedido()">
            <i class="ti ti-plus"></i>
            Agregar pedido
        </button>
    </div>
    <div class="panel-body">
        
        <%If CantidadPedidos > 0 Then%>
            <div class="pedidos-section">
                <%=HtmlPedidos%>
            </div>
        <%Else%>
            <div class="empty-state">
                <div class="empty-icon">
                    <i class="ti ti-package-off"></i>
                </div>
                <div class="empty-text">
                    No hay pedidos agregados aun
                </div>
                <button type="button" class="btn btn-primary" onclick="agregarPedido()">
                    <i class="ti ti-plus"></i>
                    Agregar primer pedido
                </button>
            </div>
        <%End If%>
        
    </div>
</div>

<!-- RESUMEN TOTAL -->
<%If CantidadPedidos > 0 Then%>
<div class="panel">
    <div class="panel-head">
        <div class="panel-title">
            <i class="ti ti-calculator"></i>
            Resumen Total
        </div>
    </div>
    <div class="panel-body">
        <div class="totales-box">
            <div class="total-line">
                <span class="total-label">Subtotal productos:</span>
                <span class="total-value"><%=TotalProductos%> Bs</span>
            </div>
            <div class="total-line">
                <span class="total-label">Envios total:</span>
                <span class="total-value"><%=TotalEnvios%> Bs</span>
            </div>
            <div class="total-line main">
                <span class="total-label">TOTAL GENERAL:</span>
                <span class="total-value"><%=TotalGeneral%> Bs</span>
            </div>
            <div style="text-align: right; margin-top: 0.5rem; font-size: 12px; color: #757575;">
                <%=CantidadPedidos%> entregas • <%=CantidadProductos%> productos
            </div>
        </div>
    </div>
</div>
<%End If%>

<!-- ACCIONES -->
<div class="panel">
    <div class="panel-body">
        <div style="display: flex; gap: 10px; justify-content: flex-end; flex-wrap: wrap;">
            <button type="button" class="btn" onclick="window.location.href='PrePedidos.aspx'">
                <i class="ti ti-arrow-left"></i>
                Volver
            </button>
            
            <%If Estado = "BORRADOR" Then%>
            <button type="button" class="btn" onclick="cancelarPrePedido()">
                <i class="ti ti-x"></i>
                Cancelar
            </button>
            <button type="button" class="btn" onclick="guardarBorrador()">
                <i class="ti ti-device-floppy"></i>
                Guardar
            </button>
            <button type="button" class="btn btn-success" onclick="finalizarYEnviar()">
                <i class="ti ti-send"></i>
                Finalizar y enviar link
            </button>
            <%End If%>
        </div>
    </div>
</div>

<!-- Hidden fields -->
<input type="hidden" id="hdPrePedidoId" value="<%=PrePedidoId%>" />
<input type="hidden" id="hdCelular" value="<%=ClienteCelular%>" />
<input type="hidden" id="hdLink" value="<%=LinkCompleto%>" />

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

function copiarLink() {
    var link = document.getElementById('hdLink').value;
    if (navigator.clipboard) {
        navigator.clipboard.writeText(link).then(function() {
            alert('✓ Link copiado al portapapeles');
        });
    } else {
        alert('Link: ' + link);
    }
}

function enviarWhatsApp() {
    var celular = document.getElementById('hdCelular').value;
    var link = document.getElementById('hdLink').value;
    var url = 'https://wa.me/' + celular + '?text=' + encodeURIComponent(link);
    window.open(url, '_blank');
}

function verEnNavegador() {
    var link = document.getElementById('hdLink').value;
    window.open(link, '_blank');
}

function agregarPedido() {
    var id = document.getElementById('hdPrePedidoId').value;
    window.location.href = 'Pedido_Agregar.aspx?prepedido=' + id;
}

function editarPedido(pedidoId) {
    window.location.href = 'Pedido_Editar.aspx?id=' + pedidoId;
}

function eliminarPedido(pedidoId) {
    if (confirm('¿Estas seguro de eliminar este pedido?')) {
        // TODO: Implementar eliminacion
        alert('Funcionalidad en desarrollo');
    }
}

function cancelarPrePedido() {
    if (confirm('¿Cancelar este pre-pedido?')) {
        // TODO: Implementar cancelacion
        alert('Funcionalidad en desarrollo');
    }
}

function guardarBorrador() {
    alert('Pre-pedido guardado como borrador');
}

function finalizarYEnviar() {
    if (confirm('¿Finalizar y enviar link al cliente?')) {
        var id = document.getElementById('hdPrePedidoId').value;
        window.location.href = 'PrePedido_Finalizar.aspx?id=' + id;
    }
}
</script>
</asp:Content>
