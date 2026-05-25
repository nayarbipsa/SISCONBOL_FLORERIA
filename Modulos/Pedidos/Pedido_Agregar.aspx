<%@ Page Title="Agregar Pedido" Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Pedido_Agregar.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_Pedido_Agregar" %>

<asp:Content ID="ContentHead" ContentPlaceHolderID="HeadContent" runat="server">
<style>
.form-section {
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 12px;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
}
.form-section-title {
    font-size: 16px;
    font-weight: 500;
    margin: 0 0 1rem 0;
    padding-bottom: 0.75rem;
    border-bottom: 2px solid #e0e0e0;
    display: flex;
    align-items: center;
    gap: 0.5rem;
}
.form-row {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 1rem;
    margin-bottom: 1rem;
}
.form-row-2 {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
    margin-bottom: 1rem;
}
.productos-section {
    background: #fafafa;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    padding: 1rem;
    margin-bottom: 1rem;
}
.producto-item {
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    padding: 1rem;
    margin-bottom: 0.75rem;
    display: flex;
    gap: 1rem;
    align-items: start;
}
.producto-item:last-child {
    margin-bottom: 0;
}
.producto-select {
    flex: 2;
}
.producto-cantidad {
    flex: 0 0 100px;
}
.producto-precio {
    flex: 1;
    text-align: right;
}
.producto-delete {
    flex: 0 0 auto;
}
.precio-info {
    font-size: 13px;
    color: #757575;
    margin-top: 0.25rem;
}
.subtotal-info {
    font-size: 15px;
    font-weight: 500;
    color: #667eea;
    margin-top: 0.25rem;
}
.totales-preview {
    background: rgba(102,126,234,0.1);
    border: 1px solid rgba(102,126,234,0.2);
    border-radius: 8px;
    padding: 1rem;
    margin-top: 1rem;
}
.total-line {
    display: flex;
    justify-content: space-between;
    padding: 0.5rem 0;
}
.total-line.main {
    border-top: 2px solid rgba(102,126,234,0.3);
    padding-top: 0.75rem;
    margin-top: 0.5rem;
    font-size: 18px;
    font-weight: 500;
    color: #667eea;
}
</style>
</asp:Content>

<asp:Content ID="ContentTitle" ContentPlaceHolderID="PageTitleContent" runat="server">
    <i class="ti ti-plus" style="vertical-align:-2px"></i> Agregar Pedido
</asp:Content>

<asp:Content ID="ContentMain" ContentPlaceHolderID="MainContent" runat="server">

<div class="alerta" id="divAlerta"><%=MensajeAlerta%></div>

<!-- INFO DEL PRE-PEDIDO -->
<div class="panel">
    <div class="panel-body">
        <div style="display: flex; align-items: center; gap: 1rem;">
            <div style="flex: 1;">
                <div style="font-size: 13px; color: #757575; margin-bottom: 0.25rem;">Agregando pedido a:</div>
                <div style="font-size: 16px; font-weight: 500;"><%=PrePedidoCodigo%> - <%=ClienteNombre%></div>
            </div>
            <button type="button" class="btn" onclick="window.location.href='PrePedido_Detalle.aspx?id=<%=PrePedidoId%>'">
                <i class="ti ti-arrow-left"></i>
                Volver
            </button>
        </div>
    </div>
</div>

<!-- FORMULARIO -->
<!-- form ya existe en Site.Master -->

<!-- DATOS DEL RECEPTOR -->
<div class="form-section">
    <h3 class="form-section-title">
        <i class="ti ti-user"></i>
        Datos del receptor
    </h3>

    <div class="form-row-2">
        <div class="form-group">
            <label class="form-label required">Para quien es</label>
            <input type="text" name="txReceptor" class="form-control" 
                   placeholder="Ej: Para mama Rosa" 
                   value="<%=ValorReceptor%>" 
                   maxlength="100" />
            <div class="form-help">Nombre de la persona que recibira</div>
        </div>

        <div class="form-group">
            <label class="form-label required">Celular receptor</label>
            <input type="text" name="txCelularReceptor" class="form-control" 
                   placeholder="71234567" 
                   value="<%=ValorCelularReceptor%>" 
                   maxlength="20" />
        </div>
    </div>
</div>

