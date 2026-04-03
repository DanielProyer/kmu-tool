import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

function jsonResponse(body: object, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method Not Allowed' }, 405);
  }

  try {
    // 1. JWT des Callers pruefen
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return jsonResponse({ error: 'Nicht autorisiert' }, 401);
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user: caller }, error: authError } =
      await supabaseAdmin.auth.getUser(token);

    if (authError || !caller) {
      return jsonResponse({ error: 'Ungueltiger Token' }, 401);
    }

    // 2. Berechtigung pruefen: Admin oder GF
    const { data: adminRow } = await supabaseAdmin
      .from('admin_users')
      .select('id')
      .eq('user_id', caller.id)
      .maybeSingle();

    const isAdmin = adminRow != null;

    let callerRolle: string | null = null;
    let callerBetriebOwnerId: string | null = null;

    if (!isAdmin) {
      const { data: profile } = await supabaseAdmin
        .from('user_profiles')
        .select('rolle, betrieb_owner_id')
        .eq('id', caller.id)
        .maybeSingle();

      callerRolle = profile?.rolle ?? null;
      callerBetriebOwnerId = profile?.betrieb_owner_id ?? caller.id;

      if (callerRolle !== 'geschaeftsfuehrer') {
        return jsonResponse({
          error: 'Keine Berechtigung. Nur Admin oder Geschaeftsfuehrer duerfen User erstellen.'
        }, 403);
      }
    }

    // 3. Request Body parsen
    let body: any;
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: 'Ungueltiger Request Body' }, 400);
    }

    const {
      email,
      password,
      firma_name,
      rolle,
      betrieb_owner_id,
      admin_profil_id,
      send_reset_email,
    } = body;

    if (!email) {
      return jsonResponse({ error: 'E-Mail ist erforderlich' }, 400);
    }

    // 4. Berechtigungs-Logik
    const validRoles = ['geschaeftsfuehrer', 'vorarbeiter', 'mitarbeiter', 'kunde'];
    const targetRolle = rolle || 'mitarbeiter';

    if (!validRoles.includes(targetRolle)) {
      return jsonResponse({ error: `Ungueltige Rolle: ${targetRolle}` }, 400);
    }

    // Admin darf alles, GF darf nur Mitarbeiter fuer eigenen Betrieb
    if (!isAdmin) {
      if (targetRolle === 'geschaeftsfuehrer') {
        return jsonResponse({
          error: 'Nur Admin darf Geschaeftsfuehrer erstellen'
        }, 403);
      }

      // GF darf nur eigenen Betrieb
      if (betrieb_owner_id && betrieb_owner_id !== caller.id) {
        return jsonResponse({
          error: 'Darf nur Mitarbeiter fuer eigenen Betrieb erstellen'
        }, 403);
      }
    }

    // 5. Auth-User erstellen
    const userPassword = password || crypto.randomUUID().slice(0, 16);

    const { data: newUser, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password: userPassword,
        email_confirm: true,
      });

    if (createError) {
      // Pruefen ob User schon existiert
      if (createError.message?.includes('already been registered') ||
          createError.message?.includes('already exists')) {
        return jsonResponse({
          error: 'Ein Benutzer mit dieser E-Mail existiert bereits'
        }, 409);
      }
      console.error('Create user error:', createError);
      return jsonResponse({
        error: `Fehler beim Erstellen: ${createError.message}`
      }, 500);
    }

    const userId = newUser.user.id;

    // 6. user_profiles anlegen
    const effectiveBetriebOwnerId = targetRolle === 'geschaeftsfuehrer'
      ? userId  // GF ist sein eigener Betrieb-Owner
      : (betrieb_owner_id || (isAdmin ? null : caller.id));

    const { error: profileError } = await supabaseAdmin
      .from('user_profiles')
      .insert({
        id: userId,
        email: email,
        firma_name: firma_name || null,
        rolle: targetRolle,
        betrieb_owner_id: effectiveBetriebOwnerId,
      });

    if (profileError) {
      console.error('Profile insert error:', profileError);
      // User wurde erstellt, aber Profil fehlgeschlagen - nicht fatal
    }

    // 7. Fuer GFs: user_subscriptions anlegen (free Plan als Default)
    if (targetRolle === 'geschaeftsfuehrer') {
      const { error: subError } = await supabaseAdmin
        .from('user_subscriptions')
        .insert({
          user_id: userId,
          plan_id: 'free',
          status: 'active',
          gueltig_ab: new Date().toISOString().split('T')[0],
        });

      if (subError) {
        console.error('Subscription insert error:', subError);
      }
    }

    // 8. admin_kundenprofile.user_id updaten (wenn admin_profil_id gegeben)
    if (admin_profil_id) {
      const { error: updateError } = await supabaseAdmin
        .from('admin_kundenprofile')
        .update({ user_id: userId })
        .eq('id', admin_profil_id);

      if (updateError) {
        console.error('Admin profil update error:', updateError);
      }
    }

    // 9. Optional: Password-Reset-Mail senden
    if (send_reset_email) {
      const { error: resetError } = await supabaseAdmin.auth.admin.generateLink({
        type: 'recovery',
        email: email,
      });
      if (resetError) {
        console.error('Reset email error:', resetError);
      }
    }

    return jsonResponse({
      success: true,
      user_id: userId,
      message: `Benutzer ${email} erfolgreich erstellt`,
      password_set: !!password,
      reset_email_sent: !!send_reset_email,
    });

  } catch (error) {
    console.error('Unexpected error:', error);
    return jsonResponse({ error: 'Interner Serverfehler' }, 500);
  }
});
