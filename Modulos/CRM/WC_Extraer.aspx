<%@ Page Language="VB" MasterPageFile="~/Site.Master"
         AutoEventWireup="false"
         CodeBehind="WC_Extraer.aspx.vb"
         Inherits="SISCONBOL_FLORERIA.Modulos_CRM_WC_Extraer" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Extraer WooCommerce
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-cloud-download" style="vertical-align:-2px"></i> Extraer datos de WooCommerce
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .crm-log{font-family:monospace;font-size:11px;background:#0d1117;color:#c9d1d9;
                 padding:10px 12px;border-radius:8px;max-height:340px;overflow-y:auto;white-space:pre-wrap;line-height:1.5}
        .crm-note{background:#fff8e1;border-left:3px solid #ffa726;padding:10px 12px;border-radius:6px;
                  margin-bottom:14px;font-size:13px;line-height:1.5}
    </style>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">

    <div class="alerta" id="divAlerta"></div>

    <div class="crm-note">
        <strong><i class="ti ti-info-circle"></i> Espejo crudo de WooCommerce.</strong>
        Esto descarga ordenes, productos y categorias y las guarda en tablas propias (FLORERIA_WC_*),
        sin tocar los pedidos operativos. Para el historico completo, descarga las ordenes por tramos
        (por anio o por rango de fechas). Volver a correr un tramo actualiza, no duplica.
    </div>

    <!-- ORDENES -->
    <div class="panel" style="margin-bottom:16px">
        <div class="panel-head">
            <div class="panel-title"><i class="ti ti-shopping-cart"></i> Ordenes (por tramo)</div>
        </div>
        <div class="panel-body">
            <div class="grid-2" style="margin-bottom:12px">
                <div class="form-group">
                    <label class="form-label">Desde fecha</label>
                    <input type="date" name="txDesde" class="form-control" value="<%=Desde%>" />
                </div>
                <div class="form-group">
                    <label class="form-label">Hasta fecha</label>
                    <input type="date" name="txHasta" class="form-control" value="<%=Hasta%>" />
                </div>
            </div>
            <div class="form-group" style="margin-bottom:12px">
                <label class="form-label">Estado en WooCommerce</label>
                <select name="selStatus" class="form-control">
                    <option value="any">Todos los estados (recomendado)</option>
                    <option value="completed">completed</option>
                    <option value="processing">processing</option>
                    <option value="on-hold">on-hold</option>
                    <option value="pending">pending</option>
                    <option value="cancelled">cancelled</option>
                    <option value="refunded">refunded</option>
                    <option value="failed">failed</option>
                </select>
            </div>
            <button type="button" class="btn btn-sm btn-primary" onclick="ejecutar('ORDENES')">
                <i class="ti ti-cloud-download"></i> Descargar ordenes del tramo
            </button>
        </div>
    </div>

    <!-- PRODUCTOS Y CATEGORIAS -->
    <div class="panel" style="margin-bottom:16px">
        <div class="panel-head">
            <div class="panel-title"><i class="ti ti-flower"></i> Catalogo</div>
        </div>
        <div class="panel-body" style="display:flex;gap:8px;flex-wrap:wrap">
            <button type="button" class="btn btn-sm btn-primary" onclick="ejecutar('PRODUCTOS')">
                <i class="ti ti-cloud-download"></i> Descargar productos
            </button>
            <button type="button" class="btn btn-sm btn-primary" onclick="ejecutar('CATEGORIAS')">
                <i class="ti ti-cloud-download"></i> Descargar categorias
            </button>
        </div>
    </div>

    <!-- RECALCULAR ANALISIS -->
    <div class="panel" style="margin-bottom:16px;border:2px solid var(--rosa);border-radius:12px">
        <div class="panel-head" style="background:linear-gradient(135deg,#fce4ec,#fff)">
            <div class="panel-title"><i class="ti ti-calculator"></i> Recalcular analisis de clientes (RFM)</div>
        </div>
        <div class="panel-body">
            <p style="font-size:13px;color:#757575;margin:0 0 12px 0">
                Reconstruye la base de clientes deduplicada y los puntajes RFM a partir de las ordenes descargadas.
                Ejecutalo despues de cada descarga de ordenes.
            </p>
            <button type="button" class="btn btn-sm" onclick="ejecutar('RECALCULAR')">
                <i class="ti ti-refresh"></i> Recalcular clientes
            </button>
        </div>
    </div>

    <!-- RESULTADO -->
    <div class="panel" style="<%=ResultadoDisplay%>">
        <div class="panel-head">
            <div class="panel-title"><i class="ti ti-terminal"></i> Resultado de la ultima accion</div>
        </div>
        <div class="panel-body">
            <div class="grid-4" style="margin-bottom:12px">
                <div class="stat"><div class="stat-lbl">Total</div><div class="stat-val"><%=RTotal%></div></div>
                <div class="stat g"><div class="stat-lbl">Nuevos</div><div class="stat-val"><%=RNuevos%></div></div>
                <div class="stat b"><div class="stat-lbl">Actualizados</div><div class="stat-val"><%=RActualizados%></div></div>
                <div class="stat r"><div class="stat-lbl">Errores</div><div class="stat-val"><%=RErrores%></div></div>
            </div>
            <div class="crm-log"><%=RLog%></div>
        </div>
    </div>

    <input type="hidden" id="hdAccion" name="hdAccion" value="" />
    <asp:Button ID="btnPostBack" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click" />

</asp:Content>

<asp:Content ID="Content5" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
    function ejecutar(accion){
        if (accion === 'ORDENES'){
            mostrar('Descargando ordenes... puede tardar segun el tramo.');
        } else if (accion === 'RECALCULAR'){
            mostrar('Recalculando clientes...');
        } else {
            mostrar('Descargando ' + accion.toLowerCase() + '...');
        }
        document.getElementById('hdAccion').value = accion;
        document.getElementById('<%= btnPostBack.ClientID %>').click();
    }
    function mostrar(msg){
        var d = document.getElementById('divAlerta');
        if(!d) return;
        d.className = 'alerta show alerta-info';
        d.textContent = msg;
    }
</script>
</asp:Content>
