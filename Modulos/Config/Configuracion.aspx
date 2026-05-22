<%@ Page Language="VB" MasterPageFile="~/Site.Master" 
         AutoEventWireup="false" 
         CodeBehind="Configuracion.aspx.vb" 
         Inherits="SISCONBOL_FLORERIA.Modulos_Config_Configuracion" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Configuración WooCommerce
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Configuración - WooCommerce
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">
    
    <!-- Alertas -->
    <div class="alerta" id="divAlerta"></div>

    <!-- Panel Configuración -->
    <div class="panel">
        <div class="panel-head">
            <div class="panel-title">Credenciales WooCommerce</div>
        </div>
        <div class="panel-body">
            <div class="alerta alerta-info" style="display:block;margin-bottom:16px">
                <i class="ti ti-info-circle"></i>
                Genera las claves en: WordPress Admin → WooCommerce → Ajustes → Avanzado → API REST
            </div>

            <div class="form-group" style="margin-bottom:14px">
                <label class="form-label">URL de tu tienda <span class="requerido">*</span></label>
                <input type="text" id="txWcUrl" name="txWcUrl" class="form-control" 
                       placeholder="https://miss-flores.com" maxlength="300"/>
                <div class="campo-error" id="errWcUrl" style="display:none;">
                    <i class="ti ti-alert-circle"></i> Ingrese la URL completa con https://
                </div>
                <small>Sin barra al final.</small>
            </div>

            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-bottom:14px">
                <div class="form-group">
                    <label class="form-label">Consumer Key <span class="requerido">*</span></label>
                    <div style="position:relative">
                        <input type="password" id="txConsumerKey" name="txConsumerKey" 
                               class="form-control" placeholder="ck_xxx" maxlength="200" 
                               style="padding-right:38px"/>
                        <button type="button" onclick="toggleVer('txConsumerKey','icoKey')"
                                style="position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:#9e9e9e;padding:2px">
                            <i class="ti ti-eye" id="icoKey"></i>
                        </button>
                    </div>
                    <div class="campo-error" id="errKey" style="display:none;">
                        <i class="ti ti-alert-circle"></i> Ingrese el Consumer Key
                    </div>
                </div>
                
                <div class="form-group">
                    <label class="form-label">Consumer Secret <span class="requerido">*</span></label>
                    <div style="position:relative">
                        <input type="password" id="txConsumerSecret" name="txConsumerSecret" 
                               class="form-control" placeholder="cs_xxx" maxlength="200"
                               style="padding-right:38px"/>
                        <button type="button" onclick="toggleVer('txConsumerSecret','icoSecret')"
                                style="position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:#9e9e9e;padding:2px">
                            <i class="ti ti-eye" id="icoSecret"></i>
                        </button>
                    </div>
                    <div class="campo-error" id="errSecret" style="display:none;">
                        <i class="ti ti-alert-circle"></i> Ingrese el Consumer Secret
                    </div>
                </div>
            </div>

            <div class="form-group" style="margin-bottom:14px">
                <label class="form-label">Clave secreta para Webhooks</label>
                <div style="position:relative">
                    <input type="password" id="txWebhookSecret" name="txWebhookSecret" 
                           class="form-control" placeholder="Min. 16 caracteres" maxlength="200"
                           style="padding-right:38px"/>
                    <button type="button" onclick="toggleVer('txWebhookSecret','icoWebhook')"
                            style="position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:#9e9e9e;padding:2px">
                        <i class="ti ti-eye" id="icoWebhook"></i>
                    </button>
                </div>
            </div>

            <div style="display:flex;gap:10px;margin-top:4px">
                <button type="button" class="btn" onclick="probarConexion()">
                    <i class="ti ti-plug"></i> Probar conexión
                </button>
                <button type="button" class="btn btn-primary" onclick="guardarConfig()">
                    <i class="ti ti-device-floppy"></i> Guardar credenciales
                </button>
            </div>
        </div>
    </div>

    <!-- Hidden fields -->
    <input type="hidden" id="hdAccion" name="hdAccion" value=""/>
    <input type="hidden" id="hdWcUrl" name="hdWcUrl" value=""/>
    <input type="hidden" id="hdConsumerKey" name="hdConsumerKey" value=""/>
    <input type="hidden" id="hdConsumerSecret" name="hdConsumerSecret" value=""/>
    <input type="hidden" id="hdWebhookSecret" name="hdWebhookSecret" value=""/>
    
    <asp:Button ID="btnPostBack" runat="server" Text="" 
                Style="display:none" OnClick="btnAccion_Click"/>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

