<%@ Page Language="VB" MasterPageFile="~/Site.Master"
         AutoEventWireup="false"
         CodeBehind="Clientes.aspx.vb"
         Inherits="SISCONBOL_FLORERIA.Modulos_CRM_Clientes" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Clientes WooCommerce
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-users" style="vertical-align:-2px"></i> Base de clientes
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .crm-table{width:100%;border-collapse:collapse;font-size:13px}
        .crm-table th{text-align:left;padding:8px 10px;background:#fafafa;border-bottom:2px solid #eee;font-weight:600;color:#555;white-space:nowrap}
        .crm-table td{padding:8px 10px;border-bottom:1px solid #f0f0f0}
        .crm-table tr:hover{background:#fff5f8}
        .seg{display:inline-block;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:600}
        .seg-Campeon{background:#e8f5e9;color:#2e7d32}
        .seg-Leal{background:#e3f2fd;color:#1565c0}
        .seg-NuevoPotencial{background:#fff3e0;color:#e65100}
        .seg-Enriesgo{background:#fff8e1;color:#f9a825}
        .seg-Perdido{background:#ffebee;color:#c62828}
        .seg-Regular{background:#f5f5f5;color:#757575}
    </style>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">

    <div class="panel" style="margin-bottom:14px">
        <div class="panel-body" style="display:flex;gap:10px;flex-wrap:wrap;align-items:flex-end">
            <div class="form-group" style="flex:1;min-width:200px;margin:0">
                <label class="form-label">Buscar (nombre, email, telefono)</label>
                <input type="text" id="txBuscar" class="form-control" onkeyup="if(event.key==='Enter')cargar()" />
            </div>
            <div class="form-group" style="margin:0">
                <label class="form-label">Segmento</label>
                <select id="selSegmento" class="form-control" onchange="cargar()">
                    <option value="">Todos</option>
                    <option value="Campeon">Campeon</option>
                    <option value="Leal">Leal</option>
                    <option value="Nuevo/Potencial">Nuevo/Potencial</option>
                    <option value="En riesgo">En riesgo</option>
                    <option value="Perdido">Perdido</option>
                    <option value="Regular">Regular</option>
                </select>
            </div>
            <div class="form-group" style="margin:0">
                <label class="form-label">Ordenar por</label>
                <select id="selOrden" class="form-control" onchange="cargar()">
                    <option value="gasto">Mayor gasto</option>
                    <option value="frecuencia">Mas pedidos</option>
                    <option value="recencia">Compra mas reciente</option>
                    <option value="nombre">Nombre</option>
                </select>
            </div>
            <button type="button" class="btn btn-sm btn-primary" onclick="cargar()">
                <i class="ti ti-search"></i> Buscar
            </button>
        </div>
    </div>

    <div class="panel">
        <div class="panel-body">
            <div id="divTabla" style="overflow-x:auto">
                <p style="color:#999;text-align:center;padding:20px">Cargando...</p>
            </div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="Content5" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
    function cargar(){
        var b = encodeURIComponent(document.getElementById('txBuscar').value);
        var s = encodeURIComponent(document.getElementById('selSegmento').value);
        var o = encodeURIComponent(document.getElementById('selOrden').value);
        var cont = document.getElementById('divTabla');
        cont.innerHTML = '<p style="color:#999;text-align:center;padding:20px">Cargando...</p>';
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'Clientes_Handler.ashx?action=listar&b=' + b + '&seg=' + s + '&o=' + o, true);
        xhr.onload = function(){
            if (xhr.status === 200){ cont.innerHTML = xhr.responseText; }
            else { cont.innerHTML = '<p style="color:#c62828;text-align:center;padding:20px">Error ' + xhr.status + '</p>'; }
        };
        xhr.onerror = function(){ cont.innerHTML = '<p style="color:#c62828;text-align:center;padding:20px">Error de conexion</p>'; };
        xhr.send();
    }
    cargar();
</script>
</asp:Content>
