<%@ Page Language="VB" AutoEventWireup="false" CodeBehind="Error.aspx.vb" Inherits="SISCONBOL_FLORERIA.ErrorPage" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SISCONBOL - Error</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@latest/tabler-icons.min.css">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .error-container {
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0,0,0,.3);
            padding: 48px 40px;
            max-width: 500px;
            width: 100%;
            text-align: center;
        }
        .error-icon {
            font-size: 80px;
            margin-bottom: 24px;
        }
        .error-icon.e403 { color: #F57C00; }
        .error-icon.e404 { color: #1976D2; }
        .error-icon.e500 { color: #D32F2F; }
        .error-code {
            font-size: 48px;
            font-weight: 700;
            margin-bottom: 16px;
            color: #424242;
        }
        .error-title {
            font-size: 24px;
            font-weight: 600;
            margin-bottom: 12px;
            color: #424242;
        }
        .error-message {
            font-size: 15px;
            color: #757575;
            line-height: 1.6;
            margin-bottom: 32px;
        }
        .error-actions {
            display: flex;
            gap: 12px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
            transition: all .2s;
            border: none;
            cursor: pointer;
        }
        .btn-primary {
            background: #C2185B;
            color: white;
        }
        .btn-primary:hover {
            background: #880E4F;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(194, 24, 91, 0.3);
        }
        .btn-secondary {
            background: #f5f5f5;
            color: #424242;
        }
        .btn-secondary:hover {
            background: #eeeeee;
        }
        .error-details {
            margin-top: 32px;
            padding-top: 24px;
            border-top: 1px solid #e0e0e0;
            font-size: 12px;
            color: #9e9e9e;
        }
        @media (max-width: 480px) {
            .error-container {
                padding: 32px 24px;
            }
            .error-code {
                font-size: 36px;
            }
            .error-title {
                font-size: 20px;
            }
            .error-actions {
                flex-direction: column;
            }
            .btn {
                width: 100%;
                justify-content: center;
            }
        }
    </style>
</head>
<body>
    <div class="error-container">
        <div class="error-icon <%= IconClass %>" id="errorIcon">
            <i class="<%= IconoTabler %>"></i>
        </div>
        
        <div class="error-code" id="errorCode"><%= CodigoError %></div>
        <div class="error-title" id="errorTitle"><%= TituloError %></div>
        <div class="error-message" id="errorMessage"><%= MensajeError %></div>
        
        <div class="error-actions">
            <a href="<%= ResolveUrl("~/Default.aspx") %>" class="btn btn-primary">
                <i class="ti ti-home"></i>
                Ir al inicio
            </a>
            <button type="button" class="btn btn-secondary" onclick="history.back()">
                <i class="ti ti-arrow-left"></i>
                Volver atrás
            </button>
        </div>
        
        <% If MostrarDetalles Then %>
        <div class="error-details">
            <div><strong>ID de error:</strong> <%= ErrorId %></div>
            <div><strong>Fecha:</strong> <%= FechaError %></div>
        </div>
        <% End If %>
    </div>
</body>
</html>
