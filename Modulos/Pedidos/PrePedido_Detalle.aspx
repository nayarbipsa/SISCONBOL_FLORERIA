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
    display: flex;
    align-items: center;
    gap: 6px;
}
.cliente-value {
    font-size: 15px;
    font-weight: 500;
}
.btn-edit-inline{background:rgba(255,255,255,.2);border:none;color:#fff;padding:2px 6px;border-radius:4px;cursor:pointer;opacity:.85;display:inline-flex;align-items:center}
.btn-edit-inline:hover{opacity:1;background:rgba(255,255,255,.32)}
.btn-edit-inline i{font-size:13px}
.cliente-edit{display:flex;flex-direction:column;gap:5px}
.edit-fields{display:flex;flex-direction:column;gap:4px}
.edit-inp{background:rgba(255,255,255,.95);border:1px solid rgba(255,255,255,.4);color:#212121;padding:6px 9px;border-radius:6px;font-size:13px;width:100%;outline:none}
.edit-inp:focus{background:#fff;border-color:#fff}
.edit-actions{display:flex;gap:6px;margin-top:2px}
.btn-edit-save,.btn-edit-cancel{border:none;padding:5px 10px;border-radius:6px;font-size:11px;font-weight:500;cursor:pointer;display:inline-flex;align-items:center;gap:4px}
.btn-edit-save{background:#4caf50;color:#fff}
.btn-edit-cancel{background:rgba(255,255,255,.25);color:#fff}
.edit-error{font-size:11px;color:#ffcdd2;background:rgba(198,40,40,.4);padding:4px 8px;border-radius:4px}
.btn-cotiz{background:#E8F5E9 !important;border:1px solid #A5D6A7 !important;color:#1B5E20 !important;font-weight:500}
.btn-cotiz:hover{background:#C8E6C9 !important}
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

/* ============================================================
   CARDS COMPACTAS — entregas borrador y pedidos confirmados
   3 líneas: header, receptor, info+total. Toda la card es clickeable.
   ============================================================ */
.card-compact{
    background:#fff;
    border:0.5px solid #e0e0e0;
    border-radius:6px;
    padding:10px 12px;
    margin-bottom:6px;
    cursor:pointer;
    transition:all .15s;
}
.card-compact:hover{
    background:#FFF8FB;
    border-color:#C2185B;
}
.card-bor{ background:#FFFDF6; border-color:#FFE0B2; }
.card-bor:hover{ background:#FFF8E1; border-color:#FB923C; }

.cc-row1{ display:flex; align-items:center; gap:8px; margin-bottom:4px; }
.cc-num{
    width:22px; height:22px; border-radius:50%;
    color:#fff;
    display:flex; align-items:center; justify-content:center;
    font-size:11px; font-weight:600;
    flex-shrink:0;
}
.cc-num-conf{ background:#7F77DD; }
.cc-num-draft{ background:#FB923C; }
.cc-cod{
    font-family:monospace; font-size:11px; font-weight:600;
    color:#7F77DD;
}
.cc-tag{
    padding:2px 7px; border-radius:99px;
    font-size:10px; font-weight:500;
    white-space:nowrap;
    display:inline-flex; align-items:center; gap:3px;
}
.cc-tag-conf{ background:#E8F5E9; color:#2E7D32; }
.cc-tag-draft{ background:#FFF3E0; color:#E65100; }
.cc-tag i{ font-size:10px; }

.cc-menu-btn{
    background:#f5f5f5;
    border:0.5px solid #e0e0e0;
    padding:3px 8px;
    border-radius:5px;
    font-size:10px;
    cursor:pointer;
    color:#424242;
    display:inline-flex;
    align-items:center;
    gap:3px;
    font-weight:500;
    flex-shrink:0;
}
.cc-menu-btn:hover{ background:#eee; }
.cc-menu-btn i{ font-size:10px; }

.cc-row2{
    display:flex; align-items:center; gap:10px;
    flex-wrap:wrap; margin-bottom:3px;
}
.cc-nom{ font-size:13px; font-weight:500; color:#212121; }
.cc-meta{
    font-size:11px; color:#9e9e9e;
    display:inline-flex; align-items:center; gap:3px;
}
.cc-meta i{ font-size:11px; }

.cc-row3{
    display:flex; justify-content:space-between; align-items:center;
    gap:8px;
    margin-top:4px; padding-top:6px;
    border-top:0.5px dashed #f0f0f0;
}
.cc-info{
    font-size:11px; color:#666;
    display:flex; align-items:center; gap:8px;
    flex-wrap:wrap; flex:1; min-width:0;
}
.cc-info-item{ display:inline-flex; align-items:center; gap:3px; }
.cc-info-item i{ font-size:11px; color:#9e9e9e; }

.cc-pill-exp{
    background:#FFE0B2; color:#E65100;
    font-size:9px; padding:1px 5px;
    border-radius:3px; font-weight:500;
}

.cc-total-wrap{ text-align:right; flex-shrink:0; }
.cc-total{ font-size:13px; font-weight:600; color:#212121; white-space:nowrap; }
.cc-total-empty{ color:#bdbdbd; }
.cc-total-sub{
    font-size:9px; color:#9e9e9e;
    display:block; margin-top:1px;
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
            <div class="cliente-label">
                Cliente
                <button type="button" id="btnEditNombre" class="btn-edit-inline" onclick="iniciarEdicionNombre()" title="Editar nombre">
                    <i class="ti ti-pencil"></i>
                </button>
            </div>
            <div class="cliente-value" id="vistaNombre"><%=ClienteNombre%></div>
            <div class="cliente-edit" id="editNombre" style="display:none">
                <div class="edit-fields">
                    <input type="text" id="inpNombre" class="edit-inp" maxlength="200" placeholder="Nombre" value="<%=ClienteNombreSolo%>" />
                    <input type="text" id="inpApellidos" class="edit-inp" maxlength="200" placeholder="Apellidos" value="<%=ClienteApellidos%>" />
                </div>
                <div class="edit-actions">
                    <button type="button" class="btn-edit-save" onclick="guardarNombreCliente()"><i class="ti ti-check"></i> Guardar</button>
                    <button type="button" class="btn-edit-cancel" onclick="cancelarEdicionNombre()"><i class="ti ti-x"></i> Cancelar</button>
                </div>
                <div class="edit-error" id="errEditNombre" style="display:none"></div>
            </div>
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

<!-- ESTADO DEL LINK PARA EL CLIENTE -->
<div class="panel">
    <div class="panel-head">
        <div class="panel-title">
            <i class="ti ti-link" style="color:#3B5BDB"></i>
            Link para el cliente
            <% If EstadoLink = 0 Then %>
                <span style="background:#f5f5f5;color:#666;padding:2px 8px;border-radius:4px;font-size:11px;margin-left:8px">No enviado</span>
            <% ElseIf EstadoLink = 1 AndAlso LinkExpirado Then %>
                <span style="background:#FFEBEE;color:#C62828;padding:2px 8px;border-radius:4px;font-size:11px;margin-left:8px">Expirado</span>
            <% ElseIf EstadoLink = 1 Then %>
                <span style="background:#FFF3CD;color:#856404;padding:2px 8px;border-radius:4px;font-size:11px;margin-left:8px">Esperando cliente</span>
            <% Else %>
                <span style="background:#E8F5E9;color:#2E7D32;padding:2px 8px;border-radius:4px;font-size:11px;margin-left:8px">Cliente confirmó</span>
            <% End If %>
        </div>
    </div>
    <div class="panel-body" style="padding-top:0.75rem">

        <% If EstadoLink = 0 Then %>
            <p style="margin:0 0 12px;font-size:13px;color:#666">
                Genera y envia al cliente un link para que confirme sus datos, direccion, fecha y metodo de pago.
            </p>
            <button type="button" onclick="enviarLinkCliente()" style="width:100%;max-width:320px;padding:11px;font-size:13px;background:#25D366;color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:500">
                <i class="ti ti-brand-whatsapp" style="font-size:15px;vertical-align:-2px;margin-right:5px"></i> Enviar link por WhatsApp
            </button>

        <% ElseIf EstadoLink = 1 AndAlso LinkExpirado Then %>
            <div style="background:#FFEBEE;padding:10px 12px;border-radius:6px;margin-bottom:10px;font-size:12px;color:#C62828">
                <i class="ti ti-alert-triangle" style="font-size:14px;vertical-align:-2px;margin-right:4px"></i>
                El link expiro el <%=FechaExpiracion%>. Genera uno nuevo.
            </div>
            <button type="button" onclick="enviarLinkCliente()" style="padding:9px 16px;font-size:12px;background:#25D366;color:#fff;border:none;border-radius:8px;cursor:pointer;font-weight:500">
                <i class="ti ti-refresh" style="font-size:14px;vertical-align:-2px"></i> Regenerar y reenviar
            </button>

        <% ElseIf EstadoLink = 1 Then %>
            <% If TokenAbiertoEn > DateTime.MinValue Then %>
                <div style="background:#E3F2FD;padding:8px 12px;border-radius:6px;margin-bottom:8px;font-size:12px;color:#1565C0">
                    <i class="ti ti-eye" style="font-size:14px;vertical-align:-2px;margin-right:4px"></i> Cliente abrio el link el <%=TokenAbiertoEn.ToString("dd/MM HH:mm")%>
                </div>
            <% Else %>
                <div style="background:#FFF8E1;padding:8px 12px;border-radius:6px;margin-bottom:8px;font-size:12px;color:#F57F17">
                    <i class="ti ti-clock" style="font-size:14px;vertical-align:-2px;margin-right:4px"></i> Cliente aun no abrio el link
                </div>
            <% End If %>
            <div style="font-size:11px;color:#666;margin-bottom:10px">Expira en <%=HorasParaExpirar%>h &middot; <%=FechaExpiracion%></div>
            <div style="display:flex;gap:8px;flex-wrap:wrap">
                <button type="button" onclick="location.reload()" class="btn btn-sm">
                    <i class="ti ti-refresh"></i> Verificar
                </button>
                <button type="button" onclick="copiarLink()" class="btn btn-sm">
                    <i class="ti ti-copy"></i> Copiar link
                </button>
                <% If CantidadPedidos > 0 OrElse CantidadBorradores > 0 Then %>
                <button type="button" onclick="enviarCotizacion()" class="btn btn-sm btn-cotiz">
                    <i class="ti ti-brand-whatsapp" style="color:#25D366"></i> Cotización
                </button>
                <% End If %>
                <button type="button" onclick="enviarLinkCliente()" class="btn btn-sm">
                    <i class="ti ti-brand-whatsapp" style="color:#25D366"></i> Reenviar WhatsApp
                </button>
            </div>

        <% Else %>
            <div style="background:#E8F5E9;padding:10px 12px;border-radius:6px;margin-bottom:10px;font-size:12px;color:#1B5E20">
                <p style="margin:0;font-weight:500"><i class="ti ti-check" style="font-size:14px;vertical-align:-2px"></i> Cliente confirmo el <%=TokenConfirmadoEn.ToString("dd/MM HH:mm")%></p>
                <p style="margin:4px 0 0;font-size:11px;color:#2E7D32">Revisa los datos abajo y confirma el pedido cuando estes listo</p>
            </div>
            <div style="display:flex;gap:8px;flex-wrap:wrap">
                <button type="button" onclick="copiarLink()" class="btn btn-sm">
                    <i class="ti ti-copy"></i> Copiar link
                </button>
                <% If CantidadPedidos > 0 OrElse CantidadBorradores > 0 Then %>
                <button type="button" onclick="enviarCotizacion()" class="btn btn-sm btn-cotiz">
                    <i class="ti ti-brand-whatsapp" style="color:#25D366"></i> Cotización
                </button>
                <% End If %>
            </div>
        <% End If %>

    </div>
</div>

<!-- BORRADORES (ENTREGAS EN PROCESO) -->
<%If CantidadBorradores > 0 Then%>
<div class="panel">
    <div class="panel-head">
        <div class="panel-title">
            <i class="ti ti-pencil" style="color:#F9A825"></i>
            Borradores en proceso
            <span style="background: #FFF3CD; color:#856404; padding: 2px 8px; border-radius: 4px; font-size: 11px; margin-left: 8px;">
                <%=CantidadBorradores%>
            </span>
        </div>
        <button type="button" class="btn btn-primary btn-sm" onclick="agregarEntrega()">
            <i class="ti ti-plus"></i>
            Nueva entrega
        </button>
    </div>
    <div class="panel-body">
        <div class="pedidos-section">
            <%=HtmlBorradores%>
        </div>
    </div>
</div>
<%End If%>

<!-- PEDIDOS CONFIRMADOS -->
<div class="panel">
    <div class="panel-head">
        <div class="panel-title">
            <i class="ti ti-truck-delivery"></i>
            Pedidos confirmados
            <span style="background: #e0e0e0; padding: 2px 8px; border-radius: 4px; font-size: 11px; margin-left: 8px;">
                <%=CantidadPedidos%>
            </span>
        </div>
        <%If CantidadBorradores = 0 Then%>
        <button type="button" class="btn btn-primary btn-sm" onclick="agregarEntrega()">
            <i class="ti ti-plus"></i>
            Nueva entrega
        </button>
        <%End If%>
    </div>
    <div class="panel-body">
        
        <%If CantidadPedidos > 0 Then%>
            <div class="pedidos-section">
                <%=HtmlPedidos%>
            </div>
        <%ElseIf CantidadBorradores = 0 Then%>
            <div class="empty-state">
                <div class="empty-icon">
                    <i class="ti ti-package-off"></i>
                </div>
                <div class="empty-text">
                    No hay entregas registradas aun
                </div>
                <button type="button" class="btn btn-primary" onclick="agregarEntrega()">
                    <i class="ti ti-plus"></i>
                    Agregar primera entrega
                </button>
            </div>
        <%Else%>
            <div class="empty-state" style="padding: 1.5rem;">
                <div class="empty-text" style="color:#999;font-size:13px">
                    No hay pedidos confirmados todavia
                </div>
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

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

// ============================================================
// LINK PUBLICO CLIENTE
// ============================================================
function enviarLinkCliente() {
    var prepedidoId = parseInt(document.getElementById('hdPrePedidoId').value) || 0;
    if (prepedidoId === 0) {
        alert('Pre-pedido invalido');
        return;
    }

    var formData = new FormData();
    formData.append('accion', 'GENERAR_TOKEN');
    formData.append('prepedido_id', prepedidoId);

    fetch('PrePedido_Handler.ashx', { method: 'POST', body: formData })
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (!data.ok) {
                // Si el handler devolvió entregas_incompletas, mostrar modal detallado
                if (data.entregas_incompletas && data.entregas_incompletas.length > 0) {
                    mostrarModalEntregasIncompletas(data.entregas_incompletas);
                    return;
                }
                alert('Error: ' + (data.msg || 'no se pudo generar el link'));
                return;
            }

            var mensaje = 'Hola! Aqui esta el link para confirmar tu pedido en Miss Flores:\n' + data.url;

            // MODIFICACIÓN A OPCIÓN 2: Usar el esquema nativo de WhatsApp
            var url = data.celular_cliente
                ? ('whatsapp://send?phone=' + data.celular_cliente + '&text=' + encodeURIComponent(mensaje))
                : ('whatsapp://send?text=' + encodeURIComponent(mensaje));

            // Usar window.location.href en lugar de window.open('_blank')
            // Esto dispara la aplicación externa sin abrir ninguna pestaña huérfana
            window.location.href = url;

            // Aumentamos ligeramente el tiempo de espera a 1.5 seg (1500ms) antes de recargar
            // para darle tiempo al navegador de ejecutar la llamada a la app de escritorio o móvil
            setTimeout(function () {
                location.reload();
            }, 1500);
        })
        .catch(function () {
            alert('Error de red al generar el link');
        });
}

function copiarLink() {
    var prepedidoId = parseInt(document.getElementById('hdPrePedidoId').value) || 0;
    if (prepedidoId === 0) return;

    var formData = new FormData();
    formData.append('accion', 'GENERAR_TOKEN');
    formData.append('prepedido_id', prepedidoId);

    fetch('PrePedido_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (!data.ok) {
            // Mismo manejo: si hay entregas incompletas, modal detallado
            if (data.entregas_incompletas && data.entregas_incompletas.length > 0) {
                mostrarModalEntregasIncompletas(data.entregas_incompletas);
                return;
            }
            alert('Error: ' + (data.msg || 'no se pudo obtener el link'));
            return;
        }
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(data.url)
                .then(function() { alert('Link copiado:\n' + data.url); })
                .catch(function() { prompt('Copia este link:', data.url); });
        } else {
            prompt('Copia este link:', data.url);
        }
    });
}

// ============================================================
// MODAL: entregas incompletas (bloquea envío del link)
// ============================================================
function mostrarModalEntregasIncompletas(lista) {
    // Crear overlay si no existe
    var overlay = document.getElementById('modalValidacionLink');
    if (overlay) overlay.parentNode.removeChild(overlay);

    overlay = document.createElement('div');
    overlay.id = 'modalValidacionLink';
    overlay.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.5);z-index:10000;overflow-y:auto;padding:20px;display:flex;align-items:flex-start;justify-content:center';

    var prepedidoId = parseInt(document.getElementById('hdPrePedidoId').value) || 0;

    var html = '<div style="background:white;border-radius:12px;max-width:560px;width:100%;margin-top:40px;overflow:hidden;box-shadow:0 10px 40px rgba(0,0,0,0.2)">';

    // Header rojo de alerta
    html += '<div style="background:#FFEBEE;color:#B71C1C;padding:16px 22px;display:flex;align-items:center;gap:12px;border-bottom:2px solid #FFCDD2">';
    html += '<i class="ti ti-alert-triangle" style="font-size:28px;color:#C62828"></i>';
    html += '<div style="flex:1">';
    html += '<p style="margin:0;font-size:16px;font-weight:600">No se puede enviar el link</p>';
    html += '<p style="margin:2px 0 0;font-size:13px;color:#7F1D1D">Faltan datos en ' + lista.length + ' entrega' + (lista.length === 1 ? '' : 's') + '. El cliente vería un link inválido.</p>';
    html += '</div>';
    html += '<button type="button" onclick="cerrarModalValidacion()" style="border:none;background:none;cursor:pointer;font-size:22px;color:#999"><i class="ti ti-x"></i></button>';
    html += '</div>';

    // Lista de entregas con campos faltantes
    html += '<div style="padding:18px 22px;max-height:55vh;overflow-y:auto">';
    lista.forEach(function(item) {
        html += '<div style="border:1px solid #FFCDD2;background:#FFF5F5;border-radius:10px;padding:12px 14px;margin-bottom:10px">';
        html += '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">';
        if (item.entrega_id > 0) {
            html += '<p style="margin:0;font-size:14px;font-weight:600;color:#B71C1C">Entrega ' + item.numero + ' &mdash; ' + escapeTexto(item.receptor) + '</p>';
            html += '<button type="button" onclick="irAEntrega(' + item.entrega_id + ')" style="font-size:12px;padding:5px 12px;background:#3B5BDB;color:white;border:none;border-radius:6px;cursor:pointer;font-weight:500"><i class="ti ti-edit" style="font-size:13px;vertical-align:-2px"></i> Completar</button>';
        } else {
            html += '<p style="margin:0;font-size:14px;font-weight:600;color:#B71C1C">Pre-pedido sin entregas</p>';
            html += '<button type="button" onclick="agregarEntrega()" style="font-size:12px;padding:5px 12px;background:#3B5BDB;color:white;border:none;border-radius:6px;cursor:pointer;font-weight:500"><i class="ti ti-plus" style="font-size:13px;vertical-align:-2px"></i> Crear entrega</button>';
        }
        html += '</div>';
        html += '<ul style="margin:0;padding-left:20px;font-size:13px;color:#7F1D1D;line-height:1.7">';
        item.faltantes.forEach(function(campo) {
            html += '<li>' + escapeTexto(campo) + '</li>';
        });
        html += '</ul>';
        html += '</div>';
    });
    html += '</div>';

    // Footer
    html += '<div style="padding:12px 22px;background:#FAFAFA;border-top:1px solid #f0f0f0;display:flex;justify-content:flex-end;gap:8px">';
    html += '<button type="button" onclick="cerrarModalValidacion()" style="padding:8px 18px;font-size:13px;background:white;color:#555;border:1px solid #d0d0d0;border-radius:6px;cursor:pointer;font-weight:500">Cerrar</button>';
    html += '</div>';

    html += '</div>';
    overlay.innerHTML = html;
    document.body.appendChild(overlay);

    // Cerrar al hacer click fuera del modal
    overlay.addEventListener('click', function(ev) {
        if (ev.target === overlay) cerrarModalValidacion();
    });
}

function cerrarModalValidacion() {
    var overlay = document.getElementById('modalValidacionLink');
    if (overlay && overlay.parentNode) overlay.parentNode.removeChild(overlay);
}

function irAEntrega(entregaId) {
    var ppId = document.getElementById('hdPrePedidoId').value;
    window.location.href = 'Entrega_Agregar.aspx?prepedido=' + ppId + '&entrega=' + entregaId;
}

function escapeTexto(s) {
    if (s === null || s === undefined) return '';
    var d = document.createElement('div');
    d.textContent = String(s);
    return d.innerHTML;
}

function agregarEntrega() {
    var id = document.getElementById('hdPrePedidoId').value;
    window.location.href = 'Entrega_Agregar.aspx?prepedido=' + id;
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

// ============================================================
// Menú "Acciones" desplegable en cada pedido confirmado
// ============================================================
function toggleMenuPedido(btnEl, ev) {
    if (ev) ev.stopPropagation();
    var menu = btnEl.parentNode.querySelector('.menu-dropdown-pedido');
    if (!menu) return;
    var abierto = (menu.style.display === 'block');
    // Cerrar todos primero
    cerrarMenusPedido();
    if (!abierto) {
        menu.style.display = 'block';
        // Rotar chevron
        var ic = btnEl.querySelector('i.ti-chevron-down, i.ti-chevron-up');
        if (ic) ic.classList.replace('ti-chevron-down', 'ti-chevron-up');
    }
}

function cerrarMenusPedido() {
    document.querySelectorAll('.menu-dropdown-pedido').forEach(function(m) {
        m.style.display = 'none';
    });
    document.querySelectorAll('.btn-acciones-menu i.ti-chevron-up').forEach(function(ic) {
        ic.classList.replace('ti-chevron-up', 'ti-chevron-down');
    });
}

// Cerrar al hacer click fuera
document.addEventListener('click', function(e) {
    if (!e.target.closest('.menu-wrap')) {
        cerrarMenusPedido();
    }
});

// ============================================================
// Sincronizar un pedido ya creado con WooCommerce
// Llama Entrega_Handler.ashx con accion=SINCRONIZAR_PEDIDO_WC
// Al recibir wc_order_id, transforma el botón en "Ver en WC"
// ============================================================
// ============================================================
// Sincronizar un pedido ya creado con WooCommerce
// Llama Entrega_Handler.ashx con accion=SINCRONIZAR_PEDIDO_WC
// Recarga la página para refrescar el menú con "Ver en WC"
// ============================================================
function sincronizarConWC(pedidoId, btn) {
    if (!confirm('¿Crear este pedido en WooCommerce?')) return;

    // Buscar el botón Acciones del menú padre
    var menuWrap = btn.closest('.menu-wrap');
    var btnAcciones = menuWrap ? menuWrap.querySelector('.btn-acciones-menu') : null;
    if (btnAcciones) {
        btnAcciones.disabled = true;
        btnAcciones.innerHTML = '<i class="ti ti-loader" style="font-size:13px"></i> Creando...';
    }

    var formData = new FormData();
    formData.append('accion', 'SINCRONIZAR_PEDIDO_WC');
    formData.append('pedido_id', pedidoId);

    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.ok && data.wc_order_id > 0) {
                // Recargar para mostrar el nuevo estado del menú
                location.reload();
            } else {
                alert('No se pudo crear en WooCommerce:\n' + (data.msg || 'Error desconocido'));
                if (btnAcciones) {
                    btnAcciones.disabled = false;
                    btnAcciones.innerHTML = 'Acciones <i class="ti ti-chevron-down" style="font-size:13px"></i>';
                }
            }
        })
        .catch(function() {
            alert('Error de conexión. Intente nuevamente.');
            if (btnAcciones) {
                btnAcciones.disabled = false;
                btnAcciones.innerHTML = 'Acciones <i class="ti ti-chevron-down" style="font-size:13px"></i>';
            }
        });
}

// ============================================================
// Edición inline del nombre del cliente
// ============================================================
function iniciarEdicionNombre() {
    document.getElementById('vistaNombre').style.display = 'none';
    document.getElementById('btnEditNombre').style.display = 'none';
    document.getElementById('errEditNombre').style.display = 'none';
    document.getElementById('editNombre').style.display = 'flex';
    var inp = document.getElementById('inpNombre');
    inp.focus(); inp.select();
}
function cancelarEdicionNombre() {
    document.getElementById('editNombre').style.display = 'none';
    document.getElementById('errEditNombre').style.display = 'none';
    document.getElementById('vistaNombre').style.display = '';
    document.getElementById('btnEditNombre').style.display = '';
}
function guardarNombreCliente() {
    var ppId = parseInt(document.getElementById('hdPrePedidoId').value) || 0;
    var nombre = document.getElementById('inpNombre').value.trim();
    var apellidos = document.getElementById('inpApellidos').value.trim();
    var errBox = document.getElementById('errEditNombre');
    errBox.style.display = 'none';
    if (!nombre) { errBox.textContent = 'El nombre es obligatorio'; errBox.style.display = 'block'; return; }
    var fd = new FormData();
    fd.append('accion', 'ACTUALIZAR_NOMBRE_CLIENTE');
    fd.append('prepedido_id', ppId);
    fd.append('nombre', nombre);
    fd.append('apellidos', apellidos);
    fetch('PrePedido_Detalle.aspx?id=' + ppId, {
        method: 'POST', headers: { 'X-Requested-With': 'XMLHttpRequest' }, body: fd
    })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) {
            document.getElementById('vistaNombre').textContent = data.nombre_completo;
            cancelarEdicionNombre();
        } else {
            errBox.textContent = data.msg || 'No se pudo guardar';
            errBox.style.display = 'block';
        }
    })
    .catch(function() { errBox.textContent = 'Error de conexión'; errBox.style.display = 'block'; });
}

// ============================================================
// Enviar cotización por WhatsApp
// ============================================================
function enviarCotizacion() {
    var ppId = parseInt(document.getElementById('hdPrePedidoId').value) || 0;
    var celular = document.getElementById('hdCelular').value || '';
    if (ppId <= 0) return;
    var fd = new FormData();
    fd.append('accion', 'GENERAR_COTIZACION');
    fd.append('prepedido_id', ppId);
    fetch('PrePedido_Detalle.aspx?id=' + ppId, {
        method: 'POST', headers: { 'X-Requested-With': 'XMLHttpRequest' }, body: fd
    })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (!data.ok) { alert(data.msg || 'No se pudo generar la cotización'); return; }
        var celLimpio = celular.replace(/[^0-9]/g, '');
        if (celLimpio.length === 8) celLimpio = '591' + celLimpio;
        var url = celLimpio
            ? 'whatsapp://send?phone=' + celLimpio + '&text=' + encodeURIComponent(data.mensaje)
            : 'whatsapp://send?text=' + encodeURIComponent(data.mensaje);
        window.location.href = url;
    })
    .catch(function() { alert('Error de conexión al generar cotización'); });
}
</script>
</asp:Content>
