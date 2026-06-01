<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="pp.aspx.vb" Inherits="SISCONBOL_FLORERIA.pp" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Miss Flores - Pre-pedido</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex; align-items: center; justify-content: center; min-height: 100vh;
            background: linear-gradient(135deg, #C2185B 0%, #880E4F 100%); color: #fff; padding: 16px;
        }
        /* --- Spinner (redirect del cliente) --- */
        .loader { text-align: center; padding: 2rem; }
        .spinner {
            border: 4px solid rgba(255,255,255,0.3); border-top: 4px solid #fff; border-radius: 50%;
            width: 50px; height: 50px; animation: spin 1s linear infinite; margin: 0 auto 1.5rem;
        }
        @keyframes spin { 0% { transform: rotate(0deg);} 100% { transform: rotate(360deg);} }
        .loader h2 { font-size: 18px; font-weight: 400; margin-bottom: .5rem; }
        .loader p { font-size: 14px; opacity: .9; }

        /* --- Pantalla de eleccion (agente) --- */
        .card {
            background: #fff; color: #212121; border-radius: 16px; max-width: 420px; width: 100%;
            padding: 26px 22px; box-shadow: 0 12px 40px rgba(0,0,0,.25); text-align: center;
        }
        .card .flor { font-size: 40px; color: #C2185B; }
        .card h1 { font-size: 19px; font-weight: 700; color: #880E4F; margin: 8px 0 2px; }
        .card .codigo { font-size: 13px; color: #888; margin-bottom: 4px; }
        .card .cliente { font-size: 14px; color: #555; margin-bottom: 20px; }
        .card .pregunta { font-size: 14px; font-weight: 600; color: #444; margin-bottom: 16px; }
        .opt {
            display: flex; align-items: center; gap: 12px; text-decoration: none; text-align: left;
            border: 2px solid #eee; border-radius: 12px; padding: 14px 16px; margin-bottom: 12px;
            color: #212121; transition: border-color .15s, background .15s;
        }
        .opt:hover { border-color: #C2185B; background: #FCE4EC; }
        .opt i { font-size: 28px; flex-shrink: 0; }
        .opt.agente i { color: #1565C0; }
        .opt.cliente i { color: #2E7D32; }
        .opt .t { font-size: 15px; font-weight: 600; }
        .opt .s { font-size: 12px; color: #777; }
        .foot { font-size: 11px; color: #aaa; margin-top: 6px; }
    </style>
</head>
<body>

<% If MostrarEleccion Then %>

    <div class="card">
        <i class="ti ti-flower flor"></i>
        <h1>Miss Flores</h1>
        <div class="codigo"><%= Codigo %></div>
        <% If ClienteNombre <> "" Then %>
            <div class="cliente"><i class="ti ti-user" style="font-size:13px;vertical-align:-2px"></i> <%= Server.HtmlEncode(ClienteNombre) %></div>
        <% End If %>

        <p class="pregunta">Como quieres ver este pre-pedido?</p>

        <a class="opt agente" href="<%= LinkAgente %>">
            <i class="ti ti-user-check"></i>
            <div>
                <div class="t">Ver como AGENTE</div>
                <div class="s">Abrir la gestion interna del pre-pedido</div>
            </div>
        </a>

        <a class="opt cliente" href="<%= LinkCliente %>">
            <i class="ti ti-user"></i>
            <div>
                <div class="t">Ver como CLIENTE</div>
                <div class="s">Abrir el formulario publico de confirmacion</div>
            </div>
        </a>

        <p class="foot">Estas viendo esto porque tienes una sesion de agente activa.</p>
    </div>

<% Else %>

    <div class="loader">
        <div class="spinner"></div>
        <h2>Abriendo tu pre-pedido...</h2>
        <p>Por favor espera un momento</p>
    </div>

<% End If %>

</body>
</html>
