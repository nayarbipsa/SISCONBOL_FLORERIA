<%@ Page Language="VB" MasterPageFile="~/Site.Master"
         AutoEventWireup="false"
         CodeBehind="Segmentos.aspx.vb"
         Inherits="SISCONBOL_FLORERIA.Modulos_CRM_Segmentos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Segmentos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-users-group" style="vertical-align:-2px"></i> Segmentos de clientes (RFM)
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .seg-cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:14px}
        .seg-card{background:#fff;border:1px solid #eee;border-left:5px solid #ccc;border-radius:10px;padding:16px}
        .seg-card h3{margin:0 0 6px 0;font-size:16px}
        .seg-card .cnt{font-size:28px;font-weight:700}
        .seg-card .val{color:#888;font-size:12px;margin-bottom:8px}
        .seg-card p{font-size:12px;color:#666;line-height:1.5;margin:0 0 10px 0}
    </style>
</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="MainContent" runat="server">
    <p style="color:#777;font-size:13px;margin-bottom:16px">
        Segmentacion automatica por modelo RFM (Recencia, Frecuencia, Monto). Se recalcula desde 'Extraer'.
    </p>
    <div class="seg-cards"><%=CardsHtml%></div>
</asp:Content>

<asp:Content ID="Content5" ContentPlaceHolderID="ScriptsContent" runat="server"></asp:Content>
