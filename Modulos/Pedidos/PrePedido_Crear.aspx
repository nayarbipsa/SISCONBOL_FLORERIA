<%@ Page Title="Crear Pre-Pedido" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="PrePedido_Crear.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_PrePedido_Crear" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
<script src="<%= ResolveUrl("~/Scripts/validaciones.js") %>" type="text/javascript"></script>
<style>
.pais-badge {
    display: none;
    padding: 8px 14px;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 600;
    margin-top: 10px;
    width: fit-content;
}
.pais-bolivia { background: #FFF9C4; color: #F57F17; border: 1px solid #F9A825; }
.pais-peru    { background: #FFEBEE; color: #C62828; border: 1px solid #EF9A9A; }
.pais-intl    { background: #E3F2FD; color: #1565C0; border: 1px solid #90CAF9; }

.form-crear { max-width: 720px; }

.form-crear .form-control {
    padding: 14px 16px;
    font-size: 16px;
    border-radius: 10px;
}

.form-crear .form-label {
    font-size: 15px;
    font-weight: 600;
    margin-bottom: 8px;
}

.form-crear .form-label.required::after {
    content: ' *';
    color: #C62828;
}

.form-crear .form-help {
    font-size: 13px;
    margin-top: 6px;
}

.form-crear .form-group {
    margin-bottom: 20px;
}

.form-crear select.form-control {
    padding: 14px 16px;
    font-size: 15px;
}

.form-input-icon { position: relative; }
.form-input-icon > i {
    position: absolute;
    left: 14px;
    top: 50%;
    transform: translateY(-50%);
    font-size: 20px;
    color: #9e9e9e;
    pointer-events: none;
}
.form-input-icon > .form-control { padding-left: 44px; }

.form-section {
    background: #fafafa;
    border: 1px solid #f0f0f0;
    border-radius: 10px;
    padding: 20px 24px;
    margin-bottom: 20px;
}

.form-section-title {
    font-size: 14px;
    font-weight: 700;
    color: #880E4F;
    text-transform: uppercase;
    letter-spacing: .5px;
    margin-bottom: 18px;
    display: flex;
    align-items: center;
    gap: 8px;
}
.form-section-title i { font-size: 18px; }

.form-row-2 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
}

.form-crear .btn-accion {
    padding: 14px 28px;
    font-size: 16px;
    font-weight: 600;
    border-radius: 10px;
    gap: 10px;
    min-width: 180px;
}
.form-crear .btn-accion i { font-size: 20px; }

.form-crear .btn-cancelar {
    padding: 14px 28px;
    font-size: 15px;
    font-weight: 500;
    border-radius: 10px;
    gap: 10px;
    min-width: 140px;
}

.form-acciones {
    display: flex;
    gap: 14px;
    align-items: center;
    padding-top: 8px;
}

@media (max-width: 600px) {
    .form-row-2 { grid-template-columns: 1fr; }
    .form-acciones { flex-direction: column; }
    .form-crear .btn-accion,
    .form-crear .btn-cancelar { width: 100%; justify-content: center; }
}
</style>
</asp:Content>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-shopping-cart-plus" style="vertical-align:-2px"></i> Crear Pre-Pedido
</asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="alerta" id="divAlerta"><%=MensajeAlerta%></div>

    <div class="panel form-crear">
        <div class="panel-head">
            <div class="panel-title">
                <i class="ti ti-file-plus"></i> Nuevo Pre-Pedido
            </div>
            <div class="panel-actions">
                <a href="PrePedidos.aspx" class="btn btn-sm">
                    <i class="ti ti-arrow-left"></i>
                    Volver
                </a>
            </div>
        </div>
        <div class="panel-body">

            <!-- Tipo de Registro -->
            <div class="form-section">
                <div class="form-section-title">
                    <i class="ti ti-clipboard-list"></i>
                    Tipo de registro
                </div>
                <div class="form-group">
                    <label class="form-label required">Tipo de registro</label>
                    <select id="selTipo" name="selTipo" class="form-control">
                        <option value="PRE_PEDIDO">Pre-Pedido (formulario web para el cliente)</option>
                        <option value="VENTA_TIENDA">Venta Tienda (registro directo)</option>
                        <option value="VENTA_ANTIGUA">Venta Antigua (migracion)</option>
                    </select>
                    <span class="form-help">
                        <i class="ti ti-info-circle" style="font-size:14px;vertical-align:-2px;"></i>
                        Pre-Pedido genera un link para que el cliente complete sus datos
                    </span>
                </div>
            </div>

            <!-- Datos del Cliente -->
            <div class="form-section">
                <div class="form-section-title">
                    <i class="ti ti-user"></i>
                    Datos del cliente pagador
                </div>

                <div class="form-row-2">
                    <div class="form-group">
                        <label class="form-label required">Celular</label>
                        <div class="form-input-icon">
                            <i class="ti ti-phone"></i>
                            <input type="text" id="txCelular" name="txCelular" class="form-control"
                                   placeholder="71234567  o  +591 71234567"
                                   maxlength="25" onkeyup="detectarPais()" value="<%=ValorCelular%>" />
                        </div>
                        <div id="indicadorPais" class="pais-badge"></div>
                        <span class="form-help">
                            <i class="ti ti-info-circle" style="font-size:14px;vertical-align:-2px;"></i>
                            Bolivia: 71234567 | Internacional: +codigo numero
                        </span>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Email</label>
                        <div class="form-input-icon">
                            <i class="ti ti-mail"></i>
                            <input type="email" id="txEmail" name="txEmail" class="form-control"
                                   placeholder="juan@email.com" value="<%=ValorEmail%>" />
                        </div>
                        <span class="form-help">Opcional - Se enviara confirmacion aqui</span>
                    </div>
                </div>

                <div class="form-row-2">
                    <div class="form-group">
                        <label class="form-label">Nombre</label>
                        <input type="text" id="txNombre" name="txNombre" class="form-control"
                               placeholder="Juan" value="<%=ValorNombre%>" />
                        <span class="form-help">Opcional - Puede completarse despues</span>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Apellidos</label>
                        <input type="text" id="txApellidos" name="txApellidos" class="form-control"
                               placeholder="Perez Garcia" value="<%=ValorApellidos%>" />
                        <span class="form-help">Opcional - Puede completarse despues</span>
                    </div>
                </div>
            </div>

            <!-- Hidden fields -->
            <input type="hidden" id="hdPaisId" name="hdPaisId" value="" />
            <input type="hidden" id="hdAccion" name="hdAccion" value="" />

            <!-- Botones -->
            <div class="form-acciones">
                <a href="PrePedidos.aspx" class="btn btn-cancelar">
                    <i class="ti ti-x"></i>
                    Cancelar
                </a>
                <button type="button" class="btn btn-primary btn-accion" onclick="enviarFormulario()">
                    <i class="ti ti-check"></i>
                    Crear Pre-Pedido
                </button>
            </div>

        </div>
    </div>

    <asp:Button ID="btnPostBack" runat="server" Style="display:none" OnClick="btnAccion_Click" />

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

window.addEventListener('DOMContentLoaded', function() {
    mostrarAlertaSiExiste();
    autoDetectarPaisInicial();
    registrarEnter();
});

function mostrarAlertaSiExiste() {
    var divAlerta = document.getElementById('divAlerta');
    if (divAlerta && divAlerta.textContent.trim() !== '') {
        var esMensajeExito = divAlerta.textContent.indexOf('creado correctamente') >= 0;
        divAlerta.className = 'alerta ' + (esMensajeExito ? 'alerta-success' : 'alerta-error') + ' show';
    }
}

function autoDetectarPaisInicial() {
    var txCel = document.getElementById('txCelular');
    if (txCel && txCel.value.trim()) {
        detectarPais();
    }
}

function detectarPais() {
    var input = document.getElementById('txCelular');
    var indicador = document.getElementById('indicadorPais');
    var hdPais = document.getElementById('hdPaisId');

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

    if (tel.match(/^\+?591\d{7,8}$/)) {
        paisId = '1';
        paisNombre = 'Bolivia (+591)';
        css += ' pais-bolivia';
    } else if (tel.match(/^[67]\d{6,7}$/)) {
        paisId = '1';
        paisNombre = 'Bolivia';
        css += ' pais-bolivia';
    } else if (tel.match(/^\+?51\d{9}$/)) {
        paisId = '2';
        paisNombre = 'Peru (+51)';
        css += ' pais-peru';
    } else if (tel.match(/^\+\d{1,4}\d{7,15}$/)) {
        paisId = '';
        paisNombre = 'Internacional';
        css += ' pais-intl';
    } else {
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
    var resultado = Validaciones.validarFormularioPrePedido();

    if (!resultado.valido) {
        Validaciones.marcarCampoInvalido(resultado.campo, resultado.mensaje);
        return;
    }

    var hdAcc = document.getElementById('hdAccion');
    if (hdAcc) hdAcc.value = 'CREAR';

    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}

function registrarEnter() {
    var form = document.querySelector('form');
    if (!form) return;
    form.addEventListener('keypress', function(event) {
        if (event.keyCode === 13 || event.which === 13) {
            var target = event.target;
            if (target && target.tagName === 'INPUT' && target.type !== 'submit') {
                event.preventDefault();
                enviarFormulario();
                return false;
            }
        }
    });
}
</script>
</asp:Content>
