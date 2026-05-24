<%@ Page Title="Links Pre-Pedido" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="PrePedido_Links.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_PrePedido_Links" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
.success-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 12px;
    padding: 2rem;
    color: white;
    text-align: center;
    margin-bottom: 2rem;
}
.success-icon {
    font-size: 64px;
    margin-bottom: 1rem;
}
.success-title {
    font-size: 24px;
    font-weight: 500;
    margin-bottom: 0.5rem;
}
.link-section {
    background: white;
    border: 2px solid #667eea;
    border-radius: 12px;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
}
.link-title {
    font-size: 16px;
    font-weight: 500;
    margin-bottom: 1rem;
    color: #333;
}
.link-url {
    background: #f5f5f5;
    padding: 1rem;
    border-radius: 8px;
    font-family: monospace;
    font-size: 13px;
    word-break: break-all;
    margin-bottom: 1rem;
    border: 1px solid #e0e0e0;
}
.btn-whatsapp {
    background: #25D366;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 8px;
    font-size: 14px;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 8px;
}
.btn-whatsapp:hover {
    background: #1FA855;
}
</style>
</asp:Content>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-circle-check" style="vertical-align:-2px"></i> Pre-Pedido Creado
</asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

<div class="success-card">
    <div class="success-icon">
        <i class="ti ti-circle-check"></i>
    </div>
    <h2 class="success-title">Pre-Pedido <%=Codigo%> creado exitosamente</h2>
    <p>Cliente: <%=ClienteNombre%></p>
</div>

<!-- LINK CLIENTE -->
<div class="link-section">
    <h3 class="link-title">
        <i class="ti ti-link"></i>
        Link para el cliente (formulario web)
    </h3>
    <div class="link-url"><%=LinkCliente%></div>
    <button type="button" class="btn-whatsapp" onclick="enviarLinkCliente()">
        <i class="ti ti-brand-whatsapp"></i>
        Enviar por WhatsApp
    </button>
    <button type="button" class="btn btn-sm" onclick="copiarTexto('<%=LinkCliente%>')">
        <i class="ti ti-copy"></i>
        Copiar
    </button>
    <div style="margin-top: 0.75rem; font-size: 13px; color: #666;">
        <i class="ti ti-clock"></i>
        Valido hasta: <%=FechaExpiracion%>
    </div>
</div>

<!-- LINK INTERNO -->
<div class="link-section">
    <h3 class="link-title">
        <i class="ti ti-link"></i>
        Link interno (acceso rapido para ti)
    </h3>
    <div class="link-url"><%=LinkInterno%></div>
    <button type="button" class="btn-whatsapp" onclick="enviarLinkInterno()">
        <i class="ti ti-brand-whatsapp"></i>
        Enviarte a ti mismo
    </button>
    <button type="button" class="btn btn-sm" onclick="copiarTexto('<%=LinkInterno%>')">
        <i class="ti ti-copy"></i>
        Copiar
    </button>
    <div style="margin-top: 0.75rem; font-size: 13px; color: #666;">
        <i class="ti ti-info-circle"></i>
        Guardalo para retomar dias despues
    </div>
</div>

<!-- MENSAJE SUGERIDO -->
<div class="link-section">
    <h3 class="link-title">
        <i class="ti ti-message"></i>
        Mensaje sugerido para WhatsApp
    </h3>
    <div class="link-url" style="white-space: pre-wrap;"><%=MensajeSugerido%></div>
    <button type="button" class="btn-whatsapp" onclick="enviarMensajeCompleto()">
        <i class="ti ti-brand-whatsapp"></i>
        Enviar mensaje completo
    </button>
    <button type="button" class="btn btn-sm" onclick="copiarMensaje()">
        <i class="ti ti-copy"></i>
        Copiar mensaje
    </button>
</div>

<!-- ACCIONES -->
<div class="panel">
    <div class="panel-body">
        <div style="display: flex; gap: 10px; justify-content: center;">
            <a href="PrePedido_Detalle.aspx?id=<%=PrePedidoId%>" class="btn btn-primary">
                <i class="ti ti-eye"></i>
                Ver pre-pedido
            </a>
            <a href="PrePedido_Crear.aspx" class="btn">
                <i class="ti ti-plus"></i>
                Crear otro
            </a>
            <a href="PrePedidos.aspx" class="btn">
                <i class="ti ti-list"></i>
                Ver todos
            </a>
        </div>
    </div>
</div>

<!-- Hidden fields -->
<input type="hidden" id="hdCelular" value="<%=ClienteCelular%>" />
<input type="hidden" id="hdMensaje" value="<%=Server.HtmlEncode(MensajeSugerido)%>" />
<input type="hidden" id="hdPrePedidoId" value="<%=PrePedidoId%>" />

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

function copiarTexto(texto) {
    if (navigator.clipboard) {
        navigator.clipboard.writeText(texto).then(function() {
            alert('Copiado al portapapeles');
        });
    } else {
        var textarea = document.createElement('textarea');
        textarea.value = texto;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        alert('Copiado al portapapeles');
    }
}

function copiarMensaje() {
    var hdMensaje = document.getElementById('hdMensaje');
    if (hdMensaje) {
        var mensaje = hdMensaje.value;
        copiarTexto(mensaje);
    }
}

function enviarLinkCliente() {
    var celular = document.getElementById('hdCelular').value;
    var link = '<%=LinkCliente%>';
    
    var url = 'https://api.whatsapp.com/send?phone=' + celular + '&text=' + encodeURIComponent(link);
    window.open(url, '_blank');
}

function enviarLinkInterno() {
    var link = '<%=LinkInterno%>';
    var url = 'https://api.whatsapp.com/send?text=' + encodeURIComponent(link);
    window.open(url, '_blank');
}

function enviarMensajeCompleto() {
    var celular = document.getElementById('hdCelular').value;
    var hdMensaje = document.getElementById('hdMensaje');
    
    if (!hdMensaje) {
        alert('Error: No se pudo cargar el mensaje');
        return;
    }
    
    var mensaje = hdMensaje.value;
    var url = 'https://api.whatsapp.com/send?phone=' + celular + '&text=' + encodeURIComponent(mensaje);
    window.open(url, '_blank');
}
</script>
</asp:Content>
