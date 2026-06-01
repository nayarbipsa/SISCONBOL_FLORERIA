<%@ Page Language="VB" MasterPageFile="~/Site.Master"
         AutoEventWireup="false"
         CodeBehind="Exportar.aspx.vb"
         Inherits="SISCONBOL_FLORERIA.Modulos_CRM_Exportar" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Exportar clientes
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-file-export" style="vertical-align:-2px"></i> Exportar clientes
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

    <div class="panel" style="max-width:560px">
        <div class="panel-body">
            <div class="form-group">
                <label class="form-label">Segmento</label>
                <select id="selSegmento" name="selSegmento" class="form-control">
                    <option value="">Todos los clientes</option>
                    <option value="Campeon">Campeon</option>
                    <option value="Leal">Leal</option>
                    <option value="Nuevo/Potencial">Nuevo/Potencial</option>
                    <option value="En riesgo">En riesgo</option>
                    <option value="Perdido">Perdido</option>
                    <option value="Regular">Regular</option>
                </select>
            </div>

            <div class="form-group" style="margin-top:12px">
                <label class="form-label">Formato</label>
                <select id="selFormato" name="selFormato" class="form-control">
                    <option value="GOOGLEADS">Google Ads Customer Match (email/telefono hasheados)</option>
                    <option value="GENERICO">CSV generico (todos los campos)</option>
                </select>
            </div>

            <p style="font-size:12px;color:#888;margin:12px 0">
                El formato Google Ads exporta email y telefono ya hasheados con SHA256 (listos para subir a tu audiencia de Customer Match).
                El generico incluye datos legibles para analisis en Excel.
            </p>

            <input type="hidden" id="hdExportar" name="hdExportar" value="" />
            <asp:Button ID="btnExportar" runat="server" CssClass="btn btn-sm btn-primary"
                        Text="Descargar CSV" OnClick="btnExportar_Click" />
        </div>
    </div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server"></asp:Content>
