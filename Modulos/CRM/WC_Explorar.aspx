<%@ Page Language="VB" MasterPageFile="~/Site.Master"
         AutoEventWireup="false"
         CodeBehind="WC_Explorar.aspx.vb"
         Inherits="SISCONBOL_FLORERIA.Modulos_CRM_WC_Explorar" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Explorar espejo WC
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-database-search" style="vertical-align:-2px"></i> Explorar datos crudos de WooCommerce
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .crm-table{width:100%;border-collapse:collapse;font-size:12px}
        .crm-table th{text-align:left;padding:7px 9px;background:#fafafa;border-bottom:2px solid #eee;font-weight:600;color:#555;white-space:nowrap}
        .crm-table td{padding:7px 9px;border-bottom:1px solid #f0f0f0;white-space:nowrap}
        .tabs{display:flex;gap:6px;margin-bottom:14px}
        .tab{padding:7px 14px;border-radius:8px;border:1px solid #e0e0e0;background:#fff;cursor:pointer;font-size:13px}
        .tab.active{background:var(--rosa);color:#fff;border-color:var(--rosa)}
        .json-box{font-family:monospace;font-size:11px;background:#0d1117;color:#c9d1d9;padding:10px;border-radius:8px;max-height:400px;overflow:auto;white-space:pre-wrap}
    </style>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">

    <div class="tabs">
        <div class="tab active" id="tabOrdenes" onclick="setTab('ordenes')">Ordenes</div>
        <div class="tab" id="tabProductos" onclick="setTab('productos')">Productos</div>
        <div class="tab" id="tabCategorias" onclick="setTab('categorias')">Categorias</div>
    </div>

    <div class="panel" style="margin-bottom:14px">
        <div class="panel-body" style="display:flex;gap:10px;align-items:flex-end">
            <div class="form-group" style="flex:1;margin:0">
                <label class="form-label">Buscar</label>
                <input type="text" id="txBuscar" class="form-control" onkeyup="if(event.key==='Enter')cargar()" />
            </div>
            <button type="button" class="btn btn-sm btn-primary" onclick="cargar()"><i class="ti ti-search"></i> Buscar</button>
        </div>
    </div>

    <div class="panel">
        <div class="panel-body">
            <div id="divTabla" style="overflow-x:auto"><p style="color:#999;text-align:center;padding:20px">Cargando...</p></div>
        </div>
    </div>

    <!-- Modal json -->
    <div id="modalJson" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:1000;padding:30px" onclick="cerrarJson(event)">
        <div style="max-width:800px;margin:0 auto;background:#fff;border-radius:12px;padding:18px" onclick="event.stopPropagation()">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
                <strong>json_raw</strong>
                <button type="button" class="btn btn-sm" onclick="document.getElementById('modalJson').style.display='none'">Cerrar</button>
            </div>
            <div id="jsonContenido" class="json-box"></div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="Content5" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
    var _tab = 'ordenes';
    function setTab(t){
        _tab = t;
        document.getElementById('tabOrdenes').className = 'tab' + (t==='ordenes'?' active':'');
        document.getElementById('tabProductos').className = 'tab' + (t==='productos'?' active':'');
        document.getElementById('tabCategorias').className = 'tab' + (t==='categorias'?' active':'');
        cargar();
    }
    function cargar(){
        var b = encodeURIComponent(document.getElementById('txBuscar').value);
        var cont = document.getElementById('divTabla');
        cont.innerHTML = '<p style="color:#999;text-align:center;padding:20px">Cargando...</p>';
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'WC_Explorar_Handler.ashx?action=listar&tipo=' + _tab + '&b=' + b, true);
        xhr.onload = function(){ cont.innerHTML = (xhr.status===200) ? xhr.responseText : '<p style="color:#c62828;text-align:center;padding:20px">Error ' + xhr.status + '</p>'; };
        xhr.onerror = function(){ cont.innerHTML = '<p style="color:#c62828;text-align:center;padding:20px">Error de conexion</p>'; };
        xhr.send();
    }
    function verJson(tipo, id){
        var xhr = new XMLHttpRequest();
        xhr.open('GET', 'WC_Explorar_Handler.ashx?action=json&tipo=' + tipo + '&id=' + id, true);
        xhr.onload = function(){
            document.getElementById('jsonContenido').textContent = xhr.responseText;
            document.getElementById('modalJson').style.display = 'block';
        };
        xhr.send();
    }
    function cerrarJson(e){ document.getElementById('modalJson').style.display='none'; }
    cargar();
</script>
</asp:Content>
