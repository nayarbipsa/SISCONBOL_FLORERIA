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
.ea-modal-overlay { display:none; position:fixed; top:0; left:0; right:0; bottom:0; background:rgba(0,0,0,0.45); z-index:9999; overflow-y:auto; padding:20px; }
.ea-modal { background:white; border-radius:12px; max-width:620px; margin:0 auto; border:1px solid #e0e0e0; }
.ea-modal-sm { max-width:450px; margin:40px auto; }
.ea-modal-header { padding:12px 20px; border-bottom:1px solid #f0f0f0; display:flex; justify-content:space-between; align-items:center; background:#fafafa; border-radius:12px 12px 0 0; }
.ea-modal-close { border:none; background:none; cursor:pointer; font-size:18px; color:#999; }
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
        <button type="button" class="ea-btn-wsp" onclick="enviarCotizacionWsp()"><i class="ti ti-brand-whatsapp" style="font-size:14px;vertical-align:-2px" aria-hidden="true"></i> Cotizacion</button>
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
                    <input type="text" id="txZonaBuscar" class="ea-input" placeholder="Escriba para buscar zona..." list="dlZonas" autocomplete="off" value="<%=ValorZonaTexto%>" onchange="seleccionarZona(this.value)">
                    <datalist id="dlZonas"></datalist>
                    <input type="hidden" id="hdZonaId" name="ddZona" value="<%=If(ValorZonaId>0, ValorZonaId.ToString(), "")%>">
                </div>
                <div>
                    <label class="ea-label">Direccion *</label>
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
                <select id="ddSlot" name="ddSlot" class="ea-select" onchange="guardarCampo('slot_id', this.value); calcularSubtotal()">
                    <option value="">-- Seleccionar --</option>
                    <%=HtmlSlots%>
                </select>
            </div>
            <div>
                <label class="ea-label">&nbsp;</label>
                <label class="ea-radio-label" style="height:36px"><input type="checkbox" id="chkExpress" name="chkExpress" <%=If(ValorExpress, "checked", "")%> onchange="guardarCampo('es_express', this.checked ? '1' : '0'); calcularSubtotal()"> Express</label>
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
                <label class="ea-label">Ocasion</label>
                <select id="ddOcasion" name="ddOcasion" class="ea-select" onchange="guardarCampo('tipo_ocacion', this.value)">
                    <option value="">-- Seleccionar --</option>
                    <option value="CUMPLEANOS" <%=If(ValorOcasion = "CUMPLEANOS", "selected", "")%>>Cumpleaños</option>
                    <option value="ANIVERSARIO" <%=If(ValorOcasion = "ANIVERSARIO", "selected", "")%>>Aniversario</option>
                    <option value="CONDOLENCIAS" <%=If(ValorOcasion = "CONDOLENCIAS", "selected", "")%>>Condolencias</option>
                    <option value="AGRADECIMIENTO" <%=If(ValorOcasion = "AGRADECIMIENTO", "selected", "")%>>Agradecimiento</option>
                    <option value="AMOR" <%=If(ValorOcasion = "AMOR", "selected", "")%>>Amor</option>
                    <option value="NACIMIENTO" <%=If(ValorOcasion = "NACIMIENTO", "selected", "")%>>Nacimiento</option>
                    <option value="GRADUACION" <%=If(ValorOcasion = "GRADUACION", "selected", "")%>>Graduacion</option>
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
                <input type="number" id="txDescuento" name="txDescuento" value="<%=ValorDescuento%>" min="0" max="100" step="5" style="width:55px;text-align:center;padding:3px;font-size:12px;border:1px solid #d0d0d0;border-radius:4px" onblur="guardarCampo('descuento', this.value); calcularSubtotal()" onchange="calcularSubtotal()">
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
<input type="hidden" id="hdPrePedidoEntregaId" name="hdPrePedidoEntregaId" value="<%=PrePedidoEntregaId%>">
<input type="hidden" id="hdPrePedidoId" name="hdPrePedidoId" value="<%=PrePedidoId%>">
<input type="hidden" id="hdAccion" name="hdAccion" value="">
<asp:Button ID="btnAccion" runat="server" Text="" Style="display:none" OnClick="btnAccion_Click"/>


<!-- MODAL BUSCADOR DE PRODUCTOS -->
<div id="modalBuscador" class="ea-modal-overlay">
    <div class="ea-modal">
        <div class="ea-modal-header">
            <span style="font-size:15px;font-weight:500"><i class="ti ti-search" style="font-size:17px;vertical-align:-2px;margin-right:6px" aria-hidden="true"></i>Buscar producto</span>
            <button type="button" onclick="cerrarBuscador()" class="ea-modal-close"><i class="ti ti-x" aria-hidden="true"></i></button>
        </div>
        <div style="padding:10px 20px;border-bottom:1px solid #f0f0f0">
            <div style="display:flex;gap:6px;margin-bottom:6px">
                <input type="text" id="txBuscarProd" placeholder="Buscar por nombre, SKU..." class="ea-input" style="flex:1" onkeyup="if(event.key==='Enter')buscarProductos()">
                <button type="button" onclick="buscarProductos()" class="ea-btn-buscar"><i class="ti ti-search" style="font-size:14px" aria-hidden="true"></i></button>
            </div>
            <div style="display:flex;gap:6px;align-items:center">
                <label style="font-size:11px;color:#999;white-space:nowrap">Categoría:</label>
                <select id="ddCategoriaFiltro" class="ea-select" style="font-size:12px;flex:1" onchange="buscarProductos()">
                    <option value="0" selected>Todas las categorías</option>
                    <%=HtmlCategoriasBtns%>
                </select>
            </div>
        </div>
        <div style="padding:10px 20px;border-bottom:2px solid #FFE082;background:#FFF8E1">
            <div style="display:flex;gap:10px;align-items:center">
                <div style="width:40px;height:40px;min-width:40px;border-radius:50%;background:white;display:flex;align-items:center;justify-content:center">
                    <i class="ti ti-pencil-plus" style="font-size:18px;color:#F57F17" aria-hidden="true"></i>
                </div>
                <div style="flex:1">
                    <p style="margin:0;font-size:13px;font-weight:500;color:#F57F17">Producto Personalizado</p>
                    <div style="display:grid;grid-template-columns:2fr 1fr;gap:6px;margin-top:6px">
                        <input type="text" id="txPersNombre" placeholder="Nombre del producto..." class="ea-input" style="font-size:11px;padding:4px 6px">
                        <div style="display:flex;gap:3px">
                            <input type="number" id="txPersPrecio" placeholder="Precio" step="0.01" class="ea-input" style="font-size:11px;padding:4px;flex:1">
                            <select id="ddPersMoneda" class="ea-select" style="font-size:10px;padding:2px;width:auto"><option value="BOB">Bs</option><option value="USD">USD</option></select>
                        </div>
                    </div>
                    <input type="text" id="txPersDetalle" placeholder="Personalizacion / descripcion..." class="ea-input" style="font-size:11px;padding:4px 6px;margin-top:4px;border-style:dashed">
                    <button type="button" onclick="agregarPersonalizado()" style="font-size:11px;padding:4px 12px;margin-top:6px;background:white;color:#F57F17;border:1px solid #FFE082;border-radius:8px;cursor:pointer"><i class="ti ti-plus" style="font-size:12px;vertical-align:-1px" aria-hidden="true"></i> Agregar personalizado</button>
                </div>
            </div>
        </div>
        <div id="divListaProductos" style="max-height:350px;overflow-y:auto">
            <p style="padding:20px;text-align:center;color:#999;font-size:13px">Escriba para buscar productos...</p>
        </div>
    </div>
</div>

<!-- MODAL REGISTRAR PAGO -->
<div id="modalPago" class="ea-modal-overlay">
    <div class="ea-modal ea-modal-sm">
        <div class="ea-modal-header">
            <span style="font-size:15px;font-weight:500"><i class="ti ti-cash" style="font-size:17px;vertical-align:-2px;margin-right:6px" aria-hidden="true"></i>Registrar pago</span>
            <button type="button" onclick="cerrarModalPago()" class="ea-modal-close"><i class="ti ti-x" aria-hidden="true"></i></button>
        </div>
        <div style="padding:20px">
            <div class="ea-grid-2" style="margin-bottom:10px">
                <div>
                    <label class="ea-label">Método *</label>
                    <select id="ddPagoMetodo" class="ea-select">
                        <option value="">-- Seleccionar --</option>
                        <option value="EFECTIVO">Efectivo</option>
                        <option value="QR">QR Bolivia (BNB)</option>
                        <option value="TRANSFERENCIA">Transferencia</option>
                        <option value="PAYPAL">PayPal</option>
                        <option value="CRIPTO">Cripto USDT</option>
                        <option value="YAPE">Yape</option>
                        <option value="PIX">Pix</option>
                        <option value="TARJETA">Tarjeta</option>
                        <option value="PAGOMOVIL">Pago Movil</option>
                    </select>
                </div>
                <div>
                    <label class="ea-label">Tipo *</label>
                    <select id="ddPagoTipo" class="ea-select">
                        <option value="TOTAL">Total</option>
                        <option value="ANTICIPO">Anticipo</option>
                        <option value="SALDO">Saldo</option>
                    </select>
                </div>
            </div>
            <div class="ea-grid-2" style="margin-bottom:10px">
                <div>
                    <label class="ea-label">Moneda *</label>
                    <select id="ddPagoMoneda" class="ea-select" onchange="recalcularConversion()">
                        <option value="BOB" selected>Bs (Bolivianos)</option>
                        <option value="USD">USD (Dólares)</option>
                    </select>
                </div>
                <div>
                    <label class="ea-label">Tasa de cambio</label>
                    <input type="number" id="txPagoTasa" value="<%=TasaCambio.ToString("F4")%>" step="0.0001" class="ea-input" onchange="recalcularConversion()">
                </div>
            </div>
            <div style="margin-bottom:10px">
                <label class="ea-label">Monto *</label>
                <input type="number" id="txPagoMonto" placeholder="0.00" step="0.01" class="ea-input" oninput="recalcularConversion()">
                <div id="divConversion" style="font-size:11px;color:#999;margin-top:4px;display:none">
                    <i class="ti ti-arrow-right" style="font-size:11px;vertical-align:-1px"></i>
                    Equivale a <span id="spanConversion" style="color:#3B5BDB;font-weight:500"></span>
                </div>
            </div>
            <div style="margin-bottom:10px">
                <label class="ea-label">Referencia / Nro transaccion</label>
                <input type="text" id="txPagoRef" placeholder="Ej: TXN-123456" class="ea-input">
            </div>
            <div style="margin-bottom:10px">
                <label class="ea-label">Observaciones</label>
                <input type="text" id="txPagoObs" placeholder="Opcional..." class="ea-input">
            </div>
            <div style="margin-bottom:16px">
                <label class="ea-label">Estado del pago</label>
                <div style="display:flex;gap:1rem;align-items:center">
                    <label class="ea-radio-label"><input type="radio" name="pagoEstado" value="PENDIENTE" checked> Pendiente</label>
                    <label class="ea-radio-label"><input type="radio" name="pagoEstado" value="VERIFICADO"> Verificado</label>
                    <label class="ea-radio-label"><input type="radio" name="pagoEstado" value="RECHAZADO"> Rechazado</label>
                </div>
            </div>
            <div style="display:flex;justify-content:flex-end;gap:6px;padding-top:10px;border-top:1px solid #f0f0f0">
                <button type="button" onclick="cerrarModalPago()" class="btn" style="font-size:12px;padding:6px 14px">Cancelar</button>
                <button type="button" onclick="guardarPago()" style="font-size:12px;padding:6px 14px;background:#EBF0FF;color:#3B5BDB;border:1px solid #90CAF9;border-radius:8px;cursor:pointer;font-weight:500"><i class="ti ti-check" style="font-size:13px;vertical-align:-1px" aria-hidden="true"></i> Guardar pago</button>
            </div>
        </div>
    </div>
</div>

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

var prepedidoEntregaId = parseInt(document.getElementById('hdPrePedidoEntregaId').value) || 0;
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
function filtrarZonas(preservarSeleccion) {
    var ciudadId = parseInt(document.getElementById('ddCiudad').value) || 0;
    var dl = document.getElementById('dlZonas');
    dl.innerHTML = '';
    if (!preservarSeleccion) {
        document.getElementById('txZonaBuscar').value = '';
        document.getElementById('hdZonaId').value = '';
    }
    zonasData.forEach(function(z) {
        if (z.ciudad_id === ciudadId) {
            var opt = document.createElement('option');
            opt.value = z.nombre + ' (Bs ' + z.precio_bs.toFixed(2) + ')';
            opt.setAttribute('data-id', z.zona_id);
            dl.appendChild(opt);
        }
    });
}
function seleccionarZona(texto) {
    var ciudadId = parseInt(document.getElementById('ddCiudad').value) || 0;
    var encontrada = null;
    zonasData.forEach(function(z) {
        if (z.ciudad_id === ciudadId) {
            var label = z.nombre + ' (Bs ' + z.precio_bs.toFixed(2) + ')';
            if (label === texto) encontrada = z;
        }
    });
    if (encontrada) {
        document.getElementById('hdZonaId').value = encontrada.zona_id;
        guardarCampo('zona_id', encontrada.zona_id);
        calcularSubtotal();
    }
}

// ============================================================
// AUTO-GUARDADO VIA AJAX
// ============================================================
function guardarCampo(campo, valor) {
    if (prepedidoEntregaId === 0) {
        mostrarError();
        return;
    }
    mostrarGuardando();
    var formData = new FormData();
    formData.append('accion', 'GUARDAR_CAMPO');
    formData.append('prepedido_entrega_id', prepedidoEntregaId);
    formData.append('campo', campo);
    formData.append('valor', valor);
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) { mostrarGuardado(); } else { mostrarError(); }
    })
    .catch(function() { mostrarError(); });
}

