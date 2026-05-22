<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="Error.aspx.vb" Inherits="SISCONBOL_FLORERIA.Error_aspx" %>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Error - SISCONBOL</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f5f5;color:#424242;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:20px}
.error-box{background:white;border-radius:12px;padding:40px;max-width:500px;width:100%;text-align:center;box-shadow:0 4px 16px rgba(0,0,0,.08)}
.error-icon{font-size:64px;color:#C2185B;margin-bottom:20px}
.error-title{font-size:24px;font-weight:600;color:#424242;margin-bottom:12px}
.error-message{font-size:15px;color:#757575;line-height:1.6;margin-bottom:24px}
.error-code{font-size:13px;color:#9e9e9e;margin-bottom:24px;font-family:monospace}
.btn{display:inline-flex;align-items:center;gap:8px;padding:10px 20px;background:#C2185B;color:white;border:none;border-radius:8px;font-size:14px;font-weight:500;text-decoration:none;cursor:pointer;transition:background .15s}
.btn:hover{background:#880E4F}
.btn-secondary{background:white;color:#424242;border:1px solid #e0e0e0}
.btn-secondary:hover{background:#f5f5f5}
.actions{display:flex;gap:12px;justify-content:center;flex-wrap:wrap}
</style>
</head>
<body>
<div class="error-box">
    <i class="ti ti-alert-triangle error-icon" aria-hidden="true"></i>
    <h1 class="error-title" id="errorTitle">Ha ocurrido un error</h1>
    <p class="error-message" id="errorMessage">
        Lo sentimos, algo salio mal. Por favor intenta nuevamente.
    </p>
    <div class="error-code" id="errorCode"></div>
    <div class="actions">
        <a href="<%= ResolveUrl("~/Default.aspx") %>" class="btn">
            <i class="ti ti-home" aria-hidden="true"></i>
            Ir al inicio
        </a>
        <button onclick="history.back()" class="btn btn-secondary" type="button">
            <i class="ti ti-arrow-left" aria-hidden="true"></i>
            Volver atras
        </button>
    </div>
</div>
<script>
// @ts-nocheck
(function() {
    var params = new URLSearchParams(window.location.search);
    var errorCode = params.get('e');
    
    var elTitle = document.getElementById('errorTitle');
    var elMessage = document.getElementById('errorMessage');
    var elCode = document.getElementById('errorCode');
    
    if (errorCode === '403') {
        elTitle.textContent = 'Acceso denegado';
        elMessage.textContent = 'No tienes permisos para acceder a este recurso.';
        elCode.textContent = 'Error 403';
    } else if (errorCode === '404') {
        elTitle.textContent = 'Pagina no encontrada';
        elMessage.textContent = 'La pagina que buscas no existe o fue movida.';
        elCode.textContent = 'Error 404';
    } else if (errorCode === '500') {
        elTitle.textContent = 'Error del servidor';
        elMessage.textContent = 'Ocurrio un problema en el servidor. Estamos trabajando para solucionarlo.';
        elCode.textContent = 'Error 500';
    } else {
        elTitle.textContent = 'Ha ocurrido un error';
        elMessage.textContent = 'Lo sentimos, algo salio mal. Por favor intenta nuevamente.';
        if (errorCode) {
            elCode.textContent = 'Error ' + errorCode;
        }
    }
})();
</script>
</body>
</html>
