' ============================================================
' SISCONBOL_FLORERIA - Clientes (code-behind)
' Pagina shell: el listado se carga via Clientes_Handler.ashx.
' Sesion y menu los maneja Site.Master.
' ============================================================
Partial Public Class Modulos_CRM_Clientes
    Inherits System.Web.UI.Page

    Protected Sub Page_Load(sender As Object, e As EventArgs) Handles Me.Load
        ' Nada: la pagina solo monta el shell. Datos via handler.
    End Sub

End Class
