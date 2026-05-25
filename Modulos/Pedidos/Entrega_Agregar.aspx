<%@ Page Title="Gestionar Entrega" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Entrega_Agregar.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_Entrega_Agregar" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
.ea-section { background:white; border:1px solid #e0e0e0; border-radius:12px; margin-bottom:8px; overflow:hidden; }
.ea-section-header { padding:10px 20px; cursor:pointer; display:flex; align-items:center; justify-content:space-between; }
.ea-section-header:hover { background:#fafafa; }
.ea-section-title { display:flex; align-items:center; gap:8px; font-size:14px; font-weight:500; }
.ea-section-summary { font-size:11px; color:#999; }
.ea-section-body { padding:0 20px 16px; border-top:1px solid #f0f0f0; }
.ea-bar { background:white; border:1px solid #e0e0e0; border-radius:12px; padding:8px 16px; margin-bottom:10px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px; }
.ea-bar-left { display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.ea-bar-sep { width:1px; height:20px; background:#e0e0e0; }
.ea-productos { background:white; border:1px solid #e0e0e0; border-radius:12px; padding:16px 20px; margin-bottom:8px; }
.ea-prod-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:10px; padding-bottom:8px; border-bottom:1px solid #f0f0f0; }
.ea-prod-row { display:grid; grid-template-columns:2fr 85px 30px; gap:6px; align-items:center; padding:8px 6px; background:#fafafa; border-radius:8px; margin-bottom:3px; font-size:12px; }
.ea-prod-row.personalizado { background:#FFF8E1; border:1px solid #FFE082; }
.ea-prod-name { font-weight:500; }
.ea-prod-detail { font-size:10px; color:#999; }
.ea-prod-detail span { color:#667eea; }
.ea-prod-custom { font-size:10px; color:#F57F17; }
.ea-btn-buscar { font-size:12px; background:#EBF0FF; color:#3B5BDB; border:none; padding:5px 12px; border-radius:8px; cursor:pointer; }
.ea-btn-buscar:hover { background:#D6E0FF; }
.ea-btn-wsp { font-size:11px; padding:5px 10px; background:#E8F5E9; color:#2E7D32; border:1px solid #A5D6A7; border-radius:8px; }
.ea-btn-link { font-size:11px; padding:5px 10px; background:#EBF0FF; color:#3B5BDB; border:1px solid #90CAF9; border-radius:8px; }
.ea-btn-pago { font-size:11px; padding:4px 10px; background:#EBF0FF; color:#3B5BDB; border:1px solid #90CAF9; border-radius:8px; }
.ea-grid-2 { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
.ea-grid-3 { display:grid; grid-template-columns:1fr 1fr 1fr; gap:10px; }
.ea-label { font-size:12px; font-weight:500; display:block; margin-bottom:3px; }
.ea-input { width:100%; padding:7px 10px; border:1px solid #d0d0d0; border-radius:6px; font-size:13px; }
.ea-input:focus { outline:none; border-color:#667eea; box-shadow:0 0 0 3px rgba(102,126,234,0.1); }
.ea-select { width:100%; padding:7px 10px; border:1px solid #d0d0d0; border-radius:6px; font-size:13px; background:white; }
.ea-textarea { width:100%; padding:7px 10px; border:1px solid #d0d0d0; border-radius:6px; font-size:13px; resize:vertical; min-height:60px; }
.ea-radio-group { display:flex; gap:1.5rem; align-items:center; height:36px; }
.ea-radio-label { display:flex; align-items:center; gap:4px; font-size:12px; cursor:pointer; }
.ea-dom-fields { background:#fafafa; border-radius:8px; padding:10px; margin-top:10px; }
.ea-recojo-fields { background:#fafafa; border-radius:8px; padding:12px; margin-top:10px; }
.ea-sucursal-card { flex:1; padding:12px; border-radius:8px; border:1px solid #e0e0e0; cursor:pointer; text-align:center; }
.ea-sucursal-card.selected { border:2px solid #3B5BDB; background:#EBF0FF; }
.ea-resumen { background:white; border:1px solid #e0e0e0; border-radius:12px; padding:16px 20px; margin-bottom:8px; }
.ea-total-row { display:flex; justify-content:space-between; font-size:13px; padding:2px 0; }
.ea-total-row.final { padding-top:6px; margin-top:4px; border-top:2px solid #333; font-size:15px; font-weight:500; }
.ea-pago-row { display:grid; grid-template-columns:1fr 80px 70px 80px 50px 30px; gap:6px; align-items:center; padding:7px 4px; background:#fafafa; border-radius:8px; margin-bottom:3px; font-size:12px; }
.ea-pago-header { display:grid; grid-template-columns:1fr 80px 70px 80px 50px 30px; gap:6px; font-size:10px; color:#aaa; text-transform:uppercase; padding:0 4px; margin-bottom:4px; }
.ea-link-states { display:grid; grid-template-columns:1fr 1fr 1fr; gap:8px; margin-bottom:10px; }
.ea-link-state { text-align:center; padding:8px; border-radius:8px; border:1px solid #e0e0e0; }
.ea-link-state.active { border:2px solid #F9A825; background:#FFF8E1; }
.ea-link-state.inactive { opacity:0.4; }
.ea-check-grid { display:grid; grid-template-columns:1fr 1fr; gap:3px 16px; font-size:12px; margin-bottom:12px; }
.ea-check-item { display:flex; align-items:center; gap:5px; padding:2px 0; }
.ea-btn-wc { width:100%; font-size:13px; padding:11px; display:flex; align-items:center; justify-content:center; gap:7px; background:#EBF0FF; color:#3B5BDB; border:1px solid #90CAF9; border-radius:8px; cursor:pointer; font-weight:500; }
.ea-btn-wc:disabled { background:#f5f5f5; color:#ccc; border-color:#e0e0e0; cursor:not-allowed; }
.ea-badge { font-size:11px; padding:2px 8px; border-radius:10px; }
.ea-badge-warning { background:#FFF8E1; color:#F57F17; }
.ea-badge-success { background:#E8F5E9; color:#2E7D32; }
.ea-badge-count { font-size:11px; color:#999; background:#f5f5f5; padding:2px 8px; border-radius:10px; }
.ea-saved { font-size:11px; color:#2E7D32; display:flex; align-items:center; gap:3px; }
.ea-descuento-row { display:flex; justify-content:space-between; align-items:center; margin-top:4px; padding-top:4px; border-top:1px solid #f0f0f0; }
.ea-descuento-input { display:flex; align-items:center; gap:4px; }
.ea-pago-resumen { margin-top:10px; padding-top:8px; border-top:1px solid #f0f0f0; font-size:13px; }
</style>
</asp:Content>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-package" style="vertical-align:-2px"></i> <%=If(ModoEdicion, "Editar", "Agregar")%> Entrega
</asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

<div class="alerta" id="divAlerta"><%=MensajeAlerta%></div>

<!-- HEADER INFO -->
<div class="panel" style="margin-bottom:10px">
    <div class="panel-head">
        <div class="panel-title"><i class="ti ti-shopping-cart"></i> Pre-Pedido: <%=PrePedidoCodigo%></div>
        <div class="panel-actions">
            <a href="PrePedido_Detalle.aspx?id=<%=PrePedidoId%>" class="btn btn-sm"><i class="ti ti-arrow-left"></i> Volver</a>
        </div>
    </div>
    <div class="panel-body">
        <p style="margin:0;font-size:13px;color:#666">Cliente: <strong><%=ClienteNombre%></strong> &mdash; <%=ClienteCelular%> &mdash; <%=ClienteEmail%></p>
    </div>
</div>

<!-- BARRA ACCIONES -->
<div class="ea-bar">
    <div class="ea-bar-left">
        <select id="ddMoneda" name="ddMoneda" class="ea-select" style="width:auto;padding:3px 8px;font-size:12px" onchange="guardarCampo('moneda', this.value)">
            <option value="BOB" <%=If(MonedaSeleccionada = "BOB", "selected", "")%>>Bs</option>
            <option value="USD" <%=If(MonedaSeleccionada = "USD", "selected", "")%>>USD</option>
        </select>
        <div class="ea-bar-sep"></div>
        <div style="display:flex;align-items:center;gap:4px">
            <i class="ti ti-building-store" style="font-size:14px;color:#999" aria-hidden="true"></i>
            <span style="font-size:11px;color:#999">Prepara:</span>
            <select id="ddSucursalPrepara" name="ddSucursalPrepara" class="ea-select" style="width:auto;padding:3px 8px;font-size:12px" onchange="guardarCampo('sucursal_prepara_id', this.value)">
                <option value="0">No definido</option>
                <%=HtmlSucursales%>
            </select>
        </div>
        <div class="ea-bar-sep"></div>
        <span class="ea-saved" id="spanGuardado"><i class="ti ti-check" style="font-size:13px" aria-hidden="true"></i> Guardado</span>
    </div>
    <div style="display:flex;gap:6px">
        <button type="button" class="ea-btn-wsp" onclick="enviarCotizacionWsp()"><i class="ti ti-brand-whatsapp" style="font-size:14px;vertical-align:-2px" aria-hidden="true"></i> Cotización</button>
        <button type="button" class="ea-btn-link" onclick="enviarLinkCliente()"><i class="ti ti-link" style="font-size:14px;vertical-align:-2px" aria-hidden="true"></i> Enviar link</button>
    </div>
</div>

<!-- ============================================ -->
<!-- 1. PRODUCTOS -->
<!-- ============================================ -->
<div class="ea-productos">
    <div class="ea-prod-header">
        <div style="display:flex;align-items:center;gap:8px">
            <i class="ti ti-shopping-bag" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
            <span style="font-size:14px;font-weight:500">Productos</span>
            <span class="ea-badge-count" id="spanCantItems">0 items</span>
        </div>
        <button type="button" class="ea-btn-buscar" onclick="abrirBuscadorProductos()"><i class="ti ti-search" style="font-size:14px;vertical-align:-2px" aria-hidden="true"></i> Buscar producto</button>
    </div>
    <div style="display:grid;grid-template-columns:2fr 85px 30px;gap:6px;font-size:10px;color:#aaa;text-transform:uppercase;padding:0 6px;margin-bottom:4px">
        <span>Producto</span><span>Precio</span><span></span>
    </div>
    <div id="divProductos"><%=HtmlProductos%></div>
    <div style="display:flex;justify-content:flex-end;gap:1rem;margin-top:8px;padding-top:8px;border-top:1px solid #f0f0f0;font-size:13px">
        <span style="color:#999">Subtotal:</span>
        <span style="font-weight:500" id="spanSubtotal">Bs 0.00</span>
    </div>
</div>

<!-- ============================================ -->
<!-- 2. DATOS DE ENTREGA (colapsable) -->
<!-- ============================================ -->
<div class="ea-section">
    <div class="ea-section-header" onclick="toggleSeccion('secEntrega')">
        <div class="ea-section-title">
            <i class="ti ti-chevron-down" id="secEntregaArrow" aria-hidden="true"></i>
            <i class="ti ti-truck-delivery" style="color:#3B5BDB" aria-hidden="true"></i>
            Datos de entrega
        </div>
        <span class="ea-section-summary" id="secEntregaResumen"></span>
    </div>
    <div class="ea-section-body" id="secEntregaBody">
        <div class="ea-grid-2" style="padding-top:10px;margin-bottom:10px">
            <div>
                <label class="ea-label">Ciudad *</label>
                <select id="ddCiudad" name="ddCiudad" class="ea-select" onchange="filtrarZonas(); guardarCampo('ciudad_id', this.value)">
                    <option value="">-- Seleccionar --</option>
                    <%=HtmlCiudades%>
                </select>
            </div>
            <div>
                <label class="ea-label">Tipo de entrega *</label>
                <div class="ea-radio-group">
                    <label class="ea-radio-label"><input type="radio" name="tipoEntrega" value="DOMICILIO" <%=If(ValorTipoEntrega <> "RECOJO_SUCURSAL", "checked", "")%> onchange="toggleTipoEntrega(); guardarCampo('tipo_entrega', 'DOMICILIO')"> Domicilio</label>
                    <label class="ea-radio-label"><input type="radio" name="tipoEntrega" value="RECOJO_SUCURSAL" <%=If(ValorTipoEntrega = "RECOJO_SUCURSAL", "checked", "")%> onchange="toggleTipoEntrega(); guardarCampo('tipo_entrega', 'RECOJO_SUCURSAL')"> Recojo</label>
                </div>
            </div>
        </div>
        <!-- DOMICILIO -->
        <div id="fieldsDomicilio" class="ea-dom-fields">
            <div class="ea-grid-2" style="margin-bottom:8px">
                <div>
                    <label class="ea-label">Zona *</label>
                    <select id="ddZona" name="ddZona" class="ea-select" onchange="guardarCampo('zona_id', this.value)">
                        <option value="">-- Seleccionar --</option>
                    </select>
                </div>
                <div>
                    <label class="ea-label">Dirección *</label>
                    <input type="text" id="txDireccion" name="txDireccion" class="ea-input" value="<%=ValorDireccion%>" onblur="guardarCampo('direccion', this.value)">
                </div>
            </div>
            <div class="ea-grid-2">
                <div>
                    <label class="ea-label">Referencia</label>
                    <input type="text" id="txReferencia" name="txReferencia" class="ea-input" value="<%=ValorReferencia%>" onblur="guardarCampo('referencia', this.value)">
                </div>
                <div>
                    <label class="ea-label">GPS / Nota</label>
                    <input type="text" id="txGps" name="txGps" class="ea-input" value="<%=ValorGps%>" placeholder="Coordenadas o nota interna..." onblur="guardarCampo('gps', this.value)">
                </div>
            </div>
        </div>
        <!-- RECOJO -->
        <div id="fieldsRecojo" class="ea-recojo-fields" style="display:none">
            <label class="ea-label" style="margin-bottom:8px">Sucursal de recojo:</label>
            <div style="display:flex;gap:12px">
                <%=HtmlSucursalesRecojo%>
            </div>
        </div>
    </div>
</div>

<!-- ============================================ -->
<!-- 3. FECHA Y HORARIO (colapsable) -->
<!-- ============================================ -->
<div class="ea-section">
    <div class="ea-section-header" onclick="toggleSeccion('secFecha')">
        <div class="ea-section-title">
            <i class="ti ti-chevron-down" id="secFechaArrow" aria-hidden="true"></i>
            <i class="ti ti-calendar" style="color:#3B5BDB" aria-hidden="true"></i>
            Fecha y horario
        </div>
        <span class="ea-section-summary" id="secFechaResumen"></span>
    </div>
    <div class="ea-section-body" id="secFechaBody">
        <div class="ea-grid-3" style="padding-top:10px">
            <div>
                <label class="ea-label">Fecha de entrega *</label>
                <input type="date" id="txFecha" name="txFecha" class="ea-input" value="<%=ValorFecha%>" min="<%=FechaMinima%>" onchange="guardarCampo('fecha_entrega', this.value)">
            </div>
            <div>
                <label class="ea-label">Horario</label>
                <select id="ddSlot" name="ddSlot" class="ea-select" onchange="guardarCampo('slot_id', this.value)">
                    <option value="">-- Seleccionar --</option>
                    <%=HtmlSlots%>
                </select>
            </div>
            <div>
                <label class="ea-label">&nbsp;</label>
                <label class="ea-radio-label" style="height:36px"><input type="checkbox" id="chkExpress" name="chkExpress" <%=If(ValorExpress, "checked", "")%> onchange="guardarCampo('es_express', this.checked ? '1' : '0')"> Express</label>
            </div>
        </div>
    </div>
</div>

<!-- ============================================ -->
<!-- 4. DESTINATARIO Y DEDICATORIA (colapsable) -->
<!-- ============================================ -->
<div class="ea-section">
    <div class="ea-section-header" onclick="toggleSeccion('secDestinatario')">
        <div class="ea-section-title">
            <i class="ti ti-chevron-down" id="secDestinatarioArrow" aria-hidden="true"></i>
            <i class="ti ti-user-heart" style="color:#3B5BDB" aria-hidden="true"></i>
            Destinatario y dedicatoria
        </div>
        <span class="ea-section-summary" id="secDestinatarioResumen"></span>
    </div>
    <div class="ea-section-body" id="secDestinatarioBody">
        <div class="ea-grid-3" style="padding-top:10px;margin-bottom:10px">
            <div>
                <label class="ea-label">Persona que recibe *</label>
                <input type="text" id="txReceptor" name="txReceptor" class="ea-input" value="<%=ValorReceptor%>" onblur="guardarCampo('receptor_nombre', this.value)">
            </div>
            <div>
                <label class="ea-label">Celular *</label>
                <input type="text" id="txCelularReceptor" name="txCelularReceptor" class="ea-input" value="<%=ValorCelularReceptor%>" onblur="guardarCampo('receptor_celular', this.value)">
            </div>
            <div>
                <label class="ea-label">Ocasión</label>
                <select id="ddOcasion" name="ddOcasion" class="ea-select" onchange="guardarCampo('tipo_ocacion', this.value)">
                    <option value="">-- Seleccionar --</option>
                    <option value="CUMPLEANOS" <%=If(ValorOcasion = "CUMPLEANOS", "selected", "")%>>Cumpleaños</option>
                    <option value="ANIVERSARIO" <%=If(ValorOcasion = "ANIVERSARIO", "selected", "")%>>Aniversario</option>
                    <option value="CONDOLENCIAS" <%=If(ValorOcasion = "CONDOLENCIAS", "selected", "")%>>Condolencias</option>
                    <option value="AGRADECIMIENTO" <%=If(ValorOcasion = "AGRADECIMIENTO", "selected", "")%>>Agradecimiento</option>
                    <option value="AMOR" <%=If(ValorOcasion = "AMOR", "selected", "")%>>Amor</option>
                    <option value="NACIMIENTO" <%=If(ValorOcasion = "NACIMIENTO", "selected", "")%>>Nacimiento</option>
                    <option value="GRADUACION" <%=If(ValorOcasion = "GRADUACION", "selected", "")%>>Graduación</option>
                    <option value="OTRO" <%=If(ValorOcasion = "OTRO", "selected", "")%>>Otro</option>
                </select>
            </div>
        </div>
        <div style="margin-bottom:8px">
            <label class="ea-label">Dedicatoria <span style="color:#999;font-weight:400">(500)</span></label>
            <textarea id="txDedicatoria" name="txDedicatoria" class="ea-textarea" maxlength="500" onblur="guardarCampo('dedicatoria', this.value)"><%=ValorDedicatoria%></textarea>
        </div>
        <div>
            <label class="ea-label">Firma <span style="color:#999;font-weight:400">(100)</span></label>
            <input type="text" id="txFirma" name="txFirma" class="ea-input" value="<%=ValorFirma%>" maxlength="100" onblur="guardarCampo('firma_tarjeta', this.value)">
        </div>
    </div>
</div>

<!-- ============================================ -->
<!-- 5. RESUMEN -->
<!-- ============================================ -->
<div class="ea-resumen">
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px;padding-bottom:8px;border-bottom:1px solid #f0f0f0">
        <i class="ti ti-receipt" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
        <span style="font-size:14px;font-weight:500">Resumen</span>
    </div>
    <div id="divResumen">
        <div class="ea-total-row"><span style="color:#999">Subtotal productos</span><span id="resSubtotal">Bs 0.00</span></div>
        <div class="ea-total-row"><span style="color:#999">Envío</span><span id="resEnvio">Bs 0.00</span></div>
        <div class="ea-total-row"><span style="color:#999">Recargo horario</span><span id="resRecargoHorario">Bs 0.00</span></div>
        <div class="ea-total-row"><span style="color:#999">Recargo express</span><span id="resRecargoExpress">Bs 0.00</span></div>
        <div class="ea-descuento-row">
            <span style="color:#2E7D32"><i class="ti ti-discount-2" style="font-size:14px;vertical-align:-2px" aria-hidden="true"></i> Descuento</span>
            <div class="ea-descuento-input">
                <span style="font-size:12px;color:#2E7D32">-</span>
                <input type="number" id="txDescuento" name="txDescuento" value="<%=ValorDescuento%>" min="0" max="100" step="5" style="width:55px;text-align:center;padding:3px;font-size:12px;border:1px solid #d0d0d0;border-radius:4px" onblur="guardarCampo('descuento', this.value)">
                <select id="ddDescuentoMoneda" name="ddDescuentoMoneda" style="width:auto;padding:3px 4px;font-size:11px;border:1px solid #d0d0d0;border-radius:4px" onchange="guardarCampo('descuento_moneda', this.value)">
                    <option value="BOB" <%=If(ValorDescuentoMoneda = "BOB" Or ValorDescuentoMoneda = "", "selected", "")%>>Bs</option>
                    <option value="USD" <%=If(ValorDescuentoMoneda = "USD", "selected", "")%>>USD</option>
                </select>
            </div>
        </div>
        <p style="margin:0;font-size:10px;color:#999">Máx 100 Bs / 15 USD</p>
        <div class="ea-total-row final"><span>Total</span><span id="resTotal">Bs 0.00</span></div>
    </div>
</div>

<!-- ============================================ -->
<!-- 6. PAGOS -->
<!-- ============================================ -->
<div class="ea-resumen">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid #f0f0f0">
        <div style="display:flex;align-items:center;gap:8px">
            <i class="ti ti-cash" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
            <span style="font-size:14px;font-weight:500">Pagos</span>
            <span class="ea-badge ea-badge-warning" id="spanEstadoPago">Pendiente</span>
        </div>
        <button type="button" class="ea-btn-pago" onclick="abrirModalPago()"><i class="ti ti-plus" style="font-size:13px;vertical-align:-1px" aria-hidden="true"></i> Registrar pago</button>
    </div>
    <div class="ea-pago-header"><span>Método</span><span>Monto</span><span>Moneda</span><span>Fecha</span><span>Verif.</span><span></span></div>
    <div id="divPagos"><%=HtmlPagos%></div>
    <div class="ea-pago-resumen">
        <div style="display:flex;justify-content:space-between;margin-bottom:3px"><span style="color:#999">Total pedido:</span><span id="pagoTotal">Bs 0.00</span></div>
        <div style="display:flex;justify-content:space-between;margin-bottom:3px"><span style="color:#999">Total pagado:</span><span style="color:#2E7D32" id="pagoPagado">Bs 0.00</span></div>
        <div style="display:flex;justify-content:space-between;font-weight:500"><span style="color:#E53935">Saldo pendiente:</span><span style="color:#E53935" id="pagoSaldo">Bs 0.00</span></div>
    </div>
</div>

<!-- ============================================ -->
<!-- 7. ESTADO DEL LINK -->
<!-- ============================================ -->
<div class="ea-resumen">
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid #f0f0f0">
        <i class="ti ti-link" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
        <span style="font-size:14px;font-weight:500">Estado del link</span>
    </div>
    <div class="ea-link-states">
        <div class="ea-link-state <%=If(EstadoLink = 0, "active", "inactive")%>">
            <div style="width:26px;height:26px;border-radius:50%;background:#f5f5f5;display:flex;align-items:center;justify-content:center;margin:0 auto 4px"><i class="ti ti-link-off" style="font-size:14px;color:#999" aria-hidden="true"></i></div>
            <p style="margin:0;font-size:10px;font-weight:500">No enviado</p>
        </div>
        <div class="ea-link-state <%=If(EstadoLink = 1, "active", "inactive")%>">
            <div style="width:26px;height:26px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;margin:0 auto 4px"><i class="ti ti-clock" style="font-size:14px;color:#F9A825" aria-hidden="true"></i></div>
            <p style="margin:0;font-size:10px;font-weight:500">Esperando</p>
        </div>
        <div class="ea-link-state <%=If(EstadoLink = 2, "active", "inactive")%>">
            <div style="width:26px;height:26px;border-radius:50%;background:#f5f5f5;display:flex;align-items:center;justify-content:center;margin:0 auto 4px"><i class="ti ti-check" style="font-size:14px;color:#2E7D32" aria-hidden="true"></i></div>
            <p style="margin:0;font-size:10px;font-weight:500">Completó</p>
        </div>
    </div>
    <button type="button" class="btn" style="width:100%;font-size:12px;padding:7px;display:flex;align-items:center;justify-content:center;gap:5px" onclick="verificarLink()"><i class="ti ti-refresh" style="font-size:14px" aria-hidden="true"></i> Verificar si el cliente ya llenó</button>
</div>

<!-- ============================================ -->
<!-- 8. CAMPOS OBLIGATORIOS + WOOCOMMERCE -->
<!-- ============================================ -->
<div class="ea-resumen">
    <div style="display:flex;align-items:center;gap:8px;margin-bottom:10px;padding-bottom:8px;border-bottom:1px solid #f0f0f0">
        <i class="ti ti-list-check" style="font-size:17px;color:#3B5BDB" aria-hidden="true"></i>
        <span style="font-size:14px;font-weight:500">Campos obligatorios</span>
        <span class="ea-badge" id="spanCamposConteo">0 de 7</span>
    </div>
    <div class="ea-check-grid" id="divChecklist"></div>
    <button type="button" class="ea-btn-wc" id="btnCrearWC" disabled onclick="crearPedidoWC()">
        <i class="ti ti-shopping-cart-plus" style="font-size:17px" aria-hidden="true"></i> Crear pedido en WooCommerce
    </button>
    <p style="margin:5px 0 0;font-size:10px;color:#999;text-align:center" id="txtEstadoWC">Faltan campos obligatorios</p>
</div>

<!-- HIDDEN FIELDS -->
<input type="hidden" id="hdPedidoId" name="hdPedidoId" value="<%=PedidoId%>">
<input type="hidden" id="hdPrePedidoId" name="hdPrePedidoId" value="<%=PrePedidoId%>">
<input type="hidden" id="hdAccion" name="hdAccion" value="">
<asp:Button ID="btnAccion" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

var pedidoId = parseInt(document.getElementById('hdPedidoId').value) || 0;
var prepedidoId = parseInt(document.getElementById('hdPrePedidoId').value) || 0;
var zonasData = <%=ZonasJson%>;
var slotsData = <%=SlotsJson%>;

// ============================================================
// SECCIONES COLAPSABLES
// ============================================================
function toggleSeccion(nombre) {
    var body = document.getElementById(nombre + 'Body');
    var arrow = document.getElementById(nombre + 'Arrow');
    if (body.style.display === 'none') {
        body.style.display = 'block';
        arrow.className = 'ti ti-chevron-down';
    } else {
        body.style.display = 'none';
        arrow.className = 'ti ti-chevron-right';
    }
}

// ============================================================
// TOGGLE DOMICILIO / RECOJO
// ============================================================
function toggleTipoEntrega() {
    var isDomicilio = document.querySelector('input[name="tipoEntrega"][value="DOMICILIO"]').checked;
    document.getElementById('fieldsDomicilio').style.display = isDomicilio ? 'block' : 'none';
    document.getElementById('fieldsRecojo').style.display = isDomicilio ? 'none' : 'block';
}

// ============================================================
// FILTRAR ZONAS POR CIUDAD
// ============================================================
function filtrarZonas() {
    var ciudadId = parseInt(document.getElementById('ddCiudad').value) || 0;
    var ddZona = document.getElementById('ddZona');
    ddZona.innerHTML = '<option value="">-- Seleccionar --</option>';
    zonasData.forEach(function(z) {
        if (z.ciudad_id === ciudadId) {
            var opt = document.createElement('option');
            opt.value = z.zona_id;
            opt.textContent = z.nombre;
            ddZona.appendChild(opt);
        }
    });
}

// ============================================================
// AUTO-GUARDADO VIA AJAX
// ============================================================
function guardarCampo(campo, valor) {
    if (pedidoId === 0) return;
    var span = document.getElementById('spanGuardado');
    span.innerHTML = '<i class="ti ti-loader" style="font-size:13px" aria-hidden="true"></i> Guardando...';
    span.style.color = '#999';

    var formData = new FormData();
    formData.append('accion', 'GUARDAR_CAMPO');
    formData.append('pedido_id', pedidoId);
    formData.append('campo', campo);
    formData.append('valor', valor);

    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) {
            span.innerHTML = '<i class="ti ti-check" style="font-size:13px" aria-hidden="true"></i> Guardado';
            span.style.color = '#2E7D32';
        } else {
            span.innerHTML = '<i class="ti ti-x" style="font-size:13px" aria-hidden="true"></i> Error';
            span.style.color = '#E53935';
        }
    })
    .catch(function() {
        span.innerHTML = '<i class="ti ti-x" style="font-size:13px" aria-hidden="true"></i> Error';
        span.style.color = '#E53935';
    });
}

// ============================================================
// INICIALIZAR
// ============================================================
document.addEventListener('DOMContentLoaded', function() {
    toggleTipoEntrega();
    filtrarZonas();
});

// ============================================================
// FUNCIONES PLACEHOLDER (se implementarán)
// ============================================================
function abrirBuscadorProductos() { alert('Buscador de productos - En desarrollo'); }
function enviarCotizacionWsp() { alert('Enviar cotización WhatsApp - En desarrollo'); }
function enviarLinkCliente() { alert('Enviar link al cliente - En desarrollo'); }
function abrirModalPago() { alert('Registrar pago - En desarrollo'); }
function verificarLink() { location.reload(); }
function crearPedidoWC() { alert('Crear pedido en WooCommerce - En desarrollo'); }
function seleccionarSucursalRecojo(id) { guardarCampo('sucursal_id', id); }
</script>
</asp:Content>
