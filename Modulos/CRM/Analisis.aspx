<%@ Page Language="VB" MasterPageFile="~/Site.Master"
         AutoEventWireup="false"
         CodeBehind="Analisis.aspx.vb"
         Inherits="SISCONBOL_FLORERIA.Modulos_CRM_Analisis" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Analisis de clientes
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-chart-bar" style="vertical-align:-2px"></i> Analisis de clientes
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .kpi-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px;margin-bottom:18px}
        .kpi{background:#fff;border:1px solid #eee;border-radius:10px;padding:14px}
        .kpi .lbl{font-size:12px;color:#888;margin-bottom:4px}
        .kpi .val{font-size:22px;font-weight:700;color:#333}
        .crm-table{width:100%;border-collapse:collapse;font-size:13px}
        .crm-table th{text-align:left;padding:8px 10px;background:#fafafa;border-bottom:2px solid #eee;font-weight:600;color:#555}
        .crm-table td{padding:8px 10px;border-bottom:1px solid #f0f0f0}
        .bar{height:8px;background:var(--rosa);border-radius:4px}
    </style>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">

    <div class="kpi-grid">
        <div class="kpi"><div class="lbl">Clientes</div><div class="val"><%=TotalClientes%></div></div>
        <div class="kpi"><div class="lbl">Recurrentes</div><div class="val"><%=Recurrentes%></div></div>
        <div class="kpi"><div class="lbl">Compraron 1 vez</div><div class="val"><%=Unicos%></div></div>
        <div class="kpi"><div class="lbl">Ingreso total (Bs)</div><div class="val"><%=IngresoTotal%></div></div>
        <div class="kpi"><div class="lbl">LTV promedio (Bs)</div><div class="val"><%=LtvPromedio%></div></div>
        <div class="kpi"><div class="lbl">Ticket promedio (Bs)</div><div class="val"><%=TicketPromedio%></div></div>
    </div>

    <div class="grid-2" style="gap:16px;align-items:start">
        <div class="panel">
            <div class="panel-head"><div class="panel-title"><i class="ti ti-users-group"></i> Segmentos RFM</div></div>
            <div class="panel-body"><%=SegmentosHtml%></div>
        </div>
        <div class="panel">
            <div class="panel-head"><div class="panel-title"><i class="ti ti-flower"></i> Top productos</div></div>
            <div class="panel-body" style="overflow-x:auto"><%=TopProductosHtml%></div>
        </div>
    </div>

    <div class="panel" style="margin-top:16px">
        <div class="panel-head"><div class="panel-title"><i class="ti ti-calendar"></i> Estacionalidad (ventas por mes)</div></div>
        <div class="panel-body" style="overflow-x:auto"><%=EstacionalidadHtml%></div>
    </div>

</asp:Content>

<asp:Content ID="Content5" ContentPlaceHolderID="ScriptsContent" runat="server"></asp:Content>
