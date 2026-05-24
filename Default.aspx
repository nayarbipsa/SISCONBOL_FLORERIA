<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Default.aspx.vb" Inherits="SISCONBOL_FLORERIA._Default" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Dashboard
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Dashboard
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div id="divAlerta" class="alerta"></div>

    <div class="bienvenida" id="spBienvenida">Bienvenido</div>
    <div class="bienvenida-sub" id="spFecha"></div>
    
    <div class="stats">
        <div class="stat">
            <div class="stat-icon"><i class="ti ti-package"></i></div>
            <div class="stat-lbl">Pre-Pedidos</div>
            <div class="stat-val" id="statPrePedidos"><%=TotalPrePedidos%></div>
            <div class="stat-sub" id="statPrePedidosHoy"><%=PrePedidosHoy%></div>
        </div>
        <div class="stat g">
            <div class="stat-icon"><i class="ti ti-coin"></i></div>
            <div class="stat-lbl">Ventas Hoy</div>
            <div class="stat-val" id="statVentasHoy"><%=VentasHoy%> Bs</div>
            <div class="stat-sub" id="statVentasInc"><%=VentasIncremento%></div>
        </div>
        <div class="stat b">
            <div class="stat-icon"><i class="ti ti-truck-delivery"></i></div>
            <div class="stat-lbl">Por Entregar</div>
            <div class="stat-val" id="statPorEntregar"><%=PorEntregar%></div>
            <div class="stat-sub">Para mañana</div>
        </div>
        <div class="stat a">
            <div class="stat-icon"><i class="ti ti-clock"></i></div>
            <div class="stat-lbl">Pendientes Pago</div>
            <div class="stat-val" id="statPendientesPago"><%=PendientesPago%></div>
            <div class="stat-sub" id="statPorVencer"><%=PorVencer%></div>
        </div>
    </div>

    <div class="panel" style="margin-top: 20px;">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-bolt"></i>
                Acciones rápidas
            </div>
        </div>
        <div class="panel-body">
            <div class="acciones-rapidas">
                <a href="Modulos/Pedidos/PrePedido_Crear.aspx" class="accion-card accion-primaria">
                    <i class="ti ti-plus"></i>
                    <div class="accion-content">
                        <div class="accion-titulo">Nuevo Pre-Pedido</div>
                        <div class="accion-sub">Crear formulario web</div>
                    </div>
                </a>

                <a href="Modulos/Pedidos/PrePedidos.aspx" class="accion-card">
                    <i class="ti ti-list"></i>
                    <div class="accion-content">
                        <div class="accion-titulo">Gestionar Pre-Pedidos</div>
                        <div class="accion-sub">Ver todos (<%=TotalPrePedidos%>)</div>
                    </div>
                </a>

                <a href="Modulos/Pedidos/PrePedido_Crear.aspx?tipo=VENTA_TIENDA" class="accion-card">
                    <i class="ti ti-shopping-cart"></i>
                    <div class="accion-content">
                        <div class="accion-titulo">Venta Tienda</div>
                        <div class="accion-sub">Registro directo</div>
                    </div>
                </a>

                <a href="javascript:void(0);" onclick="abrirBusqueda();" class="accion-card">
                    <i class="ti ti-search"></i>
                    <div class="accion-content">
                        <div class="accion-titulo">Buscar Pedido</div>
                        <div class="accion-sub">Por código/celular</div>
                    </div>
                </a>
            </div>
        </div>
    </div>

    <div class="panel" style="margin-top: 20px;">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-clock-hour-3"></i>
                Pre-Pedidos recientes
            </div>
            <div class="panel-actions">
                <a href="Modulos/Pedidos/PrePedidos.aspx" class="btn btn-sm">
                    Ver todos
                    <i class="ti ti-arrow-right"></i>
                </a>
            </div>
        </div>
        <div class="panel-body">
            <div id="divPrePedidosRecientes"></div>
        </div>
    </div>

    <div id="jsonPrePedidos" style="display:none;"><%=JsonPrePedidosRecientes%></div>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<style>
.stat-icon {
    font-size: 20px;
    margin-bottom: 6px;
    opacity: 0.8;
}

.stat-sub {
    font-size: 12px;
    margin-top: 4px;
    opacity: 0.7;
}

.acciones-rapidas {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 12px;
}

.accion-card {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 16px;
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    text-decoration: none;
    color: #424242;
    transition: all 0.15s;
}

.accion-card:hover {
    background: #FFF8FB;
    border-color: #C2185B;
    transform: translateY(-1px);
}

.accion-card i {
    font-size: 24px;
    color: #757575;
    flex-shrink: 0;
}

.accion-primaria {
    background: #FFF0F6;
    border-color: #C2185B;
}

.accion-primaria i {
    color: #C2185B;
}

.accion-primaria:hover {
    background: #FFE0ED;
}

.accion-content {
    flex: 1;
}

.accion-titulo {
    font-size: 14px;
    font-weight: 500;
    color: #424242;
    margin-bottom: 2px;
}

.accion-sub {
    font-size: 12px;
    color: #757575;
}

.prepedido-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px;
    border: 1px solid #f0f0f0;
    border-radius: 8px;
    margin-bottom: 8px;
    cursor: pointer;
    transition: background 0.15s;
}

.prepedido-item:hover {
    background: #FFF8FB;
}

.prepedido-codigo {
    font-family: monospace;
    font-size: 13px;
    font-weight: 500;
    color: #424242;
    flex-shrink: 0;
}

.prepedido-cliente {
    flex: 1;
    min-width: 0;
}

.prepedido-nombre {
    font-size: 14px;
    font-weight: 500;
    color: #424242;
}

.prepedido-celular {
    font-size: 12px;
    color: #757575;
}