// ============================================================
// BUSCADOR DE PRODUCTOS
// ============================================================
function abrirBuscadorProductos() {
    document.getElementById('modalBuscador').style.display = 'block';
    document.getElementById('txBuscarProd').value = '';
    document.getElementById('txBuscarProd').focus();
    buscarProductos();
}
function cerrarBuscador() {
    document.getElementById('modalBuscador').style.display = 'none';
}
function buscarProductos() {
    var texto = document.getElementById('txBuscarProd').value.trim();
    var ddCat = document.getElementById('ddCategoriaFiltro');
    var catId = ddCat ? ddCat.value : '0';
    var formData = new FormData();
    formData.append('accion', 'BUSCAR_PRODUCTOS');
    formData.append('texto', texto);
    formData.append('categoria_id', catId);
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) { renderizarProductos(data.productos); }
    });
}
function renderizarProductos(productos) {
    var container = document.getElementById('divListaProductos');
    if (productos.length === 0) {
        container.innerHTML = '<p style="padding:20px;text-align:center;color:#999;font-size:13px">No se encontraron productos</p>';
        return;
    }
    var html = '';
    productos.forEach(function(p) {
        html += '<div style="padding:10px 20px;border-bottom:1px solid #f0f0f0" onmouseover="this.style.background=\'#fafafa\'" onmouseout="this.style.background=\'transparent\'">';
        html += '<div style="display:flex;gap:10px">';
        if (p.imagen_url && p.imagen_url !== '') {
            html += '<div style="width:50px;height:50px;min-width:50px;border-radius:8px;overflow:hidden"><img src="' + p.imagen_url + '" style="width:100%;height:100%;object-fit:cover" onerror="this.parentNode.innerHTML=\'<i class=ti ti-flower style=font-size:22px;color:#E53935></i>\'"></div>';
        } else {
            html += '<div style="width:50px;height:50px;min-width:50px;border-radius:8px;background:#fafafa;display:flex;align-items:center;justify-content:center"><i class="ti ti-flower" style="font-size:22px;color:#E53935"></i></div>';
        }
        html += '<div style="flex:1">';
        html += '<div style="display:flex;justify-content:space-between;align-items:flex-start">';
        html += '<div><p style="margin:0;font-size:13px;font-weight:500">' + escapeHtml(p.nombre) + '</p>';
        html += '<p style="margin:0;font-size:10px;color:#999">' + p.sku + ' &mdash; ' + p.categoria + ' &mdash; Stock: ' + p.stock_actual + '</p></div>';
        html += '<p style="margin:0;font-size:13px;font-weight:500;color:#3B5BDB">Bs ' + p.precio_base_bs.toFixed(2) + '</p>';
        html += '</div>';
        html += '<input type="text" placeholder="Personalizacion..." style="width:100%;font-size:10px;padding:3px 6px;margin-top:5px;border:1px dashed #d0d0d0;border-radius:4px" id="pers_' + p.producto_id + '">';
        html += '<div style="display:flex;align-items:center;gap:6px;margin-top:5px">';
        html += '<button type="button" onclick="agregarProductoAlPedido(' + p.producto_id + ',\'' + escapeHtml(p.nombre).replace(/'/g, "\\'") + '\',' + p.precio_base_bs + ',' + (p.precio_base_usd || 0) + ')" ';
        html += 'style="font-size:10px;padding:3px 10px;background:#EBF0FF;color:#3B5BDB;border:1px solid #90CAF9;border-radius:8px;cursor:pointer">';
        html += '<i class="ti ti-plus" style="font-size:11px;vertical-align:-1px"></i> Agregar</button></div>';
        html += '</div></div></div>';
    });
    container.innerHTML = html;
}

// ============================================================
// AGREGAR PRODUCTO AL PEDIDO
// ============================================================
function agregarProductoAlPedido(productoId, nombre, precioBs, precioUsd) {
    var persEl = document.getElementById('pers_' + productoId);
    var persTexto = persEl ? persEl.value.trim() : '';
    insertarProducto(productoId, nombre, precioBs, precioUsd, persTexto, false);
}
function agregarPersonalizado() {
    var nombre = document.getElementById('txPersNombre').value.trim();
    var precio = parseFloat(document.getElementById('txPersPrecio').value) || 0;
    var detalle = document.getElementById('txPersDetalle').value.trim();
    if (nombre === '') { alert('Ingrese nombre del producto'); return; }
    if (precio <= 0) { alert('Ingrese un precio válido'); return; }
    insertarProducto(0, nombre, precio, 0, detalle, true);
}
function insertarProducto(productoId, nombre, precioBs, precioUsd, personalizacion, esPersonalizado) {
    if (prepedidoEntregaId === 0) { alert('Borrador no inicializado'); return; }
    var formData = new FormData();
    formData.append('accion', 'AGREGAR_PRODUCTO');
    formData.append('prepedido_entrega_id', prepedidoEntregaId);
    formData.append('producto_id', productoId);
    formData.append('es_personalizado', esPersonalizado ? '1' : '0');
    formData.append('nombre_producto', nombre);
    formData.append('precio_bs', precioBs);
    formData.append('precio_usd', precioUsd);
    formData.append('cantidad', '1');
    formData.append('personalizacion', personalizacion);
    mostrarGuardando();
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) {
            agregarFilaProducto(data.detalle_id, nombre, precioBs, personalizacion, esPersonalizado);
            mostrarGuardado();
            if (esPersonalizado) {
                document.getElementById('txPersNombre').value = '';
                document.getElementById('txPersPrecio').value = '';
                document.getElementById('txPersDetalle').value = '';
            }
        } else { alert('Error: ' + data.msg); }
    });
}
function agregarFilaProducto(detalleId, nombre, precio, personalizacion, esPersonalizado) {
    var container = document.getElementById('divProductos');
    var div = document.createElement('div');
    if (esPersonalizado) {
        div.className = 'ea-prod-row personalizado';
        div.setAttribute('data-precio', precio);
        div.setAttribute('data-cantidad', 1);
        div.innerHTML = '<div><span class="ea-prod-name">Producto Personalizado <span style="font-size:9px;color:#F57F17">WC#7076</span></span>' +
            '<span class="ea-prod-custom">' + escapeHtml(personalizacion) + '</span>' +
            '<div style="display:flex;align-items:center;gap:6px;margin-top:3px"><span style="font-size:10px;color:#999">Cant:</span>' +
            '<input type="number" value="1" min="1" style="width:45px;text-align:center;padding:2px;font-size:11px;border:1px solid #FFE082;border-radius:4px" onchange="actualizarDetalle(' + detalleId + ',\'cantidad\',this.value)"></div></div>' +
            '<input type="number" value="' + precio.toFixed(2) + '" step="0.01" style="width:75px;text-align:center;padding:3px;font-size:12px;border:1px solid #FFE082;border-radius:4px" onchange="actualizarDetalle(' + detalleId + ',\'precio\',this.value)">' +
            '<button type="button" style="border:none;background:none;color:#E53935;cursor:pointer;font-size:14px;padding:0" onclick="eliminarDetalle(' + detalleId + ',this)"><i class="ti ti-trash"></i></button>';
    } else {
        div.className = 'ea-prod-row';
        div.setAttribute('data-precio', precio);
        div.setAttribute('data-cantidad', 1);
        div.innerHTML = '<div><span class="ea-prod-name">' + escapeHtml(nombre) + '</span>' +
            (personalizacion ? '<span class="ea-prod-detail"><span>' + escapeHtml(personalizacion) + '</span></span>' : '') +
            '</div><span style="font-weight:500">Bs ' + precio.toFixed(2) + '</span>' +
            '<button type="button" style="border:none;background:none;color:#E53935;cursor:pointer;font-size:14px;padding:0" onclick="eliminarDetalle(' + detalleId + ',this)"><i class="ti ti-trash"></i></button>';
    }
    container.appendChild(div);
    actualizarConteoItems();
    calcularSubtotal();
}