// Cargar valores desde VB.NET
(function() {
    var elTxUrl     = /** @type {HTMLInputElement} */ (document.getElementById('txWcUrl'));
    var elTxKey     = /** @type {HTMLInputElement} */ (document.getElementById('txConsumerKey'));
    var elTxSecret  = /** @type {HTMLInputElement} */ (document.getElementById('txConsumerSecret'));
    var elTxWebhook = /** @type {HTMLInputElement} */ (document.getElementById('txWebhookSecret'));
    
    var url     = '<%=ValorConfig("WC_URL")%>';
    var key     = '<%=ValorConfig("WC_CONSUMER_KEY")%>';
    var secret  = '<%=ValorConfig("WC_CONSUMER_SECRET")%>';
    var webhook = '<%=ValorConfig("WC_WEBHOOK_SECRET")%>';
    
    if (elTxUrl && url !== '') {
        elTxUrl.value = url;
        marcarError('txWcUrl', 'errWcUrl', false);
    }
    if (elTxKey && key !== '') {
        elTxKey.value = key;
        marcarError('txConsumerKey', 'errKey', false);
    }
    if (elTxSecret && secret !== '') {
        elTxSecret.value = secret;
        marcarError('txConsumerSecret', 'errSecret', false);
    }
    if (elTxWebhook && webhook !== '') {
        elTxWebhook.value = webhook;
    }
})();

function toggleVer(/** @type {string} */ inputId, /** @type {string} */ iconId) {
    var inp = /** @type {HTMLInputElement} */ (document.getElementById(inputId));
    var icon = document.getElementById(iconId);
    if (!inp) return;
    
    if (inp.type === 'password') {
        inp.type = 'text';
        if (icon) icon.className = 'ti ti-eye-off';
    } else {
        inp.type = 'password';
        if (icon) icon.className = 'ti ti-eye';
    }
}

function limpiar(/** @type {string} */ v) {
    if (!v) return '';
    return v.replace(/[<>"';\\]/g, '').trim();
}

function setHd(/** @type {string} */ id, /** @type {string} */ val) {
    var el = /** @type {HTMLInputElement} */ (document.getElementById(id));
    if (el) el.value = val;
}

function guardarConfig() {
    var elTxUrl    = /** @type {HTMLInputElement} */ (document.getElementById('txWcUrl'));
    var elTxKey    = /** @type {HTMLInputElement} */ (document.getElementById('txConsumerKey'));
    var elTxSecret = /** @type {HTMLInputElement} */ (document.getElementById('txConsumerSecret'));
    var elTxWebhook = /** @type {HTMLInputElement} */ (document.getElementById('txWebhookSecret'));
    
    if (!elTxUrl || !elTxKey || !elTxSecret) return;
    
    var url    = limpiar(elTxUrl.value);
    var key    = limpiar(elTxKey.value);
    var secret = limpiar(elTxSecret.value);
    var valido = true;

    if (!url || url.indexOf('http') !== 0) {
        marcarError('txWcUrl', 'errWcUrl', true);
        valido = false;
    } else {
        marcarError('txWcUrl', 'errWcUrl', false);
    }

    if (!key) {
        marcarError('txConsumerKey', 'errKey', true);
        valido = false;
    } else {
        marcarError('txConsumerKey', 'errKey', false);
    }

    if (!secret) {
        marcarError('txConsumerSecret', 'errSecret', true);
        valido = false;
    } else {
        marcarError('txConsumerSecret', 'errSecret', false);
    }

    if (!valido) return;

    setHd('hdAccion', 'GUARDAR');
    setHd('hdWcUrl', url);
    setHd('hdConsumerKey', key);
    setHd('hdConsumerSecret', secret);
    setHd('hdWebhookSecret', elTxWebhook ? limpiar(elTxWebhook.value) : '');
    
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}

function probarConexion() {
    setHd('hdAccion', 'PROBAR');
    var btn = document.getElementById('<%= btnPostBack.ClientID %>');
    if (btn) btn.click();
}
</script>
</asp:Content>
