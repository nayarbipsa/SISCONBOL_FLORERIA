<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Productos.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_Productos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Productos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Productos
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

<div class="panel">
  <div class="panel-head">
    <div class="panel-title">Catálogo de productos</div>
    <button type="button" class="btn btn-primary" onclick="window.location.href='ProductoEditar.aspx'">
      <i class="ti ti-plus"></i> Nuevo producto
    </button>
  </div>
  <div class="panel-body">
    
    <div class="panel-filters">
      <div class="filter-group">
        <input type="text" id="txBuscar" class="form-control" placeholder="Buscar por nombre..." style="min-width:280px"/>
      </div>
      <div class="filter-group">
        <select id="ddEstado" class="form-control" style="min-width:160px">
          <option value="">Todos los estados</option>
          <option value="1">Activos</option>
          <option value="0">Inactivos</option>
        </select>
      </div>
      <div class="filter-group">
        <select id="ddSync" class="form-control" style="min-width:180px">
          <option value="">Todos (WC sync)</option>
          <option value="SINCRONIZADO">Sincronizado</option>
          <option value="PENDIENTE">Pendiente</option>
          <option value="ERROR">Error</option>
        </select>
      </div>
      <div class="filter-group">
        <button type="button" class="btn btn-secondary" onclick="buscarProductos()">
          <i class="ti ti-search"></i> Buscar
        </button>
      </div>
    </div>

    <div class="table-container">
      <table class="table">
        <thead>
          <tr>
            <th style="width:60px"></th>
            <th>Producto</th>
            <th style="width:120px">Precio</th>
            <th style="width:100px">Estado</th>
            <th style="width:140px">WooCommerce</th>
            <th style="width:80px;text-align:right">Acciones</th>
          </tr>
        </thead>
        <tbody id="tbodyProductos">
          <%=TablaHtml%>
        </tbody>
      </table>
    </div>

  </div>
</div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

function abrirFormEditar(id) {
    window.location.href = 'ProductoEditar.aspx?id=' + id;
}

function buscarProductos() {
    var buscar = document.getElementById('txBuscar');
    var estado = document.getElementById('ddEstado');
    var sync = document.getElementById('ddSync');
    
    if (!buscar || !estado || !sync) return;
    
    var url = 'Productos.aspx?';
    if (buscar.value) url += 'b=' + encodeURIComponent(buscar.value) + '&';
    if (estado.value) url += 'activo=' + estado.value + '&';
    if (sync.value) url += 'sync=' + sync.value + '&';
    
    window.location.href = url;
}

</script>
</asp:Content>