// ============================================================
// ELIMINAR / ACTUALIZAR DETALLE
// ============================================================
function eliminarDetalle(detalleId, btn) {
    if (!confirm('¿Eliminar este producto?')) return;
    var formData = new FormData();
    formData.append('accion', 'ELIMINAR_DETALLE');
    formData.append('detalle_id', detalleId);
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) { if (data.ok) { btn.closest('.ea-prod-row').remove(); actualizarConteoItems(); calcularSubtotal(); mostrarGuardado(); } });
}
function actualizarDetalle(detalleId, campo, valor) {
    var row = document.querySelector('.ea-prod-row[data-detalle-id="' + detalleId + '"]');
    if (!row) { var btns = document.querySelectorAll('.ea-prod-row'); btns.forEach(function(r) { if (r.querySelector('[onchange*="' + detalleId + '"]')) row = r; }); }
    if (row) {
        if (campo === 'precio') { row.setAttribute('data-precio', valor); }
        if (campo === 'cantidad') { row.setAttribute('data-cantidad', valor); }
        calcularSubtotal();
    }
    var formData = new FormData();
    formData.append('accion', 'ACTUALIZAR_DETALLE');
    formData.append('detalle_id', detalleId);
    formData.append('campo', campo);
    formData.append('valor', valor);
    mostrarGuardando();
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function() { mostrarGuardado(); });
}

