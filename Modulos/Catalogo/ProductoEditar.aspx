<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="ProductoEditar.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Catalogo_ProductoEditar" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    SISCONBOL - Editar Producto
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    <span id="spTitulo">Producto</span>
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

<div class="alerta" id="divAlerta"></div>

<input type="hidden" id="hdProductoId" name="hdProductoId" value="0"/>
<input type="hidden" id="hdNombre" name="hdNombre" value=""/>
<input type="hidden" id="hdDesc" name="hdDesc" value=""/>
<input type="hidden" id="hdPrecioBS" name="hdPrecioBS" value=""/>
<input type="hidden" id="hdPromoActiva" name="hdPromoActiva" value="0"/>
<input type="hidden" id="hdPromoBS" name="hdPromoBS" value=""/>
<input type="hidden" id="hdPromoDesde" name="hdPromoDesde" value=""/>
<input type="hidden" id="hdPromoHasta" name="hdPromoHasta" value=""/>
<input type="hidden" id="hdActivo" name="hdActivo" value="1"/>
<input type="hidden" id="hdImagenBase64" name="hdImagenBase64" value=""/>
<input type="hidden" id="hdImagenNombre" name="hdImagenNombre" value=""/>
<input type="hidden" id="hdAccion" name="hdAccion" value=""/>

<asp:Button ID="btnGuardar" runat="server" Text="" Style="display:none" OnClick="btnGuardar_Click"/>
<asp:Button ID="btnSincronizar" runat="server" Text="" Style="display:none" OnClick="btnSincronizar_Click"/>

<div class="grid-editor">
  
  <div class="grid-editor-main">
    
    <div class="panel">
      <div class="panel-head"><span class="panel-title">Información general</span></div>
      <div class="panel-body">
        
        <div class="form-group">
          <label class="form-label">Nombre del producto <span class="req">*</span></label>
          <input type="text" id="txNombre" class="form-control" maxlength="200" placeholder="Ej: Ramo de 12 rosas rojas"/>
          <div class="form-error" id="errNombre">El nombre es obligatorio</div>
        </div>
        
        <div class="form-row form-row-2">
          <div class="form-group">
            <label class="form-label">Precio Bs <span class="req">*</span></label>
            <input type="number" id="txPrecioBS" class="form-control" min="0" step="0.01" placeholder="0.00" oninput="calcPromo()"/>
            <div class="form-error" id="errPrecio">Precio obligatorio y mayor a 0</div>
          </div>
          
          <div class="form-group">
            <label class="form-label">
              <input type="checkbox" id="chkActivo" checked style="margin-right:6px"/>
              Producto activo
            </label>
          </div>
        </div>
        
        <div class="form-group">
          <label class="form-label">Descripción</label>
          <textarea id="txDesc" class="form-control" rows="4" placeholder="Describe el producto (opcional)"></textarea>
        </div>
        
      </div>
    </div>
    
    <div class="panel">
      <div class="panel-head">
        <span class="panel-title">Descuento</span>
        <label class="form-label-inline">
          <input type="checkbox" id="chkPromo" onchange="togglePromo()"/> Activar descuento
        </label>
      </div>
      <div class="panel-body">
        <div class="promo-box inactivo" id="promoBox">
          <div class="form-row form-row-3">
            <div class="form-group">
              <label class="form-label">Precio con descuento <span class="req">*</span></label>
              <input type="number" id="txPromoBS" class="form-control" min="0" step="0.01" placeholder="0.00" oninput="calcPromo()"/>
              <div class="form-error" id="errPromo">Debe ser menor al precio base</div>
            </div>
            <div class="form-group">
              <label class="form-label">Desde <span class="req">*</span></label>
              <input type="date" id="txPromoDesde" class="form-control"/>
              <div class="form-error" id="errPromoDesde">Fecha obligatoria</div>
            </div>
            <div class="form-group">
              <label class="form-label">Hasta <span class="req">*</span></label>
              <input type="date" id="txPromoHasta" class="form-control"/>
              <div class="form-error" id="errPromoHasta">Fecha obligatoria</div>
            </div>
          </div>
          <div id="promoResumen" class="promo-resumen"></div>
        </div>
      </div>
    </div>
    
  </div>
  
  <div class="grid-editor-side">
    
    <div class="panel">
      <div class="panel-head"><span class="panel-title">Imagen del producto</span></div>
      <div class="panel-body">
        
        <div id="divImgPreview" style="display:none;margin-bottom:10px">
          <img id="imgPreview" class="img-preview" src="" alt="Preview"/>
        </div>
        
        <div class="img-placeholder" id="divImgPlaceholder" onclick="document.getElementById('fileImagen').click()">
          <i class="ti ti-photo" style="font-size:32px"></i>
          <span style="font-weight:500">Subir imagen</span>
          <span style="font-size:11px;color:#9e9e9e">JPG, PNG o WEBP · Max 2MB</span>
        </div>
        
        <input type="file" id="fileImagen" accept="image/jpeg,image/png,image/webp" style="display:none" onchange="cargarImagen(this)"/>
        
        <div style="margin-top:8px;display:flex;gap:8px">
          <button type="button" class="btn-link" id="btnCambiarImg" style="display:none" onclick="document.getElementById('fileImagen').click()">
            <i class="ti ti-edit"></i> Cambiar
          </button>
          <button type="button" class="btn-link btn-link-danger" id="btnQuitarImg" style="display:none" onclick="quitarImagen()">
            <i class="ti ti-trash"></i> Quitar
          </button>
        </div>
        
      </div>
    </div>
    
    <div class="panel">
      <div class="panel-head"><span class="panel-title">WooCommerce</span></div>
      <div class="panel-body">
        <div id="divWcInfo">
          <p style="font-size:12px;color:#757575">Guarda el producto primero para sincronizar</p>
        </div>
        <div style="margin-top:12px">
          <button type="button" class="btn btn-secondary btn-block" id="btnSincWc" onclick="sincronizarWc()" disabled>
            <i class="ti ti-refresh"></i> Sincronizar con WooCommerce
          </button>
        </div>
      </div>
    </div>
    
  </div>
  
