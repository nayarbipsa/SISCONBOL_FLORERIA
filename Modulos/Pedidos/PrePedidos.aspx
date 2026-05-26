<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="PrePedidos.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos_Pedidos_PrePedidos" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Pre-Pedidos
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="PageTitleContent" runat="server">
    Pre-Pedidos
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

    <div id="divAlerta" class="alerta"></div>

    <%-- TOOLBAR --%>
    <div class="pp-toolbar">
        <input type="text" id="txBuscar" class="form-control"
               placeholder="Código, celular, nombre..."
               oninput="onBuscarInput()" style="flex:1;min-width:140px;" />
        <select id="selEstado" class="form-control" onchange="aplicarFiltros()" style="flex:0 0 auto;">
            <option value="">Todos los estados</option>
            <option value="BORRADOR">Borrador</option>
            <option value="FORM_ENVIADO">Form enviado</option>
            <option value="COMPLETADO">Completado</option>
            <option value="ESPERANDO_PAGO">Esperando pago</option>
            <option value="PAGADO">Pagado</option>
            <option value="CONVERTIDO">Convertido</option>
            <option value="CANCELADO">Cancelado</option>
        </select>
        <a href="PrePedido_Crear.aspx" class="btn btn-primary" style="flex-shrink:0;">
            <i class="ti ti-plus"></i> Nuevo
        </a>
    </div>

    <%-- TOTALIZADORES --%>
    <div class="pp-totales">
        <div class="pp-tot pp-tot-rosa">
            <div class="pp-tot-val" id="totCantidad">—</div>
            <div class="pp-tot-lbl">Pre-pedidos</div>
            <div class="pp-tot-sub">en esta vista</div>
        </div>
        <div class="pp-tot pp-tot-verde">
            <div class="pp-tot-val" id="totMonto">—</div>
            <div class="pp-tot-lbl">Monto total Bs</div>
            <div class="pp-tot-sub">suma del resultado</div>
        </div>
        <div class="pp-tot pp-tot-naranja">
            <div class="pp-tot-val" id="totUrgentes">—</div>
            <div class="pp-tot-lbl">Entrega urgente</div>
            <div class="pp-tot-sub">hoy o mañana</div>
        </div>
        <div class="pp-tot pp-tot-azul">
            <div class="pp-tot-val" id="totSinPago">—</div>
            <div class="pp-tot-lbl">Sin pago</div>
            <div class="pp-tot-sub">completados</div>
        </div>
    </div>

    <%-- LISTA --%>
    <div class="panel">
        <div id="divLista">
            <div class="pp-loading">
                <i class="ti ti-loader"></i> Cargando...
            </div>
        </div>
        <div class="panel-footer" id="divPaginacion" style="display:none;">
            <button class="btn btn-sm" id="btnAnterior" onclick="irPagina(-1)">
                <i class="ti ti-chevron-left"></i> Anterior
            </button>
            <span id="spPagina" style="font-size:13px;color:#616161;flex:1;text-align:center;"></span>
            <button class="btn btn-sm" id="btnSiguiente" onclick="irPagina(1)">
                Siguiente <i class="ti ti-chevron-right"></i>
            </button>
        </div>
    </div>

    <div id="jsonInicial" style="display:none;"><%=JsonInicial%></div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptsContent" runat="server">