// ============================================================
// PAGOS
// ============================================================
function abrirModalPago() {
    document.getElementById('modalPago').style.display = 'block';
    recalcularConversion();
}
function cerrarModalPago() { document.getElementById('modalPago').style.display = 'none'; }

// Muestra "equivale a X" cuando el usuario tipea el monto
function recalcularConversion() {
    var moneda = document.getElementById('ddPagoMoneda').value;
    var monto = parseFloat(document.getElementById('txPagoMonto').value) || 0;
    var tasa = parseFloat(document.getElementById('txPagoTasa').value) || 0;
    var div = document.getElementById('divConversion');
    var span = document.getElementById('spanConversion');

    if (monto <= 0 || tasa <= 0) {
        div.style.display = 'none';
        return;
    }
    if (moneda === 'BOB') {
        var equivUsd = monto / tasa;
        span.textContent = '$ ' + equivUsd.toFixed(2) + ' USD';
    } else {
        var equivBs = monto * tasa;
        span.textContent = 'Bs ' + equivBs.toFixed(2);
    }
    div.style.display = 'block';
}

function guardarPago() {
    var metodo = document.getElementById('ddPagoMetodo').value;
    var tipoPago = document.getElementById('ddPagoTipo').value || 'TOTAL';
    var moneda = document.getElementById('ddPagoMoneda').value;
    var monto = parseFloat(document.getElementById('txPagoMonto').value) || 0;
    var tasa = parseFloat(document.getElementById('txPagoTasa').value) || 0;
    var ref = document.getElementById('txPagoRef').value;
    var obs = document.getElementById('txPagoObs').value;
    var estadoEl = document.querySelector('input[name="pagoEstado"]:checked');
    var estado = estadoEl ? estadoEl.value : 'PENDIENTE';

    if (metodo === '') { alert('Seleccione metodo de pago'); return; }
    if (monto <= 0) { alert('Ingrese monto valido'); return; }
    if (tasa <= 0) { alert('Tasa de cambio invalida'); return; }
    if (prepedidoEntregaId === 0) { alert('Borrador no inicializado'); return; }

    // Calcular monto_bs y monto_usd con conversion automatica
    var montoBs, montoUsd;
    if (moneda === 'BOB') {
        montoBs = monto;
        montoUsd = monto / tasa;
    } else {
        montoUsd = monto;
        montoBs = monto * tasa;
    }

    var formData = new FormData();
    formData.append('accion', 'AGREGAR_PAGO');
    formData.append('prepedido_entrega_id', prepedidoEntregaId);
    formData.append('tipo_pago', tipoPago);
    formData.append('metodo_pago', metodo);
    formData.append('monto_bs', montoBs.toFixed(2));
    formData.append('monto_usd', montoUsd.toFixed(2));
    formData.append('referencia', ref);
    formData.append('observaciones', obs);
    formData.append('estado', estado);

    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) {
        if (data.ok) {
            var hoy = new Date();
            var fecha = (hoy.getDate()<10?'0':'') + hoy.getDate() + '/' + ((hoy.getMonth()+1)<10?'0':'') + (hoy.getMonth()+1);

            // Texto principal del monto (priorizar moneda original elegida)
            var textoMonto;
            if (moneda === 'BOB') {
                textoMonto = 'Bs ' + montoBs.toFixed(2);
                if (montoUsd > 0) textoMonto += ' / $ ' + montoUsd.toFixed(2);
            } else {
                textoMonto = '$ ' + montoUsd.toFixed(2);
                if (montoBs > 0) textoMonto += ' / Bs ' + montoBs.toFixed(2);
            }

            // Icono segun estado
            var iconoHtml;
            if (estado === 'VERIFICADO') {
                iconoHtml = '<i class="ti ti-check" style="font-size:14px;color:#2E7D32"></i>';
            } else if (estado === 'RECHAZADO') {
                iconoHtml = '<i class="ti ti-x" style="font-size:14px;color:#E53935"></i>';
            } else {
                iconoHtml = '<i class="ti ti-clock" style="font-size:14px;color:#F9A825"></i>';
            }

            var container = document.getElementById('divPagos');
            var div = document.createElement('div');
            div.className = 'ea-pago-row';
            div.innerHTML =
                '<span>' + metodo + ' <span style="font-size:10px;color:#999">(' + tipoPago + ')</span></span>' +
                '<span style="font-weight:500">' + textoMonto + '</span>' +
                '<span style="color:#999;font-size:11px">' + estado + '</span>' +
                '<span style="font-size:11px;color:#999">' + fecha + '</span>' +
                '<span>' + iconoHtml + '</span>' +
                '<button type="button" style="border:none;background:none;color:#E53935;cursor:pointer;font-size:13px;padding:0" onclick="eliminarPago(' + data.pago_id + ',this)"><i class="ti ti-trash"></i></button>';
            container.appendChild(div);

            cerrarModalPago();
            // Limpiar campos
            document.getElementById('ddPagoMetodo').value = '';
            document.getElementById('ddPagoTipo').value = 'TOTAL';
            document.getElementById('txPagoMonto').value = '';
            document.getElementById('txPagoRef').value = '';
            document.getElementById('txPagoObs').value = '';
            var radioDefault = document.querySelector('input[name="pagoEstado"][value="PENDIENTE"]');
            if (radioDefault) radioDefault.checked = true;
            document.getElementById('divConversion').style.display = 'none';
        } else {
            alert('Error al guardar pago: ' + (data.msg || 'desconocido'));
        }
    })
    .catch(function() { alert('Error de red al guardar pago'); });
}
function eliminarPago(pagoId, btn) {
    if (!confirm('¿Eliminar este pago?')) return;
    var formData = new FormData();
    formData.append('accion', 'ELIMINAR_PAGO');
    formData.append('pago_id', pagoId);
    fetch('Entrega_Handler.ashx', { method: 'POST', body: formData })
    .then(function(r) { return r.json(); })
    .then(function(data) { if (data.ok) { btn.closest('.ea-pago-row').remove(); } });
}

