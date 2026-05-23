<%@ Page Title="Crear Pre-Pedido" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="PrePedido_Crear.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_PrePedido_Crear" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
<script src="<%= ResolveUrl("~/Scripts/validaciones.js") %>" type="text/javascript"></script>
<style>
.pais-badge {
    display: none;
    padding: 3px 10px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 600;
    margin-top: 5px;
    width: fit-content;
}
.pais-bolivia {
    background: #FFF9C4;
    color: #F57F17;
    border: 1px solid #F9A825;
}
.pais-peru {
    background: #FFEBEE;
    color: #C62828;
    border: 1px solid #EF9A9A;
}
.pais-intl {
    background: #E3F2FD;
    color: #1565C0;
    border: 1px solid #90CAF9;
}
</style>
</asp:Content>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-shopping-cart-plus" style="vertical-align:-2px"></i> Crear Pre-Pedido
</asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="alerta" id="divAlerta"><%=MensajeAlerta%></div>

    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-user"></i> Datos del Cliente
            </div>
        </div>
        <div class="panel-body">
            <div class="grid-2">

                <div class="form-group">
                    <label class="form-label form-label-required">Celular</label>
                    <input type="text" id="txCelular" name="txCelular" class="form-control"
                           placeholder="71234567 o +591 71234567"
                           maxlength="25" onkeyup="detectarPais()" value="<%=ValorCelular%>" />
                    <div id="indicadorPais" class="pais-badge"></div>
                    <div class="form-help">Bolivia: 71234567 | Peru: +51 987654321 | Internacional: +codigo numero</div>
                </div>

                <div class="form-group">
                    <label class="form-label form-label-required">Tipo de Registro</label>
                    <select id="selTipo" name="selTipo" class="form-control">
                        <option value="PRE_PEDIDO">Pre-Pedido (Link Web)</option>
                        <option value="VENTA_TIENDA">Venta Tienda</option>
                        <option value="VENTA_ANTIGUA">Venta Antigua</option>
                    </select>
                </div>

                <div class="form-group">
                    <label class="form-label">Nombre</label>
                    <input type="text" id="txNombre" name="txNombre" class="form-control" 
                           placeholder="Juan" value="<%=ValorNombre%>" />
                </div>

                <div class="form-group">
                    <label class="form-label">Apellidos</label>
                    <input type="text" id="txApellidos" name="txApellidos" class="form-control" 
                           placeholder="Perez Garcia" value="<%=ValorApellidos%>" />
                </div>

                <div class="form-group">
                    <label class="form-label">Email</label>
                    <input type="email" id="txEmail" name="txEmail" class="form-control" 
                           placeholder="juan@email.com" value="<%=ValorEmail%>" />
                </div>

            </div>

            <input type="hidden" id="hdPaisId" name="hdPaisId" value="" />
            <input type="hidden" id="hdAccion" name="hdAccion" value="" />

            <button type="button" class="btn btn-primary" onclick="enviarFormulario()">
                <i class="ti ti-plus"></i> Crear Pre-Pedido
            </button>
        </div>
    </div>

    <asp:Button ID="btnPostBack" runat="server" Style="display:none" OnClick="btnAccion_Click" />

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

(function() {
    // Mostrar alerta si hay mensaje
    var divAlerta = /** @type {HTMLElement} */ (document.getElementById('divAlerta'));
    if (divAlerta && divAlerta.textContent.trim() !== '') {
        var esMensajeExito = divAlerta.textContent.indexOf('creado correctamente') >= 0;
        divAlerta.className = 'alerta ' + (esMensajeExito ? 'alerta-success' : 'alerta-error') + ' show';
    }

    // Auto-detectar país en carga si hay valor
    var txCel = /** @type {HTMLInputElement} */ (document.getElementById('txCelular'));
    if (txCel && txCel.value.trim()) {
        detectarPais();
    }
})();

/**
 * @param {void}
 */
function detectarPais() {
    var input = /** @type {HTMLInputElement} */ (document.getElementById('txCelular'));
    var indicador = document.getElementById('indicadorPais');
    var hdPais = /** @type {HTMLInputElement} */ (document.getElementById('hdPaisId'));
    if (!input || !indicador || !hdPais) return;

    var tel = input.value.trim().replace(/[\s\-()]/g, '');
    if (!tel) { 
        indicador.style.display = 'none'; 
        hdPais.value = ''; 
        return; 
    }

    var paisId = '';
    var paisNombre = '';
    var css = 'pais-badge';

    // Bolivia: +591 o números que empiezan con 6/7 (7-8 dígitos)
    if (tel.match(/^\+?591\d{7,8}$/)) {
        paisId = '1'; 
        paisNombre = 'Bolivia (+591)'; 
        css += ' pais-bolivia';
    } else if (tel.match(/^[67]\d{6,7}$/)) {
        paisId = '1'; 
        paisNombre = 'Bolivia'; 
        css += ' pais-bolivia';
    } 
    // Peru: +51 seguido de 9 dígitos
    else if (tel.match(/^\+?51\d{9}$/)) {
        paisId = '2'; 
        paisNombre = 'Peru (+51)'; 
        css += ' pais-peru';
    } 
    // Internacional: + seguido de código país (1-4 dígitos) y número (7-15 dígitos)
    else if (tel.match(/^\+\d{1,4}\d{7,15}$/)) {
        paisId = ''; 
        paisNombre = 'Internacional'; 
        css += ' pais-intl';
    } 
    else {
        indicador.style.display = 'none'; 
        hdPais.value = ''; 
        return;
    }

    indicador.textContent = paisNombre;
    indicador.className = css;
    indicador.style.display = 'inline-block';
    hdPais.value = paisId;
}

function enviarFormulario() {
    // Validar con la clase Validaciones
    var resultado = Validaciones.validarFormularioPrePedido();
    
    if (!resultado.valido) {
        Validaciones.marcarCampoInvalido(resultado.campo, resultado.mensaje);
        return;
    }
    
    var hdAcc = /** @type {HTMLInputElement} */ (document.getElementById('hdAccion'));
    if (hdAcc) hdAcc.value = 'CREAR';
    
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}
</script>
</asp:Content>
