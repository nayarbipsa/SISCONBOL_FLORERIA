Imports System
Imports System.Text.RegularExpressions

' ============================================================
' SISCONBOL - Validador Centralizado
' Archivo: App_Code/Validador.vb
' Uso: Validaciones reutilizables en TODO el proyecto
' ============================================================
Public Class Validador

    ' ============================================================
    ' VALIDACIONES DE TEXTO
    ' ============================================================

    ''' <summary>
    ''' Valida que un texto solo contenga letras, espacios y acentos
    ''' Permite: a-z, A-Z, á, é, í, ó, ú, ñ, Ñ, espacios
    ''' </summary>
    Public Shared Function EsTextoValido(texto As String, Optional permitirVacio As Boolean = True) As Boolean
        If texto Is Nothing Then texto = ""
        texto = texto.Trim()

        If texto = "" Then Return permitirVacio

        ' Solo letras, espacios, acentos, ñ
        Dim regex As New Regex("^[a-zA-Z\u00E1\u00E9\u00ED\u00F3\u00FA\u00C1\u00C9\u00CD\u00D3\u00DA\u00F1\u00D1\s]+$")
        Return regex.IsMatch(texto)
    End Function

    ''' <summary>
    ''' Valida que un texto alfanumérico sea válido
    ''' Permite: letras, números, espacios, guiones, puntos
    ''' </summary>
    Public Shared Function EsAlfanumericoValido(texto As String, Optional permitirVacio As Boolean = True) As Boolean
        If texto Is Nothing Then texto = ""
        texto = texto.Trim()

        If texto = "" Then Return permitirVacio

        ' Letras, números, espacios, guiones, puntos
        Dim regex As New Regex("^[a-zA-Z0-9\u00E1\u00E9\u00ED\u00F3\u00FA\u00C1\u00C9\u00CD\u00D3\u00DA\u00F1\u00D1\s\.\-]+$")
        Return regex.IsMatch(texto)
    End Function

    ''' <summary>
    ''' Limpia caracteres peligrosos de un texto
    ''' Remueve: <, >, ", ', ;, --, /*, */
    ''' </summary>
    Public Shared Function LimpiarTexto(texto As String) As String
        If texto Is Nothing Then Return ""

        texto = texto.Trim()
        texto = texto.Replace("<", "")
        texto = texto.Replace(">", "")
        texto = texto.Replace("'", "")
        texto = texto.Replace("""", "")
        texto = texto.Replace(";", "")
        texto = texto.Replace("--", "")
        texto = texto.Replace("/*", "")
        texto = texto.Replace("*/", "")
        texto = texto.Replace("script", "")
        texto = texto.Replace("SCRIPT", "")

        Return texto.Trim()
    End Function

    ' ============================================================
    ' VALIDACIONES DE CELULAR
    ' ============================================================

    ''' <summary>
    ''' Valida que un celular tenga formato válido
    ''' Permite: números, +, espacios, guiones, paréntesis
    ''' Mínimo: 7 dígitos
    ''' </summary>
    Public Shared Function EsCelularValido(celular As String) As Boolean
        If celular Is Nothing Then Return False
        celular = celular.Trim()

        If celular = "" Then Return False

        ' Solo números, +, espacios, guiones, paréntesis
        Dim regex As New Regex("^[\d\s\+\-\(\)]+$")
        If Not regex.IsMatch(celular) Then Return False

        ' Contar solo dígitos
        Dim digitos As String = Regex.Replace(celular, "[^\d]", "")

        ' Mínimo 7 dígitos
        If digitos.Length < 7 Then Return False

        ' Máximo 15 dígitos (estándar internacional E.164)
        If digitos.Length > 15 Then Return False

        Return True
    End Function

    ''' <summary>
    ''' Normaliza un celular removiendo caracteres de formato
    ''' Ejemplo: "+591 (72) 020-979" → "+59172020979"
    ''' </summary>
    Public Shared Function NormalizarCelular(celular As String) As String
        If celular Is Nothing Then Return ""

        ' Remover espacios, guiones, paréntesis
        celular = celular.Replace(" ", "")
        celular = celular.Replace("-", "")
        celular = celular.Replace("(", "")
        celular = celular.Replace(")", "")

        Return celular.Trim()
    End Function

    ' ============================================================
    ' VALIDACIONES DE EMAIL
    ' ============================================================

    ''' <summary>
    ''' Valida que un email tenga formato válido
    ''' </summary>
    Public Shared Function EsEmailValido(email As String, Optional permitirVacio As Boolean = True) As Boolean
        If email Is Nothing Then email = ""
        email = email.Trim()

        If email = "" Then Return permitirVacio

        ' Regex básico de email
        Dim regex As New Regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        Return regex.IsMatch(email)
    End Function

    ' ============================================================
    ' VALIDACIONES DE NÚMEROS
    ' ============================================================

    ''' <summary>
    ''' Valida que un texto sea un número entero válido
    ''' </summary>
    Public Shared Function EsEnteroValido(texto As String, ByRef valor As Integer) As Boolean
        If texto Is Nothing Then Return False
        Return Integer.TryParse(texto.Trim(), valor)
    End Function

    ''' <summary>
    ''' Valida que un texto sea un número decimal válido
    ''' </summary>
    Public Shared Function EsDecimalValido(texto As String, ByRef valor As Decimal) As Boolean
        If texto Is Nothing Then Return False
        Return Decimal.TryParse(texto.Trim(), valor)
    End Function

    ' ============================================================
    ' VALIDACIONES DE FECHAS
    ' ============================================================

    ''' <summary>
    ''' Valida que un texto sea una fecha válida
    ''' </summary>
    Public Shared Function EsFechaValida(texto As String, ByRef fecha As DateTime) As Boolean
        If texto Is Nothing Then Return False
        Return DateTime.TryParse(texto.Trim(), fecha)
    End Function

    ''' <summary>
    ''' Valida que una fecha sea futura (mayor a hoy)
    ''' </summary>
    Public Shared Function EsFechaFutura(fecha As DateTime) As Boolean
        Return fecha.Date > DateTime.Now.Date
    End Function

    ' ============================================================
    ' VALIDACIONES DE LONGITUD
    ' ============================================================

    ''' <summary>
    ''' Valida que un texto esté dentro de un rango de longitud
    ''' </summary>
    Public Shared Function ValidarLongitud(texto As String, minimo As Integer, maximo As Integer) As Boolean
        If texto Is Nothing Then texto = ""
        Dim longitud As Integer = texto.Trim().Length
        Return longitud >= minimo AndAlso longitud <= maximo
    End Function

    ' ============================================================
    ' DETECCIÓN DE INYECCIÓN SQL
    ' ============================================================

    ''' <summary>
    ''' Detecta posibles intentos de inyección SQL
    ''' </summary>
    Public Shared Function TienePatronPeligroso(texto As String) As Boolean
        If texto Is Nothing Then Return False

        texto = texto.ToUpper()

        ' Patrones sospechosos
        Dim patrones As String() = {
            "DROP TABLE", "DROP DATABASE", "DELETE FROM",
            "INSERT INTO", "UPDATE ", "EXEC ", "EXECUTE",
            "SCRIPT>", "<SCRIPT", "UNION SELECT", "OR 1=1",
            "'; DROP", "--", "/*", "*/", "XP_", "SP_"
        }

        For Each patron In patrones
            If texto.Contains(patron) Then Return True
        Next

        Return False
    End Function

    ' ============================================================
    ' MÉTODO PRINCIPAL DE VALIDACIÓN
    ' ============================================================

    ''' <summary>
    ''' Estructura para resultado de validación
    ''' </summary>
    Public Class ResultadoValidacion
        Public Property EsValido As Boolean = True
        Public Property Mensaje As String = ""
        Public Property Campo As String = ""
    End Class

    ''' <summary>
    ''' Valida formulario de Pre-Pedido
    ''' </summary>
    Public Shared Function ValidarFormularioPrePedido(
        celular As String,
        nombre As String,
        apellidos As String,
        email As String
    ) As ResultadoValidacion

        Dim resultado As New ResultadoValidacion()

        ' Validar celular (obligatorio)
        If String.IsNullOrWhiteSpace(celular) Then
            resultado.EsValido = False
            resultado.Mensaje = "El celular es obligatorio"
            resultado.Campo = "txCelular"
            Return resultado
        End If

        If Not EsCelularValido(celular) Then
            resultado.EsValido = False
            resultado.Mensaje = "El celular tiene un formato inválido. Use solo números, +, espacios, guiones y paréntesis"
            resultado.Campo = "txCelular"
            Return resultado
        End If

        If TienePatronPeligroso(celular) Then
            resultado.EsValido = False
            resultado.Mensaje = "El celular contiene caracteres no permitidos"
            resultado.Campo = "txCelular"
            Return resultado
        End If

        ' Validar nombre (opcional pero si existe debe ser válido)
        If Not String.IsNullOrWhiteSpace(nombre) Then
            If Not EsTextoValido(nombre, True) Then
                resultado.EsValido = False
                resultado.Mensaje = "El nombre solo puede contener letras y espacios"
                resultado.Campo = "txNombre"
                Return resultado
            End If

            If TienePatronPeligroso(nombre) Then
                resultado.EsValido = False
                resultado.Mensaje = "El nombre contiene caracteres no permitidos"
                resultado.Campo = "txNombre"
                Return resultado
            End If

            If nombre.Trim().Length > 200 Then
                resultado.EsValido = False
                resultado.Mensaje = "El nombre no puede exceder 200 caracteres"
                resultado.Campo = "txNombre"
                Return resultado
            End If
        End If

        ' Validar apellidos (opcional pero si existe debe ser válido)
        If Not String.IsNullOrWhiteSpace(apellidos) Then
            If Not EsTextoValido(apellidos, True) Then
                resultado.EsValido = False
                resultado.Mensaje = "Los apellidos solo pueden contener letras y espacios"
                resultado.Campo = "txApellidos"
                Return resultado
            End If

            If TienePatronPeligroso(apellidos) Then
                resultado.EsValido = False
                resultado.Mensaje = "Los apellidos contienen caracteres no permitidos"
                resultado.Campo = "txApellidos"
                Return resultado
            End If

            If apellidos.Trim().Length > 200 Then
                resultado.EsValido = False
                resultado.Mensaje = "Los apellidos no pueden exceder 200 caracteres"
                resultado.Campo = "txApellidos"
                Return resultado
            End If
        End If

        ' Validar email (opcional pero si existe debe ser válido)
        If Not String.IsNullOrWhiteSpace(email) Then
            If Not EsEmailValido(email, True) Then
                resultado.EsValido = False
                resultado.Mensaje = "El email tiene un formato inválido"
                resultado.Campo = "txEmail"
                Return resultado
            End If

            If TienePatronPeligroso(email) Then
                resultado.EsValido = False
                resultado.Mensaje = "El email contiene caracteres no permitidos"
                resultado.Campo = "txEmail"
                Return resultado
            End If

            If email.Trim().Length > 100 Then
                resultado.EsValido = False
                resultado.Mensaje = "El email no puede exceder 100 caracteres"
                resultado.Campo = "txEmail"
                Return resultado
            End If
        End If

        resultado.EsValido = True
        resultado.Mensaje = "Validación exitosa"
        Return resultado
    End Function

End Class