</div>

<div class="footer-sticky">
  <button type="button" class="btn btn-secondary" onclick="window.location.href='Productos.aspx'">
    <i class="ti ti-arrow-left"></i> Volver
  </button>
  <button type="button" class="btn btn-primary" id="btnGuardarForm" onclick="validarYGuardar()">
    <i class="ti ti-device-floppy"></i> Guardar
  </button>
</div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<script type="text/javascript">
// @ts-nocheck

<%= ScriptOnLoad %>

function setVal(id, val) {
    var el = document.getElementById(id);
    if (el) el.value = val || '';
}

function setHd(id, val) {
    var el = document.getElementById(id);
    if (el) el.value = val || '';
}

function setChk(id, val) {
    var el = document.getElementById(id);
    if (el) el.checked = val;
}

function togglePromo() {
    var chk = document.getElementById('chkPromo');
    var box = document.getElementById('promoBox');
    if (chk && box) {
        if (chk.checked) {
            box.classList.remove('inactivo');
        } else {
            box.classList.add('inactivo');
        }
        calcPromo();
    }
}

function calcPromo() {
    var chk = document.getElementById('chkPromo');
    var inpBase = document.getElementById('txPrecioBS');
    var inpPromo = document.getElementById('txPromoBS');
    var div = document.getElementById('promoResumen');
    
    if (!chk || !inpBase || !inpPromo || !div) return;
    
    var base = parseFloat(inpBase.value) || 0;
    var promo = parseFloat(inpPromo.value) || 0;
    
    if (!chk.checked || promo <= 0 || base <= 0 || promo >= base) {
        div.textContent = '';
        return;
    }
    
    var desc = base - promo;
    var pct = ((desc / base) * 100).toFixed(0);
    div.textContent = 'Descuento: Bs ' + desc.toFixed(2) + ' (' + pct + '%)';
}

function cargarImagen(input) {
    if (!input.files || !input.files[0]) return;
    
    var file = input.files[0];
    if (file.size > 2097152) {
        mostrarAlerta('La imagen no debe superar 2MB', 'error');
        input.value = '';
        return;
    }
    
    var reader = new FileReader();
    reader.onload = function(e) {
        var base64 = e.target.result.split(',')[1];
        var prev = document.getElementById('imgPreview');
        var divPrev = document.getElementById('divImgPreview');
        var divPlace = document.getElementById('divImgPlaceholder');
        var btnCambiar = document.getElementById('btnCambiarImg');
        var btnQuitar = document.getElementById('btnQuitarImg');
        
        if (prev) prev.src = e.target.result;
        if (divPrev) divPrev.style.display = 'block';
        if (divPlace) divPlace.style.display = 'none';
        if (btnCambiar) btnCambiar.style.display = 'inline-flex';
        if (btnQuitar) btnQuitar.style.display = 'inline-flex';
        
        setHd('hdImagenBase64', base64);
        setHd('hdImagenNombre', file.name);
    };
    reader.readAsDataURL(file);
}