// ============================================================
// CALCULAR SUBTOTAL
// ============================================================
function calcularSubtotal() {
    var filas = document.querySelectorAll('.ea-prod-row');
    var subtotal = 0;
    filas.forEach(function(fila) {
        var precio = parseFloat(fila.getAttribute('data-precio')) || 0;
        var cantidad = parseFloat(fila.getAttribute('data-cantidad')) || 1;
        subtotal += precio * cantidad;
    });
    document.getElementById('spanSubtotal').textContent = 'Bs ' + subtotal.toFixed(2);
    var resSubtotal = document.getElementById('resSubtotal');
    if (resSubtotal) resSubtotal.textContent = 'Bs ' + subtotal.toFixed(2);

    // Envio de zona
    var costoEnvio = 0;
    var hdZonaId = document.getElementById('hdZonaId');
    if (hdZonaId && hdZonaId.value) {
        var zid = parseInt(hdZonaId.value);
        zonasData.forEach(function(z) { if (z.zona_id === zid) costoEnvio = z.precio_bs; });
    }
    var resEnvio = document.getElementById('resEnvio');
    if (resEnvio) resEnvio.textContent = 'Bs ' + costoEnvio.toFixed(2);

    // Recargo horario
    var recargoHorario = 0;
    var ddSlot = document.getElementById('ddSlot');
    if (ddSlot && ddSlot.value) {
        var sid = parseInt(ddSlot.value);
        slotsData.forEach(function(s) { if (s.slot_id === sid) recargoHorario = s.recargo_bs; });
    }
    var resRH = document.getElementById('resRecargoHorario');
    if (resRH) resRH.textContent = 'Bs ' + recargoHorario.toFixed(2);

    // Express
    var recargoExpress = 0;
    var chkExpress = document.getElementById('chkExpress');
    if (chkExpress && chkExpress.checked) recargoExpress = 50;
    var resRE = document.getElementById('resRecargoExpress');
    if (resRE) resRE.textContent = 'Bs ' + recargoExpress.toFixed(2);

    // Descuento
    var descuento = parseFloat(document.getElementById('txDescuento').value) || 0;

    // Total
    var total = subtotal + costoEnvio + recargoHorario + recargoExpress - descuento;
    var resTotal = document.getElementById('resTotal');
    if (resTotal) resTotal.textContent = 'Bs ' + total.toFixed(2);

    // Pago total
    var pagoTotal = document.getElementById('pagoTotal');
    if (pagoTotal) pagoTotal.textContent = 'Bs ' + total.toFixed(2);
}