<!-- ENTREGA -->
<div class="form-section">
    <h3 class="form-section-title">
        <i class="ti ti-truck-delivery"></i>
        Datos de la entrega
    </h3>

    <div class="form-row">
        <div class="form-group">
            <label class="form-label required">Fecha de entrega</label>
            <input type="date" name="txFecha" class="form-control" 
                   value="<%=ValorFecha%>" 
                   min="<%=FechaMinima%>" />
            <div class="form-help">Minimo HOY + 2 dias</div>
        </div>

        <div class="form-group">
            <label class="form-label required">Horario</label>
            <select name="selHorario" class="form-control">
                <option value="">Seleccionar...</option>
                <option value="08:00-12:00">8:00 - 12:00 (Manana)</option>
                <option value="12:00-16:00">12:00 - 16:00 (Tarde)</option>
                <option value="16:00-20:00">16:00 - 20:00 (Noche)</option>
            </select>
        </div>

        <div class="form-group">
            <label class="form-label required">Tipo de entrega</label>
            <select name="selTipoEntrega" class="form-control" onchange="cambioTipoEntrega()">
                <option value="DOMICILIO">Envio a domicilio</option>
                <option value="RECOJO">Recojo en sucursal</option>
            </select>
        </div>
    </div>

    <div id="divDomicilio">
        <div class="form-row-2">
            <div class="form-group">
                <label class="form-label required">Zona de entrega</label>
                <select name="selZona" class="form-control" onchange="cambioZona()">
                    <option value="">Seleccionar zona...</option>
                    <%=HtmlZonas%>
                </select>
            </div>

            <div class="form-group">
                <label class="form-label">Costo de envio</label>
                <input type="text" id="txCostoEnvio" class="form-control" readonly value="0.00" />
                <div class="form-help">Se calcula segun la zona</div>
            </div>
        </div>

        <div class="form-group">
            <label class="form-label required">Direccion exacta</label>
            <input type="text" name="txDireccion" class="form-control" 
                   placeholder="Calle, numero, edificio, referencia..." 
                   value="<%=ValorDireccion%>" />
        </div>
    </div>

    <div id="divRecojo" style="display:none;">
        <div class="form-group">
            <label class="form-label required">Sucursal</label>
            <select name="selSucursal" class="form-control">
                <option value="">Seleccionar sucursal...</option>
                <%=HtmlSucursales%>
            </select>
        </div>
    </div>

    <div class="form-group">
        <label class="form-label">Mensaje en tarjeta</label>
        <textarea name="txMensaje" class="form-control" 
                  rows="3" 
                  placeholder="Escribe el mensaje que ira en la tarjeta..."><%=ValorMensaje%></textarea>
    </div>
</div>

<!-- PRODUCTOS -->
<div class="form-section">
    <h3 class="form-section-title">
        <i class="ti ti-shopping-cart"></i>
        Productos
    </h3>

    <div class="productos-section" id="divProductos">
        <!-- Los productos se agregan dinámicamente con JavaScript -->
    </div>

    <button type="button" class="btn btn-primary btn-sm" onclick="agregarProducto()">
        <i class="ti ti-plus"></i>
        Agregar producto
    </button>

    <!-- TOTALES PREVIEW -->
    <div class="totales-preview">
        <div class="total-line">
            <span>Subtotal productos:</span>
            <span id="spanSubtotal">0.00 Bs</span>
        </div>
        <div class="total-line">
            <span>Costo de envio:</span>
            <span id="spanEnvio">0.00 Bs</span>
        </div>
        <div class="total-line main">
            <span>TOTAL PEDIDO:</span>
            <span id="spanTotal">0.00 Bs</span>
        </div>
    </div>
</div>

<!-- ACCIONES -->
<div class="panel">
    <div class="panel-body">
        <div style="display: flex; gap: 10px; justify-content: flex-end;">
            <button type="button" class="btn" onclick="window.location.href='PrePedido_Detalle.aspx?id=<%=PrePedidoId%>'">
                <i class="ti ti-x"></i>
                Cancelar
            </button>
            <button type="button" class="btn btn-primary" onclick="guardarPedido()">
                <i class="ti ti-device-floppy"></i>
                Guardar pedido
            </button>
        </div>
    </div>
</div>

<!-- Hidden fields -->
<input type="hidden" id="hdAccion" name="hdAccion" value="" />
<input type="hidden" id="hdProductosJson" name="hdProductosJson" value="[]" />
<asp:Button ID="btnAccion" runat="server" OnClick="btnAccion_Click" style="display:none;" />

<!-- form cierra en Site.Master -->

</asp:Content>

<asp:Content ID="ContentScripts" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

var productos = [];
var contadorProductos = 0;
var catalogoProductos = <%=ProductosJson%>;
var zonasData = <%=ZonasJson%>;

function cambioTipoEntrega() {
    var tipo = document.querySelector('[name="selTipoEntrega"]').value;
    var divDom = document.getElementById('divDomicilio');
    var divRec = document.getElementById('divRecojo');
    
    if (tipo === 'RECOJO') {
        divDom.style.display = 'none';
        divRec.style.display = 'block';
        document.getElementById('txCostoEnvio').value = '0.00';
    } else {
        divDom.style.display = 'block';
        divRec.style.display = 'none';
    }
    calcularTotales();
}

