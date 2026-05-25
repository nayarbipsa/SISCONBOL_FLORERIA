<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="index.aspx.vb" Inherits="SISCONBOL_FLORERIA.Cliente_Index" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>Miss Flores - Confirma tu pedido</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">
<style>
*{box-sizing:border-box;margin:0;padding:0}
html,body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#FAFAFA;color:#212121;-webkit-text-size-adjust:100%}
.wrap{max-width:480px;margin:0 auto;background:#fff;min-height:100vh}
.hdr{background:#FCE4EC;padding:14px 16px;display:flex;align-items:center;gap:10px;border-bottom:1px solid #f0f0f0}
.hdr i{font-size:22px;color:#C2185B}
.hdr h1{font-size:15px;font-weight:600;color:#880E4F;margin:0}
.hdr p{font-size:11px;color:#AD1457;margin:0}
.banner{padding:10px 16px;background:#FFF8E1;border-bottom:1px solid #f0f0f0;display:flex;align-items:center;gap:8px;font-size:11px;color:#F57F17;font-weight:500}
.banner i{font-size:14px}
.body{padding:16px}
.section-lbl{margin:12px 0 8px;font-size:11px;color:#999;font-weight:600;letter-spacing:0.5px}
.section-lbl:first-child{margin-top:0}
.inp-lbl{display:block;font-size:11px;color:#666;margin:8px 0 3px}
.inp{width:100%;padding:9px 11px;font-size:13px;border:1px solid #d0d0d0;border-radius:6px;font-family:inherit;background:#fff}
.inp:focus{outline:none;border-color:#C2185B}
.inp.readonly{background:#f5f5f5;color:#666;cursor:not-allowed}
.inp-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px}
textarea.inp{resize:vertical;min-height:60px;font-family:inherit}
select.inp{appearance:none;-webkit-appearance:none;background-image:url("data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2216%22%20height%3D%2216%22%20fill%3D%22%23666%22%3E%3Cpath%20d%3D%22M4%206l4%204%204-4%22%20stroke%3D%22%23666%22%20fill%3D%22none%22%2F%3E%3C%2Fsvg%3E");background-repeat:no-repeat;background-position:right 10px center;padding-right:30px}

.entrega-card{background:#fff;border:1px solid #d0d0d0;border-radius:8px;margin-bottom:10px;overflow:hidden}
.entrega-card.faltan{border-color:#E53935;background:#FFEBEE}
.entrega-card.activa{border-color:#90CAF9}
.entrega-header{padding:12px;display:flex;align-items:center;gap:8px;cursor:pointer;background:#fff;user-select:none}
.entrega-resumen{flex:1;min-width:0}
.entrega-titulo{margin:0;font-size:13px;font-weight:600;color:#212121;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.entrega-sub{margin:2px 0 0;font-size:11px;color:#666}
.entrega-badge{background:#FFF3CD;color:#856404;font-size:10px;padding:3px 9px;border-radius:12px;font-weight:600;flex-shrink:0}
.entrega-badge.editando{background:#E3F2FD;color:#1565C0}
.entrega-badge.completa{background:#E8F5E9;color:#2E7D32}
.entrega-badge.faltan{background:#FFEBEE;color:#C62828}
.chev{font-size:18px;color:#999;transition:transform .2s}
.chev.up{transform:rotate(180deg)}
.entrega-body{padding:0 12px 12px;border-top:1px solid #f0f0f0;background:#fff}

.resumen-box{background:#F5F5F5;border-radius:6px;padding:10px;margin:12px 0}
.res-line{display:flex;justify-content:space-between;padding:2px 0;font-size:12px}
.res-line.muted{color:#666;margin-top:5px;border-top:1px solid #ddd;padding-top:5px}
.res-line.muted:first-of-type{border-top:0;margin-top:0;padding-top:0}
.res-line.warn{color:#E65100}
.res-line.warn i,.res-line.ok i{font-size:12px;vertical-align:-1px;margin-right:2px}
.res-line.ok{color:#2E7D32}
.res-line.total{font-size:14px;font-weight:600;border-top:1px dashed #aaa;margin-top:5px;padding-top:5px}
.res-line.total span:last-child{color:#C2185B}

.pago-box{background:#F3E5F5;padding:14px;border-radius:8px;margin:10px 0;text-align:center}
.pago-box p{margin:0 0 8px;font-size:12px;color:#7B1FA2}
.pago-box img{max-width:240px;width:100%;height:auto;background:#fff;padding:8px;border-radius:6px;display:block;margin:0 auto 8px}
.pago-info{background:#fff;padding:10px;border-radius:6px;font-size:11px;color:#4A148C}
.pago-info .row{display:flex;justify-content:space-between;padding:2px 0}
.paypal-btn{display:inline-block;background:#0070BA;color:#fff;padding:10px 22px;border-radius:6px;font-size:13px;font-weight:500;text-decoration:none;margin-top:6px}
.aviso{background:#FFF3E0;padding:10px 12px;border-radius:6px;margin:10px 0;border-left:3px solid #FB8C00;font-size:11px;color:#BF360C;line-height:1.5}
.aviso strong{color:#E65100}

.wsp-btn{display:flex;align-items:center;justify-content:center;width:100%;padding:11px;font-size:13px;font-weight:500;background:#25D366;color:#fff;border-radius:8px;text-decoration:none;border:none;gap:6px;cursor:pointer}
.wsp-btn:active{opacity:0.85}
.wsp-hint{margin:6px 0 18px;font-size:10px;color:#999;text-align:center}

.confirm-btn{width:100%;padding:14px;font-size:14px;font-weight:600;background:#C2185B;color:#fff;border:none;border-radius:8px;margin-bottom:8px;cursor:pointer}
.confirm-btn:active{background:#AD1457}
.confirm-hint{margin:0;font-size:10px;color:#999;text-align:center;line-height:1.5}

.guard-flash{position:fixed;bottom:14px;left:50%;transform:translateX(-50%);background:#2E7D32;color:#fff;padding:8px 16px;border-radius:20px;font-size:12px;font-weight:500;opacity:0;transition:opacity .3s;pointer-events:none;z-index:1000}
.guard-flash.show{opacity:1}

.estado-pantalla{padding:40px 24px;text-align:center}
.estado-pantalla i{font-size:60px;display:block;margin:0 auto 14px}
.estado-pantalla h2{font-size:18px;font-weight:600;margin:0 0 8px}
.estado-pantalla p{font-size:13px;color:#666;line-height:1.5;margin:0 0 14px}
</style>
</head>
<body>
<div class="wrap">

<% If Estado = "INVALIDO" Then %>
    <div class="hdr">
        <i class="ti ti-flower"></i>
        <div><h1>Miss Flores</h1><p>Link no valido</p></div>
    </div>
    <div class="estado-pantalla">
        <i class="ti ti-link-off" style="color:#C62828"></i>
        <h2>Link no valido</h2>
        <p>Este enlace no existe o ha sido cancelado.<br>Comunicate con Miss Flores para obtener uno nuevo.</p>
    </div>

<% ElseIf Estado = "EXPIRADO" Then %>
    <div class="hdr">
        <i class="ti ti-flower"></i>
        <div><h1>Miss Flores</h1><p>Link expirado</p></div>
    </div>
    <div class="estado-pantalla">
        <i class="ti ti-clock-off" style="color:#F57F17"></i>
        <h2>Link expirado</h2>
        <p>Este enlace ya no se puede usar.<br>Comunicate con <strong><%=NombreAgente%></strong> para que te envien uno nuevo.</p>
        <% If CelularAgenteLimpio <> "" Then %>
            <a href="https://wa.me/<%=CelularAgenteLimpio%>" target="_blank" class="wsp-btn" style="max-width:240px;margin:0 auto;display:inline-flex">
                <i class="ti ti-brand-whatsapp" style="font-size:16px"></i> Contactar a Miss Flores
            </a>
        <% End If %>
    </div>

<% ElseIf Estado = "CONFIRMADO" Then %>
    <div class="hdr">
        <i class="ti ti-flower"></i>
        <div><h1>Miss Flores</h1><p>Pedido confirmado</p></div>
    </div>
    <div class="estado-pantalla">
        <i class="ti ti-check" style="color:#2E7D32"></i>
        <h2>Listo, recibimos tu confirmacion</h2>
        <p>Estamos preparando tu pedido <strong><%=Codigo%></strong>.<br>Miss Flores validara el pago antes de la entrega.</p>
        <% If CelularAgenteLimpio <> "" Then %>
            <p style="font-size:11px;margin-top:8px">Cualquier consulta:</p>
            <a href="https://wa.me/<%=CelularAgenteLimpio%>" target="_blank" class="wsp-btn" style="max-width:240px;margin:0 auto;display:inline-flex">
                <i class="ti ti-brand-whatsapp" style="font-size:16px"></i> Contactar a <%=NombreAgente%>
            </a>
        <% End If %>
    </div>

<% Else %>
    <!-- ============== OK: MOSTRAR FORMULARIO ============== -->
    <div class="hdr">
        <i class="ti ti-flower"></i>
        <div><h1>Miss Flores</h1><p>Confirma tu pedido <%=Codigo%></p></div>
    </div>
    <div class="banner">
        <i class="ti ti-clock"></i>
        <span>Link expira en <%=HorasRestantes%>h <%=MinutosRestantes%>min</span>
    </div>

    <div class="body">

        <p class="section-lbl">TUS DATOS</p>
        <label class="inp-lbl">Tu nombre *</label>
        <input type="text" id="txClienteNombre" class="inp" value="<%=Server.HtmlEncode(ClienteNombre)%>" onblur="guardarCampoCliente('cliente_nombre', this.value)" required>
        <label class="inp-lbl">Tus apellidos</label>
        <input type="text" id="txClienteApellidos" class="inp" value="<%=Server.HtmlEncode(ClienteApellidos)%>" onblur="guardarCampoCliente('cliente_apellidos', this.value)">
        <label class="inp-lbl">Tu email *</label>
        <input type="email" id="txClienteEmail" class="inp" value="<%=Server.HtmlEncode(ClienteEmail)%>" onblur="guardarCampoCliente('cliente_email', this.value)" required>
        <label class="inp-lbl">Tu celular</label>
        <input type="text" class="inp readonly" value="<%=Server.HtmlEncode(ClienteCelular)%>" readonly>

        <p class="section-lbl">TUS ENTREGAS &middot; <%=CantidadEntregas%></p>
        <%=HtmlEntregas%>

        <p class="section-lbl">METODO DE PAGO &middot; Total: <span style="color:#C2185B;font-weight:600">Bs <%=TotalGeneralBs.ToString("N2")%></span></p>
        <select id="ddMetodoPago" class="inp" onchange="cambiarMetodoPago()">
            <option value="">-- Como pagas? --</option>
            <option value="QR">QR Bolivia (BNB)</option>
            <option value="TRANSFERENCIA">Transferencia bancaria</option>
            <option value="EFECTIVO">Efectivo (al recibir)</option>
            <option value="PAYPAL">PayPal</option>
            <option value="TARJETA">Tarjeta</option>
        </select>

        <!-- Bloques dinámicos por método -->
        <div id="boxQR" class="pago-box" style="display:none">
            <p><strong>Paso 1:</strong> Escanea con tu banco</p>
            <img src="https://miss-flores.com/wp-content/uploads/2026/05/QR_FLORERIA_2026.jpeg" alt="QR Miss Flores" onerror="this.style.display='none'">
            <div class="pago-info">
                <div class="row"><span>Titular</span><strong>Miss Flores</strong></div>
                <div class="row"><span>Monto</span><strong>Bs <%=TotalGeneralBs.ToString("N2")%></strong></div>
            </div>
        </div>

        <div id="boxTransfer" class="pago-box" style="display:none">
            <p style="text-align:left"><strong>Datos bancarios:</strong></p>
            <div class="pago-info" style="text-align:left">
                <div class="row"><span>Banco</span><strong>BNB</strong></div>
                <div class="row"><span>Titular</span><strong>Miss Flores</strong></div>
                <div class="row"><span>Monto</span><strong>Bs <%=TotalGeneralBs.ToString("N2")%></strong></div>
            </div>
        </div>

        <div id="boxPaypal" class="pago-box" style="display:none">
            <p>Paga desde tu cuenta PayPal</p>
            <a href="https://paypal.me/FloreriaMissFlores" target="_blank" class="paypal-btn">
                <i class="ti ti-brand-paypal" style="font-size:14px;vertical-align:-2px;margin-right:4px"></i> paypal.me/FloreriaMissFlores
            </a>
        </div>

        <div id="boxEfectivo" class="pago-box" style="display:none;background:#FFF8E1">
            <p style="color:#E65100"><i class="ti ti-cash"></i> Pagaras en efectivo al momento de recibir la entrega.</p>
        </div>

        <div id="boxTarjeta" class="pago-box" style="display:none">
            <p><i class="ti ti-credit-card"></i> Miss Flores te contactara por WhatsApp para procesar tu tarjeta.</p>
        </div>

        <div id="avisoComprobante" class="aviso" style="display:none">
            <p style="margin:0 0 4px"><strong><i class="ti ti-camera" style="font-size:13px;vertical-align:-2px"></i> Paso 2:</strong> Una vez realizado el pago, envia la captura del comprobante por WhatsApp para validar tu pedido.</p>
        </div>

        <% If CelularAgenteLimpio <> "" Then %>
            <a id="btnWsp" href="https://wa.me/<%=CelularAgenteLimpio%>" target="_blank" class="wsp-btn" style="display:none;text-decoration:none">
                <i class="ti ti-brand-whatsapp" style="font-size:16px"></i> Enviar comprobante por WhatsApp
            </a>
            <p id="wspHint" class="wsp-hint" style="display:none">Se abrira WhatsApp del agente: <%=NombreAgente%></p>
        <% End If %>

        <button type="button" class="confirm-btn" onclick="confirmarPedido()">
            <i class="ti ti-check" style="font-size:16px;vertical-align:-2px"></i> Confirmar mi pedido
        </button>
        <p class="confirm-hint">
            Al confirmar, Miss Flores recibira tus datos.<br>El pago sera validado antes de la entrega.
        </p>
    </div>

    <div class="guard-flash" id="guardFlash">Guardado</div>

<% End If %>

</div>

<input type="hidden" id="hdToken" value="<%=Token%>">
<input type="hidden" id="hdMetodoActual" value="<%=MetodoPagoCliente%>">

<script type="text/javascript">
// @ts-nocheck
(function(){
    var token = document.getElementById('hdToken').value;

    // ============================================================
    // Helpers comunes
    // ============================================================
    function flash(txt, ok) {
        var f = document.getElementById('guardFlash');
        if (!f) return;
        f.textContent = txt || 'Guardado';
        f.style.background = ok === false ? '#C62828' : '#2E7D32';
        f.classList.add('show');
        setTimeout(function(){ f.classList.remove('show'); }, 1200);
    }

    function postHandler(form) {
        return fetch('Cliente_PublicHandler.ashx', { method: 'POST', body: form })
            .then(function(r){ return r.json(); });
    }

    // ============================================================
    // Toggle entrega
    // ============================================================
    window.toggleEntrega = function(eid) {
        var body = document.getElementById('body-' + eid);
        var chev = document.getElementById('chev-' + eid);
        var card = body.parentNode;
        if (!body) return;
        var willOpen = body.style.display === 'none';

        // Cerrar todas las demas
        document.querySelectorAll('.entrega-body').forEach(function(b){ b.style.display = 'none'; });
        document.querySelectorAll('.chev').forEach(function(c){ c.classList.remove('up'); });
        document.querySelectorAll('.entrega-card').forEach(function(c){ c.classList.remove('activa'); });

        if (willOpen) {
            body.style.display = 'block';
            chev.classList.add('up');
            card.classList.add('activa');
        }
    };

    // ============================================================
    // Guardar campos
    // ============================================================
    window.guardarCampoCliente = function(campo, valor) {
        var f = new FormData();
        f.append('accion', 'GUARDAR_CLIENTE');
        f.append('token', token);
        f.append('campo', campo);
        f.append('valor', valor);
        postHandler(f).then(function(d){
            if (d.ok) flash('Guardado'); else flash(d.msg || 'Error', false);
        }).catch(function(){ flash('Sin conexion', false); });
    };

    window.guardarCampoEntrega = function(input) {
        var eid = input.getAttribute('data-eid');
        var campo = input.getAttribute('data-campo');
        var f = new FormData();
        f.append('accion', 'GUARDAR_ENTREGA');
        f.append('token', token);
        f.append('entrega_id', eid);
        f.append('campo', campo);
        f.append('valor', input.value);
        postHandler(f).then(function(d){
            if (d.ok) flash('Guardado'); else flash(d.msg || 'Error', false);
        }).catch(function(){ flash('Sin conexion', false); });
    };

    // ============================================================
    // Cambio de metodo de pago
    // ============================================================
    window.cambiarMetodoPago = function() {
        var m = document.getElementById('ddMetodoPago').value;
        var ids = ['boxQR','boxTransfer','boxPaypal','boxEfectivo','boxTarjeta'];
        ids.forEach(function(id){ var el = document.getElementById(id); if (el) el.style.display='none'; });

        var avComp = document.getElementById('avisoComprobante');
        var btnWsp = document.getElementById('btnWsp');
        var wspHint = document.getElementById('wspHint');
        var mostrarWsp = false;

        if (m === 'QR') { document.getElementById('boxQR').style.display='block'; mostrarWsp = true; }
        else if (m === 'TRANSFERENCIA') { document.getElementById('boxTransfer').style.display='block'; mostrarWsp = true; }
        else if (m === 'PAYPAL') { document.getElementById('boxPaypal').style.display='block'; mostrarWsp = true; }
        else if (m === 'EFECTIVO') { document.getElementById('boxEfectivo').style.display='block'; }
        else if (m === 'TARJETA') { document.getElementById('boxTarjeta').style.display='block'; }

        if (avComp) avComp.style.display = mostrarWsp ? 'block' : 'none';
        if (btnWsp) btnWsp.style.display = mostrarWsp ? 'flex' : 'none';
        if (wspHint) wspHint.style.display = mostrarWsp ? 'block' : 'none';

        // Guardar metodo
        if (m) {
            var f = new FormData();
            f.append('accion', 'GUARDAR_METODO_PAGO');
            f.append('token', token);
            f.append('metodo', m);
            postHandler(f).then(function(d){ if (d.ok) flash('Guardado'); });
        }
    };

    // ============================================================
    // Confirmar pedido
    // ============================================================
    window.confirmarPedido = function() {
        // Validar datos del cliente
        var nombre = (document.getElementById('txClienteNombre') || {}).value || '';
        var email = (document.getElementById('txClienteEmail') || {}).value || '';
        if (!nombre.trim()) { alert('Por favor escribi tu nombre'); return; }
        if (!email.trim()) { alert('Por favor escribi tu email'); return; }

        // Validar metodo de pago
        var metodo = (document.getElementById('ddMetodoPago') || {}).value || '';
        if (!metodo) { alert('Selecciona como pagas'); return; }

        // Validar entregas: cada una necesita receptor_nombre, receptor_celular, direccion
        var faltan = [];
        document.querySelectorAll('.entrega-card').forEach(function(card){
            var eid = card.getAttribute('data-entrega-id');
            var inputs = card.querySelectorAll('input[data-campo][required], textarea[data-campo][required]');
            var falta = false;
            inputs.forEach(function(inp){
                if (!inp.value.trim()) falta = true;
            });
            if (falta) faltan.push({eid:eid, card:card});
        });

        if (faltan.length > 0) {
            faltan.forEach(function(it){
                it.card.classList.add('faltan');
                var badge = it.card.querySelector('.entrega-badge');
                if (badge) { badge.textContent = 'INCOMPLETA'; badge.className = 'entrega-badge faltan'; }
            });
            // Abrir la primera
            window.toggleEntrega(faltan[0].eid);
            alert('Faltan datos en algunas entregas (marcadas en rojo). Completalas para confirmar.');
            return;
        }

        if (!confirm('¿Confirmar el pedido?\nMiss Flores recibira tus datos para preparar la entrega.')) return;

        var f = new FormData();
        f.append('accion', 'CONFIRMAR');
        f.append('token', token);
        postHandler(f).then(function(d){
            if (d.ok) location.reload();
            else alert('Error: ' + (d.msg || 'no se pudo confirmar'));
        }).catch(function(){ alert('Error de red'); });
    };

    // ============================================================
    // Init: si ya hay metodo guardado, marcarlo
    // ============================================================
    document.addEventListener('DOMContentLoaded', function(){
        var metodoActual = (document.getElementById('hdMetodoActual') || {}).value || '';
        if (metodoActual) {
            var dd = document.getElementById('ddMetodoPago');
            if (dd) { dd.value = metodoActual; window.cambiarMetodoPago(); }
        }
    });
})();
</script>

</body>
</html>