.prepedido-estado {
    flex-shrink: 0;
}

.prepedido-monto {
    font-size: 14px;
    font-weight: 500;
    color: #424242;
    min-width: 80px;
    text-align: right;
    flex-shrink: 0;
}

.prepedido-item i.ti-chevron-right {
    font-size: 18px;
    color: #bdbdbd;
    flex-shrink: 0;
}

.badge-borrador { background: #F1EFE8; color: #444441; }
.badge-enviado { background: #E6F1FB; color: #0C447C; }
.badge-completado { background: #EAF3DE; color: #27500A; }
.badge-pagado { background: #EAF3DE; color: #27500A; }
.badge-cancelado { background: #FCEBEB; color: #791F1F; }
.badge-expirado { background: #FAEEDA; color: #633806; }

.empty-state {
    text-align: center;
    padding: 40px 20px;
    color: #9e9e9e;
}
</style>

<script type="text/javascript">
// @ts-nocheck
window.addEventListener('DOMContentLoaded', function() {
    cargarDatosUsuario();
    cargarPrePedidosRecientes();
});

function cargarDatosUsuario() {
    var nombres = '<%=Session("nombres")%>';
    var apellidos = '<%=Session("apellidos")%>';
    var elBien = document.getElementById('spBienvenida');
    var elFecha = document.getElementById('spFecha');
    
    if (elBien && nombres) {
        elBien.textContent = 'Bienvenido, ' + nombres + ' ' + apellidos;
    }
    
    if (elFecha) {
        var dias  = ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'];
        var meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
        var hoy   = new Date();
        elFecha.textContent = dias[hoy.getDay()] + ', ' + hoy.getDate() + ' de ' + meses[hoy.getMonth()] + ' de ' + hoy.getFullYear();
    }
}

function cargarPrePedidosRecientes() {
    var divJson = document.getElementById('jsonPrePedidos');
    var divLista = document.getElementById('divPrePedidosRecientes');
    
    if (!divJson || !divLista) return;
    
    var jsonText = divJson.textContent.trim();
    if (!jsonText) {
        divLista.innerHTML = '<div class="empty-state"><i class="ti ti-inbox" style="font-size:48px;display:block;margin-bottom:12px;opacity:0.3;"></i>No hay pre-pedidos recientes</div>';
        return;
    }
    
    var datos = JSON.parse(jsonText);
    
    if (!datos || datos.length === 0) {
        divLista.innerHTML = '<div class="empty-state"><i class="ti ti-inbox" style="font-size:48px;display:block;margin-bottom:12px;opacity:0.3;"></i>No hay pre-pedidos recientes</div>';
        return;
    }
    
    var html = '';
    for (var i = 0; i < datos.length; i++) {
        var item = datos[i];
        var badgeClass = obtenerClaseBadge(item.estado);
        var estadoTexto = obtenerTextoEstado(item.estado);
        
        html += '<div class="prepedido-item" onclick="verDetalle(' + item.prepedido_id + ')">';
        html += '  <div class="prepedido-codigo">' + item.codigo + '</div>';
        html += '  <div class="prepedido-cliente">';
        html += '    <div class="prepedido-nombre">' + (item.cliente_nombre || 'Sin nombre') + '</div>';
        html += '    <div class="prepedido-celular">' + item.cliente_celular + '</div>';
        html += '  </div>';
        html += '  <div class="prepedido-estado">';
        html += '    <span class="badge ' + badgeClass + '">' + estadoTexto + '</span>';
        html += '  </div>';
        html += '  <div class="prepedido-monto">' + formatearMonto(item.total_bs) + ' Bs</div>';
        html += '  <i class="ti ti-chevron-right"></i>';
        html += '</div>';
    }
    
    divLista.innerHTML = html;
}

function obtenerClaseBadge(estado) {
    var clases = {
        'BORRADOR': 'badge-borrador',
        'FORM_ENVIADO': 'badge-enviado',
        'FORM_COMPLETADO': 'badge-enviado',
        'COMPROBANTE_ENVIADO': 'badge-completado',
        'PAGADO': 'badge-pagado',
        'WC_CREADO': 'badge-completado',
        'COMPLETADO': 'badge-completado',
        'EXPIRADO': 'badge-expirado',
        'CANCELADO': 'badge-cancelado'
    };
    return clases[estado] || 'badge-borrador';
}

function obtenerTextoEstado(estado) {
    var textos = {
        'BORRADOR': 'Borrador',
        'FORM_ENVIADO': 'Form Enviado',
        'FORM_COMPLETADO': 'Form Completado',
        'COMPROBANTE_ENVIADO': 'Comprobante',
        'PAGADO': 'Pagado',
        'WC_CREADO': 'WC Creado',
        'COMPLETADO': 'Completado',
        'EXPIRADO': 'Expirado',
        'CANCELADO': 'Cancelado'
    };
    return textos[estado] || estado;
}

function formatearMonto(valor) {
    if (!valor) return '0.00';
    return parseFloat(valor).toFixed(2);
}

function verDetalle(id) {
    window.location.href = 'Modulos/Pedidos/PrePedido_Detalle.aspx?id=' + id;
}

function abrirBusqueda() {
    var codigo = prompt('Ingrese el código de pre-pedido o número de celular:');
    if (codigo && codigo.trim()) {
        window.location.href = 'Modulos/Pedidos/PrePedidos.aspx?buscar=' + encodeURIComponent(codigo.trim());
    }
}

function mostrarAlerta(msg, tipo) {
    var div = document.getElementById('divAlerta');
    if (div) {
        div.className = 'alerta show alerta-' + tipo;
        div.textContent = msg;
        setTimeout(function() {
            div.className = 'alerta';
        }, 5000);
    }
}
</script>
</asp:Content>