<style>
.pp-toolbar{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:12px}
.pp-totales{display:grid;grid-template-columns:repeat(2,1fr);gap:8px;margin-bottom:16px}
.pp-tot{background:var(--gris-cl);padding:10px 14px;border-left:3px solid #e0e0e0;border-radius:0}
.pp-tot-rosa   {border-left-color:#C2185B}
.pp-tot-verde  {border-left-color:#388E3C}
.pp-tot-naranja{border-left-color:#E65100}
.pp-tot-azul   {border-left-color:#1565C0}
.pp-tot-val{font-size:20px;font-weight:500;color:#212121;line-height:1.1}
.pp-tot-lbl{font-size:11px;color:#757575;margin-top:2px;text-transform:uppercase;letter-spacing:.3px}
.pp-tot-sub{font-size:10px;color:#9e9e9e;margin-top:1px}

.pp-sep{padding:7px 18px 4px;font-size:11px;font-weight:500;color:#9e9e9e;text-transform:uppercase;letter-spacing:.4px;background:#fafafa;border-bottom:1px solid #f0f0f0}

.pp-fila{display:flex;align-items:center;gap:10px;padding:12px 18px 12px 15px;border-bottom:1px solid #f5f5f5;border-left:3px solid transparent;text-decoration:none;color:inherit;transition:background .1s}
.pp-fila:last-child{border-bottom:none}
.pp-fila:hover{background:#FFF8FB}
.pp-fila.pp-hoy{border-left-color:#C62828}
.pp-fila.pp-manana{border-left-color:#E65100}

.pp-main{flex:1;min-width:0}
.pp-r1{display:flex;align-items:center;gap:6px;flex-wrap:wrap;margin-bottom:3px}
.pp-r2{display:flex;align-items:center;gap:8px;margin-bottom:3px}
.pp-r3{display:flex;align-items:center;gap:6px;flex-wrap:wrap}
.pp-cod{font-family:monospace;font-size:11px;font-weight:600;color:#7F77DD}
.pp-nom{font-size:13px;font-weight:500;color:#212121}
.pp-sub{font-size:11px;color:#9e9e9e;display:inline-flex;align-items:center;gap:3px}
.pp-age{font-size:10px;color:#9e9e9e;display:inline-flex;align-items:center;gap:3px}

.pp-right{text-align:right;flex-shrink:0}
.pp-monto{font-size:13px;font-weight:500;color:#212121}
.pp-fecha-ent{font-size:10px;color:#9e9e9e;margin-top:2px}
.pp-chev{color:#bdbdbd;font-size:18px;flex-shrink:0}

.ppb{display:inline-flex;align-items:center;gap:3px;padding:2px 7px;border-radius:99px;font-size:10px;font-weight:500;white-space:nowrap}
.ppd{width:5px;height:5px;border-radius:50%;display:inline-block;flex-shrink:0}
.ppb-borrador{background:#F1EFE8;color:#5F5E5A} .ppb-borrador .ppd{background:#888780}
.ppb-form{background:#E6F1FB;color:#185FA5}     .ppb-form .ppd{background:#185FA5}
.ppb-completado{background:#E1F5EE;color:#0F6E56} .ppb-completado .ppd{background:#3B6D11}
.ppb-esp{background:#FAEEDA;color:#854F0B}      .ppb-esp .ppd{background:#854F0B}
.ppb-pagado{background:#EAF3DE;color:#3B6D11}   .ppb-pagado .ppd{background:#3B6D11}
.ppb-convertido{background:#EEEDFE;color:#534AB7} .ppb-convertido .ppd{background:#534AB7}
.ppb-cancelado{background:#FCEBEB;color:#A32D2D}  .ppb-cancelado .ppd{background:#A32D2D}
.ppb-sinpago{background:#F1EFE8;color:#5F5E5A}  .ppb-sinpago .ppd{background:#888780}
.ppb-verif{background:#EAF3DE;color:#3B6D11}    .ppb-verif .ppd{background:#3B6D11}
.ppb-comprob{background:#FAEEDA;color:#854F0B}  .ppb-comprob .ppd{background:#854F0B}
.ppb-rechazado{background:#FCEBEB;color:#A32D2D} .ppb-rechazado .ppd{background:#A32D2D}

.pp-ae{display:inline-flex;align-items:center;gap:3px;padding:2px 7px;border-radius:99px;font-size:10px;font-weight:500}
.pp-ae-hoy{background:#FCEBEB;color:#A32D2D}
.pp-ae-man{background:#FAEEDA;color:#854F0B}
.pp-ae-venc{background:#FCEBEB;color:#A32D2D}

.pp-loading{text-align:center;padding:40px;color:#9e9e9e;display:flex;flex-direction:column;align-items:center;gap:8px}
.pp-empty{text-align:center;padding:40px 20px;color:#9e9e9e}
</style>

<script type="text/javascript">
// @ts-nocheck
var _pagina=1,_porPagina=20,_total=0,_buscarTimer=null;
var _hoy=new Date(); _hoy.setHours(0,0,0,0);
var _manana=new Date(_hoy); _manana.setDate(_manana.getDate()+1);

window.addEventListener('DOMContentLoaded',function(){
    var p=new URLSearchParams(window.location.search);
    if(p.get('buscar')) document.getElementById('txBuscar').value=p.get('buscar');
    if(p.get('estado')) document.getElementById('selEstado').value=p.get('estado');
    var dj=document.getElementById('jsonInicial');
    if(dj&&dj.textContent.trim()){
        try{var ini=JSON.parse(dj.textContent.trim());_total=ini.total||0;renderTodo(ini.items||[]);}
        catch(e){cargarDesdeServidor();}
    }else{cargarDesdeServidor();}
});

function onBuscarInput(){clearTimeout(_buscarTimer);_buscarTimer=setTimeout(function(){_pagina=1;cargarDesdeServidor();},350);}
function aplicarFiltros(){_pagina=1;cargarDesdeServidor();}
function irPagina(d){_pagina+=d;cargarDesdeServidor();}

function cargarDesdeServidor(){
    var b=document.getElementById('txBuscar').value.trim();
    var e=document.getElementById('selEstado').value;
    var url=window.location.pathname+'?accion=LISTAR&p='+_pagina+'&buscar='+encodeURIComponent(b)+'&estado='+encodeURIComponent(e);
    document.getElementById('divLista').innerHTML='<div class="pp-loading"><i class="ti ti-loader"></i> Cargando...</div>';
    fetch(url,{headers:{'X-Requested-With':'XMLHttpRequest'}})
        .then(function(r){return r.json();})
        .then(function(d){_total=d.total||0;renderTodo(d.items||[]);})
        .catch(function(){document.getElementById('divLista').innerHTML='<div class="pp-empty">Error al cargar.</div>';});
}

function renderTodo(items){
    renderTotales(items);
    renderLista(items);
    renderPaginacion();
}

function renderTotales(items){
    var monto=0,urgentes=0,sinPago=0;
    for(var i=0;i<items.length;i++){
        var d=items[i];
        monto+=parseFloat(d.total_general_bs)||0;
        if(d.fecha_entrega_min){
            var fe=new Date(d.fecha_entrega_min);fe.setHours(0,0,0,0);
            if(fe<=_manana) urgentes++;
        }
        if((d.estado==='COMPLETADO'||d.estado==='ESPERANDO_PAGO')&&d.estado_pago!=='VERIFICADO') sinPago++;
    }
    set('totCantidad',_total.toString());
    set('totMonto',fmt(monto));
    set('totUrgentes',urgentes.toString());
    set('totSinPago',sinPago.toString());
}

function renderLista(items){
    var div=document.getElementById('divLista');
    if(!items||items.length===0){
        div.innerHTML='<div class="pp-empty"><i class="ti ti-inbox" style="font-size:36px;display:block;margin-bottom:8px;opacity:0.3;"></i>Sin resultados</div>';
        return;
    }
    var html='',lastDia='';
    for(var i=0;i<items.length;i++){
        var d=items[i];
        var dia=diaLabel(d.creado_en);
        if(dia!==lastDia){html+='<div class="pp-sep">'+esc(dia)+'</div>';lastDia=dia;}
        var al=alertaFila(d);
        html+='<a class="pp-fila '+al.clase+'" href="PrePedido_Detalle.aspx?id='+d.prepedido_id+'">';
        html+='<div class="pp-main">';
        html+='<div class="pp-r1"><span class="pp-cod">'+esc(d.codigo)+'</span>'+badgeEstado(d.estado)+(al.badge?al.badge:'')+'</div>';
        html+='<div class="pp-r2"><span class="pp-nom">'+esc(d.cliente_nombre||'Sin nombre')+'</span><span class="pp-sub"><i class="ti ti-device-mobile" aria-hidden="true"></i> '+esc(d.cliente_celular)+'</span></div>';
        html+='<div class="pp-r3"><span class="pp-age"><i class="ti ti-user" aria-hidden="true"></i> '+esc(d.creado_por_nombre||'Agente')+' · '+fmtFechaHora(d.creado_en)+'</span>'+badgePago(d.estado_pago)+htmlToken(d.token_web,d.token_expira,d.estado)+'</div>';
        html+='</div>';
        html+='<div class="pp-right"><div class="pp-monto">'+fmt(d.total_general_bs)+' Bs</div>';
        html+=d.fecha_entrega_min?'<div class="pp-fecha-ent"><i class="ti ti-calendar" aria-hidden="true"></i> '+fmtFechaCorta(d.fecha_entrega_min)+'</div>':'<div class="pp-fecha-ent">Sin fecha</div>';
        html+='</div>';
        html+='<i class="ti ti-chevron-right pp-chev" aria-hidden="true"></i></a>';
    }
    div.innerHTML=html;
}

function renderPaginacion(){
    var tp=Math.ceil(_total/_porPagina);
    var dp=document.getElementById('divPaginacion');
    if(tp<=1){if(dp)dp.style.display='none';return;}
    dp.style.display='flex';
    set('spPagina','Pág. '+_pagina+' / '+tp);
    document.getElementById('btnAnterior').disabled=(_pagina<=1);
    document.getElementById('btnSiguiente').disabled=(_pagina>=tp);
}

function alertaFila(d){
    if(d.token_expira&&d.estado==='FORM_ENVIADO'){
        var exp=new Date(d.token_expira);exp.setHours(0,0,0,0);
        if(exp<_hoy) return{clase:'pp-hoy',badge:'<span class="pp-ae pp-ae-venc"><i class="ti ti-clock-x" aria-hidden="true"></i> Token vencido</span>'};
    }
    if(!d.fecha_entrega_min) return{clase:'',badge:''};
    var fe=new Date(d.fecha_entrega_min);fe.setHours(0,0,0,0);
    if(fe<_hoy)                         return{clase:'pp-hoy',   badge:'<span class="pp-ae pp-ae-hoy"><i class="ti ti-alert-triangle" aria-hidden="true"></i> Entrega vencida</span>'};
    if(fe.getTime()===_hoy.getTime())   return{clase:'pp-hoy',   badge:'<span class="pp-ae pp-ae-hoy"><i class="ti ti-alert-triangle" aria-hidden="true"></i> Entrega HOY</span>'};
    if(fe.getTime()===_manana.getTime())return{clase:'pp-manana',badge:'<span class="pp-ae pp-ae-man"><i class="ti ti-clock" aria-hidden="true"></i> Entrega mañana</span>'};
    return{clase:'',badge:''};
}

function badgeEstado(e){
    var m={'BORRADOR':'<span class="ppb ppb-borrador"><span class="ppd"></span>Borrador</span>','FORM_ENVIADO':'<span class="ppb ppb-form"><span class="ppd"></span>Form enviado</span>','COMPLETADO':'<span class="ppb ppb-completado"><span class="ppd"></span>Completado</span>','ESPERANDO_PAGO':'<span class="ppb ppb-esp"><span class="ppd"></span>Esperando pago</span>','PAGADO':'<span class="ppb ppb-pagado"><span class="ppd"></span>Pagado</span>','CONVERTIDO':'<span class="ppb ppb-convertido"><span class="ppd"></span>Convertido</span>','CANCELADO':'<span class="ppb ppb-cancelado"><span class="ppd"></span>Cancelado</span>'};
    return m[e]||'<span class="ppb ppb-borrador">'+esc(e)+'</span>';
}

function badgePago(ep){
    if(ep==='VERIFICADO') return '<span class="ppb ppb-verif"><span class="ppd"></span>Pago verificado</span>';
    if(ep==='PENDIENTE')  return '<span class="ppb ppb-comprob"><span class="ppd"></span>Comprobante enviado</span>';
    if(ep==='RECHAZADO')  return '<span class="ppb ppb-rechazado"><span class="ppd"></span>Pago rechazado</span>';
    return '';
}

function htmlToken(tw,te,estado){
    if(!tw||estado==='BORRADOR') return '<span class="pp-sub"><i class="ti ti-link-off" aria-hidden="true"></i> Sin enviar</span>';
    if(['COMPLETADO','ESPERANDO_PAGO','PAGADO','CONVERTIDO'].indexOf(estado)>=0) return '<span class="pp-sub"><i class="ti ti-circle-check" aria-hidden="true"></i> Cliente llenó</span>';
    if(te){var exp=new Date(te),ahora=new Date();if(exp<ahora)return '';var dif=Math.round((exp-ahora)/3600000);return '<span class="pp-sub"><i class="ti ti-clock" aria-hidden="true"></i> Vence en '+dif+'h</span>';}
    return '';
}

function diaLabel(s){
    if(!s)return '';
    var d=new Date(s);d.setHours(0,0,0,0);
    var aye=new Date(_hoy);aye.setDate(aye.getDate()-1);
    if(d.getTime()===_hoy.getTime())  return 'Hoy — '+fmtFechaCorta(s);
    if(d.getTime()===aye.getTime())   return 'Ayer — '+fmtFechaCorta(s);
    return fmtFechaCorta(s);
}

function fmt(v){if(!v)return '0.00';return parseFloat(v).toLocaleString('es-BO',{minimumFractionDigits:2,maximumFractionDigits:2});}
function fmtFechaCorta(s){if(!s)return '';var d=new Date(s);var m=['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];return d.getDate()+' '+m[d.getMonth()];}
function fmtFechaHora(s){if(!s)return '';var d=new Date(s);var m=['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];return d.getDate()+' '+m[d.getMonth()]+' '+pad(d.getHours())+':'+pad(d.getMinutes());}
function pad(n){return n<10?'0'+n:''+n;}
function set(id,v){var e=document.getElementById(id);if(e)e.textContent=v;}
function esc(v){if(!v)return '';return String(v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
</script>
</asp:Content>
