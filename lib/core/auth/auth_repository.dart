import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de una operación de cuenta que la interfaz debe honrar.
///
/// Existe porque el borrado de cuenta anterior mostraba un `SnackBar` con el
/// texto `'Eliminar cuenta (placeholder)'` justo después de prometerle al
/// usuario, en un diálogo, que la acción era permanente y que se eliminarían
/// sus datos. Un `Future<void>` que se traga el error permite exactamente ese
/// tipo de mentira; un resultado explícito, no.
class AuthActionResult {
  const AuthActionResult._({
    required this.ok,
    this.messageEs,
    this.errorCode,
    this.requiresServerSupport = false,
  });

  const AuthActionResult.success({String? messageEs})
    : this._(ok: true, messageEs: messageEs);

  const AuthActionResult.failure({
    required String messageEs,
    String? errorCode,
    bool requiresServerSupport = false,
  }) : this._(
         ok: false,
         messageEs: messageEs,
         errorCode: errorCode,
         requiresServerSupport: requiresServerSupport,
       );

  final bool ok;
  final String? messageEs;
  final String? errorCode;

  /// True cuando la operación no puede completarse desde el cliente porque
  /// falta una función del servidor. Se distingue de un fallo genérico para
  /// que la interfaz pueda explicar el siguiente paso real al usuario.
  final bool requiresServerSupport;
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Enlace profundo al que vuelve el correo de recuperación.
  ///
  /// Debe estar dado de alta en Supabase → Authentication → URL Configuration,
  /// y el esquema `biog://` declarado en el manifiesto de Android y en el
  /// `Info.plist` de iOS. Mientras eso no exista, [sendPasswordReset] sigue
  /// enviando el correo: Supabase cae al `Site URL` configurado.
  static const String passwordResetRedirect = 'biog://auth/reset-password';

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Recuperación de contraseña ───────────────────────────────────────────

  /// Envía el correo de recuperación.
  ///
  /// Devuelve éxito incluso si el correo no está registrado, y es deliberado:
  /// responder "esa cuenta no existe" convertiría el formulario en un detector
  /// de qué correos tienen cuenta en Bio-G. Supabase se comporta igual.
  Future<AuthActionResult> sendPasswordReset({required String email}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      return const AuthActionResult.failure(
        messageEs: 'Escribe un correo electrónico válido.',
        errorCode: 'invalid_email',
      );
    }

