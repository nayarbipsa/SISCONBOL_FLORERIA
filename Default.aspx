<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Default.aspx.vb" Inherits="SISCONBOL_FLORERIA._Default" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Inicio
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Inicio
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    <div class="bienvenida" id="spBienvenida">Bienvenido</div>
    <div class="bienvenida-sub" id="spFecha"></div>
    
    <div class="stats">
        <div class="stat">
            <div class="stat-lbl">Pedidos hoy</div>
            <div class="stat-val">-</div>
        </div>
        <div class="stat g">
            <div class="stat-lbl">Ventas hoy</div>
            <div class="stat-val">-</div>
        </div>
        <div class="stat b">
            <div class="stat-lbl">Pre-pedidos</div>
            <div class="stat-val">-</div>
        </div>
        <div class="stat a">
            <div class="stat-lbl">Pagos pendientes</div>
            <div class="stat-val">-</div>
        </div>
    </div>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck
(function () {
    var nombres = '<%= If(Session("usuario_nombre") IsNot Nothing, Session("usuario_nombre").ToString(), "") %>';
    var elBien = document.getElementById('spBienvenida');
    var elFecha = document.getElementById('spFecha');
    
    if (elBien && nombres) {
        elBien.textContent = 'Bienvenido, ' + nombres + '.';
    }
    
    if (elFecha) {
        var dias  = ['Domingo','Lunes','Martes','Miércoles','Jueves','Viernes','Sábado'];
        var meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
        var hoy   = new Date();
        elFecha.textContent = dias[hoy.getDay()] + ' ' + hoy.getDate() + ' de ' + meses[hoy.getMonth()] + ' de ' + hoy.getFullYear();
    }
})();
</script>
</asp:Content>