function quitarImagen() {
    var prev = document.getElementById('imgPreview');
    var divPrev = document.getElementById('divImgPreview');
    var divPlace = document.getElementById('divImgPlaceholder');
    var btnCambiar = document.getElementById('btnCambiarImg');
    var btnQuitar = document.getElementById('btnQuitarImg');
    var fileInput = document.getElementById('fileImagen');
    
    if (prev) prev.src = '';
    if (divPrev) divPrev.style.display = 'none';
    if (divPlace) divPlace.style.display = 'flex';
    if (btnCambiar) btnCambiar.style.display = 'none';
    if (btnQuitar) btnQuitar.style.display = 'none';
    if (fileInput) fileInput.value = '';
    
    setHd('hdImagenBase64', '');
    setHd('hdImagenNombre', '');
}

function validarYGuardar() {
    var ok = true;
    
    var inpNom = document.getElementById('txNombre');
    var inpPrecio = document.getElementById('txPrecioBS');
    var errNom = document.getElementById('errNombre');
    var errPrecio = document.getElementById('errPrecio');
    
    if (errNom) errNom.style.display = 'none';
    if (errPrecio) errPrecio.style.display = 'none';
    
    if (!inpNom || !inpNom.value.trim()) {
        if (errNom) errNom.style.display = 'block';
        ok = false;
    }
    
    if (!inpPrecio || !inpPrecio.value.trim() || parseFloat(inpPrecio.value) <= 0) {
        if (errPrecio) errPrecio.style.display = 'block';
        ok = false;
    }
    
    var chkPromo = document.getElementById('chkPromo');
    if (chkPromo && chkPromo.checked) {
        var inpPromoBS = document.getElementById('txPromoBS');
        var inpPromoDes = document.getElementById('txPromoDesde');
        var inpPromoHas = document.getElementById('txPromoHasta');
        var errPromo = document.getElementById('errPromo');
        var errPromoDes = document.getElementById('errPromoDesde');
        var errPromoHas = document.getElementById('errPromoHasta');
        
        if (errPromo) errPromo.style.display = 'none';
        if (errPromoDes) errPromoDes.style.display = 'none';
        if (errPromoHas) errPromoHas.style.display = 'none';
        
        var promoBS = parseFloat(inpPromoBS.value) || 0;
        var precioBase = parseFloat(inpPrecio.value) || 0;
        
        if (promoBS <= 0 || promoBS >= precioBase) {
            if (errPromo) errPromo.style.display = 'block';
            ok = false;
        }
        if (!inpPromoDes || !inpPromoDes.value) {
            if (errPromoDes) errPromoDes.style.display = 'block';
            ok = false;
        }
        if (!inpPromoHas || !inpPromoHas.value) {
            if (errPromoHas) errPromoHas.style.display = 'block';
            ok = false;
        }
    }
    
    if (!ok) {
        mostrarAlerta('Completa todos los campos obligatorios', 'error');
        return;
    }
    
    var btn = document.getElementById('btnGuardarForm');
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="ti ti-loader spinner"></i> Guardando...';
    }
    
    setHd('hdNombre', inpNom.value.trim());
    
    var txDesc = document.getElementById('txDesc');
    if (txDesc) setHd('hdDesc', txDesc.value);
    
    setHd('hdPrecioBS', inpPrecio.value);
    
    if (chkPromo && chkPromo.checked) {
        setHd('hdPromoActiva', '1');
        var inpPromoBS = document.getElementById('txPromoBS');
        var inpPromoDes = document.getElementById('txPromoDesde');
        var inpPromoHas = document.getElementById('txPromoHasta');
        if (inpPromoBS) setHd('hdPromoBS', inpPromoBS.value);
        if (inpPromoDes) setHd('hdPromoDesde', inpPromoDes.value);
        if (inpPromoHas) setHd('hdPromoHasta', inpPromoHasta.value);
    } else {
        setHd('hdPromoActiva', '0');
        setHd('hdPromoBS', '');
        setHd('hdPromoDesde', '');
        setHd('hdPromoHasta', '');
    }
    
    var chkActivo = document.getElementById('chkActivo');
    setHd('hdActivo', (chkActivo && chkActivo.checked) ? '1' : '0');
    setHd('hdAccion', 'GUARDAR');
    
    document.getElementById('<%= btnGuardar.ClientID %>').click();
}

function sincronizarWc() {
    var btn = document.getElementById('btnSincWc');
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="ti ti-loader spinner"></i> Sincronizando...';
    }
    
    setHd('hdAccion', 'SINCRONIZAR');
    document.getElementById('<%= btnSincronizar.ClientID %>').click();
}

function mostrarAlerta(mensaje, tipo) {
    var div = document.getElementById('divAlerta');
    if (div) {
        div.textContent = mensaje;
        div.className = 'alerta alerta-' + tipo + ' show';
        setTimeout(function() {
            div.className = 'alerta';
        }, 5000);
    }
}

</script>
</asp:Content>