    try {
      await _client.auth.resetPasswordForEmail(
        normalized,
        redirectTo: passwordResetRedirect,
      );
      return const AuthActionResult.success(
        messageEs:
            'Si ese correo tiene una cuenta, te enviamos un enlace para '
            'restablecer la contraseña. Revisa también la carpeta de spam.',
      );
    } on AuthException catch (e) {
      // Un límite de envíos es información útil; el resto se generaliza.
      // `statusCode` se compara como texto a propósito: su tipo concreto
      // (String? o int?) ha cambiado entre versiones de gotrue, y así el
      // código vale para ambas.
      final isRateLimit =
          e.message.toLowerCase().contains('rate') ||
          e.statusCode?.toString() == '429';
      return AuthActionResult.failure(
        messageEs: isRateLimit
            ? 'Se enviaron demasiadas solicitudes. Espera unos minutos e '
                  'inténtalo de nuevo.'
            : 'No se pudo enviar el correo de recuperación. Revisa tu '
                  'conexión e inténtalo de nuevo.',
        errorCode: e.statusCode?.toString(),
      );
    } catch (_) {
      return const AuthActionResult.failure(
        messageEs:
            'No se pudo enviar el correo de recuperación. Revisa tu conexión '
            'e inténtalo de nuevo.',
        errorCode: 'network',
      );
    }
  }

  /// Fija una contraseña nueva para la sesión actual.
  ///
  /// Se usa tras abrir el enlace del correo (Supabase deja una sesión de
  /// recuperación activa) y también desde el perfil para cambiarla a voluntad.
  Future<AuthActionResult> updatePassword({
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      return const AuthActionResult.failure(
        messageEs: 'La contraseña debe tener al menos 8 caracteres.',
        errorCode: 'weak_password',
      );
    }

    if (_client.auth.currentSession == null) {
      return const AuthActionResult.failure(
        messageEs:
            'El enlace de recuperación expiró. Solicita uno nuevo desde '
            '"¿Olvidaste tu contraseña?".',
        errorCode: 'no_session',
      );
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return const AuthActionResult.success(
        messageEs: 'Tu contraseña se actualizó correctamente.',
      );
    } on AuthException catch (e) {
      return AuthActionResult.failure(
        messageEs: 'No se pudo actualizar la contraseña: ${e.message}',
        errorCode: e.statusCode?.toString(),
      );
    } catch (_) {
      return const AuthActionResult.failure(
        messageEs: 'No se pudo actualizar la contraseña. Inténtalo de nuevo.',
        errorCode: 'unknown',
      );
    }
  }

  /// Vuelve a autenticar con la contraseña actual.
  ///
  /// Requisito de las tiendas antes de una acción destructiva: quien borra la
  /// cuenta tiene que demostrar que es el dueño de la sesión, y no alguien que
  /// tomó el teléfono desbloqueado.
  Future<AuthActionResult> reauthenticate({required String password}) async {
    final email = currentUser?.email;
    if (email == null || email.isEmpty) {
      return const AuthActionResult.failure(
        messageEs: 'No hay una sesión activa que verificar.',
        errorCode: 'no_session',
      );
    }

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return const AuthActionResult.success();
    } on AuthException catch (_) {
      return const AuthActionResult.failure(
        messageEs: 'La contraseña no es correcta.',
        errorCode: 'invalid_credentials',
      );
    } catch (_) {
      return const AuthActionResult.failure(
        messageEs: 'No se pudo verificar tu identidad. Revisa tu conexión.',
        errorCode: 'network',
      );
    }
  }

  /// Solicita al servidor el borrado definitivo de la cuenta.
  ///
  /// Un cliente NO puede borrar su propio usuario de `auth.users`: hace falta
  /// la llave de servicio, que jamás debe viajar dentro de la app. Por eso esto
  /// llama a una función de Postgres que el proyecto debe exponer:
  ///
  /// ```sql
  /// create or replace function public.request_account_deletion()
  /// returns void language plpgsql security definer as $$
  /// begin
  ///   delete from public.telemetry
  ///    where device_id in (select id from public.devices
  ///                         where user_id = auth.uid());
  ///   delete from public.device_crop_contexts             where user_id = auth.uid();
  ///   delete from public.device_yield_projection_configs  where user_id = auth.uid();
  ///   delete from public.crop_care_history                where user_id = auth.uid();
  ///   delete from public.devices                          where user_id = auth.uid();
  ///   delete from public.profiles                         where id = auth.uid();
  ///   delete from auth.users                              where id = auth.uid();
  /// end $$;
  /// ```
  ///
  /// Mientras esa función no exista, este método devuelve un fallo con
  /// [AuthActionResult.requiresServerSupport] en `true`, y la interfaz dice la
  /// verdad —"quedó solicitado, no borrado"— en vez de fingir que la cuenta
  /// desapareció.
  Future<AuthActionResult> requestAccountDeletion() async {
    if (currentUser == null) {
      return const AuthActionResult.failure(
        messageEs: 'No hay una sesión activa.',
        errorCode: 'no_session',
      );
    }

    try {
      await _client.rpc('request_account_deletion');
      return const AuthActionResult.success(
        messageEs: 'Tu cuenta y tus datos se eliminaron.',
      );
    } on PostgrestException catch (e) {
      // 42883 = undefined_function. PGRST202 = la función no está expuesta.
      final missing = e.code == '42883' || e.code == 'PGRST202';
      return AuthActionResult.failure(
        messageEs: missing
            ? 'El borrado de cuenta todavía no está habilitado en el '
                  'servidor. Escríbenos y lo procesamos manualmente.'
            : 'No se pudo eliminar la cuenta: ${e.message}',
        errorCode: e.code,
        requiresServerSupport: missing,
      );
    } catch (_) {
      return const AuthActionResult.failure(
        messageEs:
            'No se pudo eliminar la cuenta. Revisa tu conexión e inténtalo '
            'de nuevo.',
        errorCode: 'network',
      );
    }
  }
}