function cambioZona() {
    var zonaId = document.querySelector('[name="selZona"]').value;
    var costo = 0;
    
    if (zonaId) {
        var zona = zonasData.find(function(z) { return z.id == zonaId; });
        if (zona) {
            costo = zona.costo;
        }
    }
    
    document.getElementById('txCostoEnvio').value = costo.toFixed(2);
    calcularTotales();
}

function agregarProducto() {
    contadorProductos++;
    var id = 'prod_' + contadorProductos;
    
    var html = '<div class="producto-item" id="' + id + '">';
    html += '  <div class="producto-select">';
    html += '    <select class="form-control" onchange="cambioProducto(\'' + id + '\', this.value)">';
    html += '      <option value="">Seleccionar producto...</option>';
    
    for (var i = 0; i < catalogoProductos.length; i++) {
        var p = catalogoProductos[i];
        html += '<option value="' + p.id + '" data-precio="' + p.precio + '">';
        html += p.nombre + ' - ' + p.precio.toFixed(2) + ' Bs';
        html += '</option>';
    }
    
    html += '    </select>';
    html += '  </div>';
    html += '  <div class="producto-cantidad">';
    html += '    <input type="number" class="form-control" min="1" value="1" onchange="cambioProducto(\'' + id + '\', null)" />';
    html += '  </div>';
    html += '  <div class="producto-precio">';
    html += '    <div class="precio-info">Precio: <span class="precio-unit">0.00</span> Bs</div>';
    html += '    <div class="subtotal-info">Subtotal: <span class="subtotal-prod">0.00</span> Bs</div>';
    html += '  </div>';
    html += '  <div class="producto-delete">';
    html += '    <button type="button" class="btn btn-icon" onclick="eliminarProducto(\'' + id + '\')">';
    html += '      <i class="ti ti-trash"></i>';
    html += '    </button>';
    html += '  </div>';
    html += '</div>';
    
    document.getElementById('divProductos').insertAdjacentHTML('beforeend', html);
}

function cambioProducto(id, productoId) {
    var div = document.getElementById(id);
    var select = div.querySelector('select');
    var inputCant = div.querySelector('input[type="number"]');
    var spanPrecio = div.querySelector('.precio-unit');
    var spanSubtotal = div.querySelector('.subtotal-prod');
    
    var prodId = productoId || select.value;
    var cantidad = parseInt(inputCant.value) || 1;
    var precio = 0;
    
    if (prodId) {
        var prod = catalogoProductos.find(function(p) { return p.id == prodId; });
        if (prod) {
            precio = prod.precio;
        }
    }
    
    var subtotal = precio * cantidad;
    
    spanPrecio.textContent = precio.toFixed(2);
    spanSubtotal.textContent = subtotal.toFixed(2);
    
    calcularTotales();
}

function eliminarProducto(id) {
    var div = document.getElementById(id);
    if (div) {
        div.remove();
        calcularTotales();
    }
}

function calcularTotales() {
    var subtotal = 0;
    var items = document.querySelectorAll('.producto-item');
    
    items.forEach(function(item) {
        var span = item.querySelector('.subtotal-prod');
        if (span) {
            subtotal += parseFloat(span.textContent) || 0;
        }
    });
    
    var envio = parseFloat(document.getElementById('txCostoEnvio').value) || 0;
    var total = subtotal + envio;
    
    document.getElementById('spanSubtotal').textContent = subtotal.toFixed(2) + ' Bs';
    document.getElementById('spanEnvio').textContent = envio.toFixed(2) + ' Bs';
    document.getElementById('spanTotal').textContent = total.toFixed(2) + ' Bs';
}

function guardarPedido() {
    // Recopilar productos
    var prods = [];
    var items = document.querySelectorAll('.producto-item');
    
    items.forEach(function(item) {
        var select = item.querySelector('select');
        var inputCant = item.querySelector('input[type="number"]');
        
        if (select.value) {
            prods.push({
                producto_id: parseInt(select.value),
                cantidad: parseInt(inputCant.value) || 1
            });
        }
    });
    
    if (prods.length === 0) {
        alert('Debes agregar al menos un producto');
        return;
    }
    
    // Guardar en hidden field
    document.getElementById('hdProductosJson').value = JSON.stringify(prods);
    document.getElementById('hdAccion').value = 'GUARDAR';
    
    // Submit
    document.getElementById('<%=btnAccion.ClientID%>').click();
}

// Inicializar
window.addEventListener('load', function() {
    agregarProducto(); // Agregar primer producto
});
</script>
</asp:Content>
