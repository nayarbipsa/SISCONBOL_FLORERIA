<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="false" CodeBehind="Webhooks_Monitor.aspx.vb" Inherits="SISCONBOL_FLORERIA.Modulos.Config.Webhooks_Monitor" %>

<asp:Content ID="Content1" ContentPlaceHolderID="head" runat="server">
    <title>Monitor de Webhooks WooCommerce - SISCONBOL</title>
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">
    <div class="contenedor-modulo">
        <div class="encabezado-modulo">
            <h1><i class="ti ti-webhook"></i> Monitor de Webhooks WooCommerce</h1>
            <p class="descripcion">Visualiza y monitorea los webhooks recibidos desde WooCommerce</p>
        </div>

        <!-- Panel de estadísticas -->
        <div class="tarjetas-stats">
            <div class="tarjeta-stat ok">
                <div class="icono"><i class="ti ti-check"></i></div>
                <div class="info">
                    <span class="etiqueta">Procesados OK (24h)</span>
                    <span class="valor" id="statOk">0</span>
                </div>
            </div>
            <div class="tarjeta-stat error">
                <div class="icono"><i class="ti ti-alert-triangle"></i></div>
                <div class="info">
                    <span class="etiqueta">Errores (24h)</span>
                    <span class="valor" id="statError">0</span>
                </div>
            </div>
            <div class="tarjeta-stat info">
                <div class="icono"><i class="ti ti-clock"></i></div>
                <div class="info">
                    <span class="etiqueta">Último Webhook</span>
                    <span class="valor" id="statUltimo">-</span>
                </div>
            </div>
        </div>

        <!-- Filtros -->
        <div class="caja-contenido" style="margin-top: 20px;">
            <div class="filtros-webhook">
                <div class="campo-filtro">
                    <label>Tipo:</label>
                    <select id="filtroTipo">
                        <option value="">Todos</option>
                        <option value="RECIBIDO">Recibidos</option>
                        <option value="PROCESADO">Procesados</option>
                        <option value="ERROR">Errores</option>
                    </select>
                </div>
                <div class="campo-filtro">
                    <label>WC Order:</label>
                    <input type="text" id="filtroOrder" placeholder="Número de orden">
                </div>
                <div class="campo-filtro">
                    <label>Últimas:</label>
                    <select id="filtroHoras">
                        <option value="24">24 horas</option>
                        <option value="48">48 horas</option>
                        <option value="168">7 días</option>
                    </select>
                </div>
                <button class="btn-secundario" onclick="cargarLogs()">
                    <i class="ti ti-refresh"></i> Actualizar
                </button>
            </div>
        </div>

        <!-- Tabla de logs -->
        <div class="caja-contenido" style="margin-top: 20px;">
            <div class="tabla-scroll">
                <table class="tabla-datos" id="tablaLogs">
                    <thead>
                        <tr>
                            <th>Fecha</th>
                            <th>Tipo</th>
                            <th>WC Order</th>
                            <th>Pedido ID</th>
                            <th>Firma</th>
                            <th>IP Origen</th>
                            <th>Mensaje</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody id="bodyLogs">
                        <tr>
                            <td colspan="8" class="texto-centro">Cargando logs...</td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Hidden fields para postback -->
    <asp:HiddenField ID="hdnAccion" runat="server" />
    <asp:HiddenField ID="hdnLogId" runat="server" />
    <asp:Button ID="btnAccion" runat="server" style="display:none;" />
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
    <script>
        // @ts-nocheck
        
        // Cargar logs al iniciar
        document.addEventListener('DOMContentLoaded', function() {
            cargarLogs();
            
            // Auto-refresh cada 30 segundos
            setInterval(cargarLogs, 30000);
        });
        
        function cargarLogs() {
            var tipo = document.getElementById('filtroTipo').value;
            var order = document.getElementById('filtroOrder').value;
            var horas = document.getElementById('filtroHoras').value;
            
            // Simular carga (en producción, usar AJAX a WebMethod)
            var bodyLogs = document.getElementById('bodyLogs');
            bodyLogs.innerHTML = '<tr><td colspan="8" class="texto-centro">Cargando...</td></tr>';
            
            setTimeout(function() {
                cargarLogsReal(tipo, order, horas);
            }, 500);
        }
        
        function cargarLogsReal(tipo, order, horas) {
            // TODO: Implementar llamada AJAX real
            // Por ahora, datos de ejemplo
            var logs = [
                {
                    fecha: '2026-05-24 16:45:30',
                    tipo: 'PROCESADO',
                    wc_order: '1234',
                    pedido_id: '42',
                    firma_valida: true,
                    ip: '192.168.1.100',
                    mensaje: 'Pedido creado correctamente'
                },
                {
                    fecha: '2026-05-24 16:30:15',
                    tipo: 'ERROR',
                    wc_order: '1235',
                    pedido_id: null,
                    firma_valida: false,
                    ip: '192.168.1.101',
                    mensaje: 'Firma HMAC inválida'
                }
            ];
            
            renderizarLogs(logs);
            actualizarStats(logs);
        }
        
        function renderizarLogs(logs) {
            var bodyLogs = document.getElementById('bodyLogs');
            
            if (logs.length === 0) {
                bodyLogs.innerHTML = '<tr><td colspan="8" class="texto-centro">No hay logs para mostrar</td></tr>';
                return;
            }
            
            var html = '';
            logs.forEach(function(log) {
                var claseTipo = log.tipo === 'ERROR' ? 'badge-error' : 'badge-ok';
                var iconoFirma = log.firma_valida ? 
                    '<i class="ti ti-check" style="color: green;"></i>' : 
                    '<i class="ti ti-x" style="color: red;"></i>';
                
                html += '<tr>';
                html += '<td>' + log.fecha + '</td>';
                html += '<td><span class="' + claseTipo + '">' + log.tipo + '</span></td>';
                html += '<td>#' + log.wc_order + '</td>';
                html += '<td>' + (log.pedido_id || '-') + '</td>';
                html += '<td class="texto-centro">' + iconoFirma + '</td>';
                html += '<td>' + log.ip + '</td>';
                html += '<td>' + log.mensaje + '</td>';
                html += '<td class="texto-centro">';
                html += '<button class="btn-icono" onclick="verDetalle(' + log.log_id + ')" title="Ver JSON">';
                html += '<i class="ti ti-file-text"></i>';
                html += '</button>';
                html += '</td>';
                html += '</tr>';
            });
            
            bodyLogs.innerHTML = html;
        }
        
        function actualizarStats(logs) {
            var ok = logs.filter(function(l) { return l.tipo === 'PROCESADO'; }).length;
            var error = logs.filter(function(l) { return l.tipo === 'ERROR'; }).length;
            var ultimo = logs.length > 0 ? logs[0].fecha : '-';
            
            document.getElementById('statOk').textContent = ok;
            document.getElementById('statError').textContent = error;
            document.getElementById('statUltimo').textContent = ultimo;
        }
        
        function verDetalle(logId) {
            alert('Ver detalle del log ID: ' + logId);
            // TODO: Abrir modal con JSON completo del payload
        }
    </script>
    
    <style>
        .tarjetas-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .tarjeta-stat {
            background: white;
            border-radius: 8px;
            padding: 20px;
            display: flex;
            align-items: center;
            gap: 15px;
            border-left: 4px solid #ccc;
        }
        
        .tarjeta-stat.ok { border-left-color: var(--color-ok); }
        .tarjeta-stat.error { border-left-color: var(--color-error); }
        .tarjeta-stat.info { border-left-color: var(--color-info); }
        
        .tarjeta-stat .icono {
            font-size: 2rem;
            opacity: 0.8;
        }
        
        .tarjeta-stat .info {
            display: flex;
            flex-direction: column;
        }
        
        .tarjeta-stat .etiqueta {
            font-size: 0.85rem;
            color: #666;
            margin-bottom: 5px;
        }
        
        .tarjeta-stat .valor {
            font-size: 1.8rem;
            font-weight: bold;
            color: #333;
        }
        
        .filtros-webhook {
            display: flex;
            gap: 15px;
            align-items: flex-end;
            flex-wrap: wrap;
        }
        
        .campo-filtro {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        
        .campo-filtro label {
            font-size: 0.9rem;
            color: #666;
        }
        
        .badge-ok {
            background: #d4edda;
            color: #155724;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 0.85rem;
            font-weight: 500;
        }
        
        .badge-error {
            background: #f8d7da;
            color: #721c24;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 0.85rem;
            font-weight: 500;
        }
    </style>
</asp:Content>