// ============================================================
// WHATSAPP COTIZACIÓN
// ============================================================
function enviarCotizacionWsp() {
    var filas = document.querySelectorAll('.ea-prod-row');
    if (filas.length === 0) { alert('Agregue al menos un producto'); return; }

    var cliente = '<%=ClienteNombre%>';
    var celular = '<%=ClienteCelular%>';
    var subtotal = 0;
    var lineas = '';

    filas.forEach(function(fila) {
        var nombre = fila.querySelector('.ea-prod-name');
        var precio = parseFloat(fila.getAttribute('data-precio')) || 0;
        var cantidad = parseFloat(fila.getAttribute('data-cantidad')) || 1;
        var sub = precio * cantidad;
        subtotal += sub;
        if (nombre) {
            lineas += '- ' + nombre.textContent.trim() + (cantidad > 1 ? ' x' + cantidad : '') + ' - Bs ' + sub.toFixed(2) + '\n';
        }
    });

    var descuento = parseFloat(document.getElementById('txDescuento').value) || 0;

    // Obtener costo envio de la zona seleccionada
    var costoEnvio = 0;
    var zonaTexto = '';
    var hdZonaId = document.getElementById('hdZonaId');
    if (hdZonaId && hdZonaId.value) {
        var zid = parseInt(hdZonaId.value);
        zonasData.forEach(function(z) {
            if (z.zona_id === zid) { costoEnvio = z.precio_bs; zonaTexto = z.nombre; }
        });
    }

    // Recargo por horario (slot)
    var recargoHorario = 0;
    var horarioTexto = '';
    var ddSlot = document.getElementById('ddSlot');
    if (ddSlot && ddSlot.value) {
        var sid = parseInt(ddSlot.value);
        slotsData.forEach(function(s) {
            if (s.slot_id === sid) {
                recargoHorario = s.recargo_bs;
                horarioTexto = s.etiqueta;
            }
        });
    }

    // Recargo express
    var recargoExpress = 0;
    var chkExpress = document.getElementById('chkExpress');
    if (chkExpress && chkExpress.checked) recargoExpress = 50;

    var total = subtotal + costoEnvio + recargoHorario + recargoExpress - descuento;

    var mensaje = '*Miss Flores - Cotizacion*\n\n';
    mensaje += lineas + '\n';
    mensaje += 'Subtotal: Bs ' + subtotal.toFixed(2) + '\n';
    if (costoEnvio > 0) {
        mensaje += 'Envio (' + zonaTexto + '): Bs ' + costoEnvio.toFixed(2) + '\n';
    }
    if (recargoHorario > 0) {
        mensaje += 'Recargo horario (' + horarioTexto + '): Bs ' + recargoHorario.toFixed(2) + '\n';
    }
    if (recargoExpress > 0) {
        mensaje += 'Recargo express: Bs ' + recargoExpress.toFixed(2) + '\n';
    }
    if (descuento > 0) {
        mensaje += 'Descuento: -Bs ' + descuento.toFixed(2) + '\n';
    }
    mensaje += '*Total: Bs ' + total.toFixed(2) + '*';

    // Limpiar número de celular
    var numLimpio = celular.replace(/[^0-9]/g, '');
    if (numLimpio.length === 8 && (numLimpio.startsWith('6') || numLimpio.startsWith('7'))) {
        numLimpio = '591' + numLimpio;
    }
    if (!numLimpio.startsWith('591') && numLimpio.length < 10) {
        numLimpio = '591' + numLimpio;
    }

    var url = 'https://wa.me/' + numLimpio + '?text=' + encodeURIComponent(mensaje);
    window.open(url, '_blank');
}
function enviarLinkCliente() { alert('Enviar link al cliente - En desarrollo'); }
function verificarLink() { location.reload(); }
function crearPedidoWC() { alert('Crear pedido en WooCommerce - En desarrollo'); }
function seleccionarSucursalRecojo(id) { guardarCampo('sucursal_id', id); }

// ============================================================
// UTILIDADES
// ============================================================
function mostrarGuardando() {
    var s = document.getElementById('spanGuardado');
    s.innerHTML = '<i class="ti ti-loader" style="font-size:13px"></i> Guardando...'; s.style.color = '#999';
}
function mostrarGuardado() {
    var s = document.getElementById('spanGuardado');
    s.innerHTML = '<i class="ti ti-check" style="font-size:13px"></i> Guardado'; s.style.color = '#2E7D32';
}
function mostrarError() {
    var s = document.getElementById('spanGuardado');
    s.innerHTML = '<i class="ti ti-x" style="font-size:13px"></i> Error'; s.style.color = '#E53935';
}
function actualizarConteoItems() {
    var items = document.querySelectorAll('.ea-prod-row');
    document.getElementById('spanCantItems').textContent = items.length + ' items';
}
function escapeHtml(text) {
    if (!text) return '';
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ============================================================
// INICIALIZAR
// ============================================================
document.addEventListener('DOMContentLoaded', function() {
    toggleTipoEntrega();
    filtrarZonas(true);  // preservar zona pre-cargada del servidor
    actualizarConteoItems();
    calcularSubtotal();
});
</script>
</asp:Content>
