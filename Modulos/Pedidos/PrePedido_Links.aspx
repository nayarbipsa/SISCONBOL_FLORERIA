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
    <% If Request.QueryString("existia") = "1" Then %>
        <h2 class="success-title">Ya tienes un pre-pedido activo: <%=Codigo%></h2>
        <p style="font-size: 14px; opacity: 0.9;">Este cliente ya tiene un pre-pedido en proceso. Puedes enviar los links nuevamente o editarlo.</p>
    <% Else %>
        <h2 class="success-title">Pre-Pedido <%=Codigo%> creado exitosamente</h2>
        <p>Cliente: <%=ClienteNombre%></p>
    <% End If %>
</div>

<!-- PRIMER MENSAJE AL CLIENTE -->
<div class="link-section">
    <h3 class="link-title">
        <i class="ti ti-message"></i>
        Primer mensaje al cliente
    </h3>
    <div class="link-url" style="white-space: pre-wrap;"><%=MensajeSugerido%></div>
    <button type="button" class="btn-whatsapp" onclick="enviarLinkCliente()">
        <i class="ti ti-brand-whatsapp"></i>
        Enviar primer mensaje
    </button>
    <button type="button" class="btn btn-sm" onclick="copiarMensaje()">
        <i class="ti ti-copy"></i>
        Copiar mensaje
    </button>
    <div style="margin-top: 0.75rem; font-size: 13px; color: #666;">
        <i class="ti ti-clock"></i>
        Enviar apenas el cliente escriba para no perder el contacto
    </div>
</div>

<!-- LINK DEL FORMULARIO (ENVIAR DESPUÉS) -->
<div class="link-section">
    <h3 class="link-title">
        <i class="ti ti-link"></i>
        Link del formulario (enviar después)
    </h3>
    <div class="link-url"><%=LinkCliente%></div>
    <button type="button" class="btn-whatsapp" onclick="enviarLinkFormulario()">
        <i class="ti ti-brand-whatsapp"></i>
        Enviar link del formulario
    </button>
    <button type="button" class="btn btn-sm" onclick="copiarTexto('<%=LinkCliente%>')">
        <i class="ti ti-copy"></i>
        Copiar link
    </button>
    <div style="margin-top: 0.75rem; font-size: 13px; color: #666;">
        <i class="ti ti-info-circle"></i>
        Enviar después del primer mensaje para que el cliente complete sus datos
    </div>
</div>

<!-- LINK DE ACCESO DIRECTO -->
<div class="link-section">
    <h3 class="link-title">
        <i class="ti ti-eye"></i>
        Link de acceso directo
    </h3>
    <div class="link-url"><%=LinkInterno%></div>
    <button type="button" class="btn-whatsapp" onclick="enviarLinkInterno()">
        <i class="ti ti-brand-whatsapp"></i>
        Enviar link de acceso
    </button>
    <button type="button" class="btn btn-sm" onclick="copiarTexto('<%=LinkInterno%>')">
        <i class="ti ti-copy"></i>
        Copiar link
    </button>
    <div style="margin-top: 0.75rem; font-size: 13px; color: #666;">
        <i class="ti ti-info-circle"></i>
        Para que el cliente vea su pedido cuando quiera
    </div>
</div>

<!-- GUARDAR PARA EL AGENTE -->
<div class="link-section" style="background: #E8F5E9; border-color: #4CAF50;">
    <h3 class="link-title" style="color: #2E7D32;">
        <i class="ti ti-bookmark"></i>
        Guardar para ti (agente)
    </h3>
    <p style="font-size: 14px; color: #555; margin-bottom: 1rem;">
        Envíate el link a ti mismo para tener acceso rápido al pre-pedido desde tu WhatsApp.
    </p>
    <button type="button" class="btn-whatsapp" onclick="guardarParaMi()">
        <i class="ti ti-brand-whatsapp"></i>
        Enviarme el link
    </button>
    <button type="button" class="btn btn-sm" onclick="copiarTexto('<%=LinkInterno%>')">
        <i class="ti ti-copy"></i>
        Copiar link
    </button>
</div>

<!-- ACCIONES -->
<div class="panel">
    <div class="panel-body">
        <div style="display: flex; gap: 10px; justify-content: center;">
            <%-- ========================================== --%>
            <%-- BOTÓN QUE SÍ FUNCIONA (SERVER-SIDE)       --%>
            <%-- ========================================== --%>
            <asp:Button ID="btnVerDetalle" runat="server" 
                Text=" Ver pre-pedido" 
                CssClass="btn btn-primary" 
                OnClick="btnVerDetalle_Click" 
                UseSubmitBehavior="False" />
            
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
<input type="hidden" id="hdMensaje" value="<%=MensajeSugerido%>" />
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
    var hdMensaje = document.getElementById('hdMensaje');
    
    if (!hdMensaje) {
        alert('Error: No se pudo cargar el mensaje');
        return;
    }
    
    var mensaje = hdMensaje.value;
    var url = 'https://api.whatsapp.com/send?phone=' + celular + '&text=' + encodeURIComponent(mensaje);
    window.open(url, '_blank');
}

function enviarLinkFormulario() {
    var celular = document.getElementById('hdCelular').value;
    var link = '<%=LinkCliente%>';
    var mensaje = 'Ahora por favor, para poder completar su pedido, llene el formulario en este link:\n' + link;
    
    var url = 'https://api.whatsapp.com/send?phone=' + celular + '&text=' + encodeURIComponent(mensaje);
    window.open(url, '_blank');
}

function enviarLinkInterno() {
    var celular = document.getElementById('hdCelular').value;
    var link = '<%=LinkInterno%>';
    var url = 'https://api.whatsapp.com/send?phone=' + celular + '&text=' + encodeURIComponent(link);
    window.open(url, '_blank');
}

function guardarParaMi() {
    var link = '<%=LinkInterno%>';
    var codigo = '<%=Codigo%>';
    var mensaje = 'Pre-pedido ' + codigo + ' - Link de acceso:\n' + link;
    
    var url = 'https://api.whatsapp.com/send?text=' + encodeURIComponent(mensaje);
    window.open(url, '_blank');
}
</script>
</asp:Content>
