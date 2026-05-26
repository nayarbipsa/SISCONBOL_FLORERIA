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
                <button type="button" onclick="enviarLinkCliente()" class="btn btn-sm">
                    <i class="ti ti-brand-whatsapp" style="color:#25D366"></i> Reenviar WhatsApp
                </button>
            </div>

        <% Else %>
            <div style="background:#E8F5E9;padding:10px 12px;border-radius:6px;margin-bottom:10px;font-size:12px;color:#1B5E20">
                <p style="margin:0;font-weight:500"><i class="ti ti-check" style="font-size:14px;vertical-align:-2px"></i> Cliente confirmo el <%=TokenConfirmadoEn.ToString("dd/MM HH:mm")%></p>
                <p style="margin:4px 0 0;font-size:11px;color:#2E7D32">Revisa los datos abajo y confirma el pedido cuando estes listo</p>
            </div>
            <button type="button" onclick="copiarLink()" class="btn btn-sm">
                <i class="ti ti-copy"></i> Copiar link
            </button>
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
// Sincronizar un pedido ya creado con WooCommerce
// Llama Entrega_Handler.ashx con accion=SINCRONIZAR_PEDIDO_WC
// Al recibir wc_order_id, transforma el botón en "Ver en WC"
// ============================================================
function sincronizarConWC(pedidoId, btn) {
    if (!confirm('¿Crear este pedido en WooCommerce?')) return;

    // Estado de carga
    var textoOriginal = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = '<i class="ti ti-loader" style="font-size:13px;vertical-align:-2px"></i> Creando...';
    btn.style.opacity = '0.7';
    btn.style.cursor = 'wait';

    var formData = new FormData();
    formData.append('accion', 'SINCRONIZAR_PEDIDO_WC');
    formData.append('pedido_id', pedidoId);

    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.ok && data.wc_order_id > 0) {
                // Sustituir el botón por uno de "Ver en WC"
                var url = 'https://miss-flores.com/wp-admin/post.php?post=' + data.wc_order_id + '&action=edit';
                var nuevoLink = document.createElement('a');
                nuevoLink.href = url;
                nuevoLink.target = '_blank';
                nuevoLink.style.cssText = 'background:#F3E5F5;color:#6A1B9A;padding:4px 10px;border-radius:6px;font-size:11px;font-weight:500;text-decoration:none;display:inline-flex;align-items:center;gap:3px;border:1px solid #CE93D8';
                nuevoLink.innerHTML = '<i class="ti ti-brand-woocommerce" style="font-size:13px;vertical-align:-2px"></i> Ver en WC';
                btn.parentNode.replaceChild(nuevoLink, btn);
            } else {
                // Restaurar y mostrar error
                btn.disabled = false;
                btn.innerHTML = textoOriginal;
                btn.style.opacity = '1';
                btn.style.cursor = 'pointer';
                alert('No se pudo crear en WooCommerce:\n' + (data.msg || 'Error desconocido'));
            }
        })
        .catch(function() {
            btn.disabled = false;
            btn.innerHTML = textoOriginal;
            btn.style.opacity = '1';
            btn.style.cursor = 'pointer';
            alert('Error de conexión. Intente nuevamente.');
        });
}
</script>
</asp:Content>
