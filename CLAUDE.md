# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

SISCONBOL_FLORERIA is the internal management system for a flower shop ("Miss Flores", Bolivia): pre-orders, orders, catalog/pricing, delivery, finance, and a WooCommerce storefront integration. It is an **ASP.NET Web Forms application written in VB.NET on .NET Framework 4.8**, backed by **SQL Server 2019** (remote, hosted at somee.com). All UI text and domain vocabulary is Spanish.

## Build & run

- **Build:** Open `SISCONBOL_FLORERIA.sln`/`.vbproj` in Visual Studio (the project is `OutputType=Library` — a web app compiled to `bin/SISCONBOL_FLORERIA.dll`). From the CLI: `msbuild SISCONBOL_FLORERIA.vbproj /t:Build`. There is **no test suite, no linter, no npm/build pipeline** — verification is done by running the site and visually confirming behavior.
- **Run:** F5 in Visual Studio (IIS Express). The VB compiler is the Roslyn provider pinned via `packages.config` (`Microsoft.CodeDom.Providers.DotNetCompilerPlatform`).
- **Database:** The connection string lives in `Web.config` (`SISCONBOL`) and points at the live remote DB — there is no local DB. SQL is applied by running the numbered scripts in order against that server: `01_CREAR_TODAS_LAS_TABLAS.sql` → `02_CREAR_TODOS_LOS_INDICES.sql` → `03_TODOS_LOS_SPS.sql` → `04_DATOS_INICIALES.sql` → `05_SPS_DASHBOARD.sql`. These files are the **source of truth for the schema** — read them before touching any data code.

## Architecture

**MasterPage + SesionHelper is the spine of the app.** Understand these before editing pages:

- `App_Code/SesionHelper.vb` — the heart of the system. Owns the connection string (`ObtenerCadena`), session validation (`VerificarSesion`, backed by `FLORERIA_sp_ValidarSesion`), user data loading, and **dynamic sidebar HTML generation** (`GenerarMenuHtml`, backed by `FLORERIA_sp_CargarMenu` — menu items and per-user permissions come from the DB, not from markup).
- `Site.Master` / `Site.Master.vb` — the shell. `Site.Master.vb` is deliberately **minimal**: it only calls `SesionHelper.VerificarSesion` + `GenerarMenuHtml` in `Page_Load`. Do NOT add menu-loading or session logic here — duplicating it causes login loops.
- Internal pages (`.aspx` + `.aspx.vb`) use `MasterPageFile="~/Site.Master"` and contain only their own logic. They do **not** verify sessions or load menus — the master does. ContentPlaceHolders: `TitleContent`, `PageTitleContent`, `HeadContent`, `MainContent`, `ScriptsContent`.
- **Standalone pages (no master):** `Login.aspx`, `CambiarPassword.aspx`, `Error.aspx`.

**Authentication is custom, not membership-based.** `Login.aspx.vb` hashes the password as **SHA256 with salt `FLORERIA2026`** (this salt must match the SQL side), calls `FLORERIA_sp_Login`, then stores a token in both `Session` and a `SISCONBOL_TOKEN` cookie. `Global.asax.vb` `Session_Start` restores the session from that cookie after app recompiles, so sessions survive rebuilds. Forms auth is configured in `Web.config` but the real gate is `SesionHelper.VerificarSesion`.

**AJAX goes through `.ashx` handlers.** Pages with live tables/filters (e.g. `Pedidos_Handler.ashx.vb`, `MisEntregas_Handler.ashx.vb`, `PrePedido_Handler.ashx`) implement `IHttpHandler` + `IRequiresSessionState`, call `SesionHelper.VerificarSesion` first, then route on a query-string `action` param and return HTML fragments or JSON. User type (`tipo_id`: 1=Admin, 2=Gerente, 3=Cajero/Vendedor) drives permissions inside handlers.

**Data access is stored-procedure-only.** All DB calls use `SqlCommand` with `CommandType.StoredProcedure` and `AddWithValue` parameters — never string-concatenated SQL. Every DB object is prefixed `FLORERIA_`. When a page errors with "expects parameter @X" or "IndexOutOfRange: field", fix the **SP** to match the VB, or add the missing parameter in VB — do not guess column names; read `03_TODOS_LOS_SPS.sql`.

**Module layout** lives under `Modulos/`: `Pedidos` (orders + the pre-order/PrePedido funnel, the most active area), `Catalogo` (products, categories, pricing), `Config` (users, menu permissions, settings, webhook monitor), `Delivery`, `Finanzas`.

**WooCommerce integration:** `App_Code/WooCommerceSync.vb` pushes products to a WC store via the REST API (credentials read from the `FLORERIA_Config` table by `clave`). Inbound webhooks land at public handlers `WebhookWC.ashx` / `WebhookCapture.ashx` and are logged to `FLORERIA_Webhook_Log`. The customer-facing pre-order confirmation lives in `/cliente/` (`index.aspx` + `Cliente_PublicHandler.ashx`). These public endpoints — plus `/cliente/`, `pp.aspx`, `formulario.aspx` — are explicitly **allowed anonymous** via `<location>` rules in `Web.config`; their security is enforced in code by validating a per-request token against `FLORERIA_PrePedido`.

## Project-specific conventions (important — these are real footguns here)

These are distilled from the `*.md` rule files in the repo root (`REGLAS_DEFINITIVAS_V3.md`, `CHECKLIST_OBLIGATORIO_VB.md`, `PROTOCOLO_ACTUALIZADO_FINAL.md`, `SECCION_VALIDACIONES_REGLAS.md`):

- **VB.NET is not C#.** Do not use `??`, `?.`, or `New With {...}` anonymous types (define a named `Class` instead). Use explicit types and `If x IsNot Nothing Then` null guards. Read hidden form fields with `Request.Form("hdX")`.
- **`App_Code/*.vb` files have NO `Namespace`** (e.g. `Public Class SesionHelper` directly). Every `.aspx.vb` code-behind **does** use `Namespace SISCONBOL_FLORERIA`. Getting this wrong yields "X is not declared" or "Could not load type" errors.
- **`.aspx` files must be ASCII-only in visible HTML** (labels, placeholders, option text, section titles): no accents, `ñ`, `¿`, `¡`, `°`. Write "Peru", "codigo", "Configuracion". Accents ARE allowed in DB data, in VB strings, in HTML comments, and inside JS function bodies. Save `.aspx` as UTF-8 with BOM. (Garbled `Â¿QuÃ©?` on screen = accents leaked into `.aspx`.)
- **Tabler icons need two classes:** `<i class="ti ti-home">`. In the `FLORERIA_Menu` table store only `ti-home`; `SesionHelper` prepends `ti ` when generating menu HTML. The icon webfont is loaded from a CDN in `Site.Master`.
- **CSS is global in `Estilos/site.css`; JS is global in `Scripts/site.js`.** Use `:root` variables (`--rosa`, `--gris`, `--verde`) and the unified `.form-control` class for all inputs/selects/textareas. Never modify base layout classes (`.layout`, `.sidebar`, `.main`, `.topbar`, `.nav-item`, `.nav-child`, etc.) or create `.form-input`/`.form-select`/`.form-textarea`. Per-page CSS goes in `HeadContent`.
- **Validate every user input in three layers** (`SECCION_VALIDACIONES_REGLAS.md`): JS (`Scripts/validaciones.js`, UX), VB (`App_Code/Validador.vb`, real security — `Validador.TienePatronPeligroso`, `ValidarFormularioPrePedido`, etc.), and SQL (`FLORERIA_fn_ValidarTexto`, `FLORERIA_fn_ValidarCelular` via `RAISERROR`). `Web.config` sets `validateRequest="false"`, so backend validation is the actual defense against SQL injection / XSS.
- **HTML field-name discipline:** read code-behind values with the exact `name=""` attribute from the `.aspx` (the repo notes are full of `txCelular` vs `txtCelular` bugs). When an SP returns a result set, read it with `ExecuteReader()`, not `ExecuteNonQuery()`.

## Conventions when working here

- The rule files repeatedly stress: **don't invent schema, column names, SP return shapes, or control names — read the actual file first.** "If I don't see it in the code, it doesn't exist."
- Don't declare something "working" without building cleanly (no errors in the VS Output window) and confirming the rendered result.
