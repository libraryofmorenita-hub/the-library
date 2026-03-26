// ─────────────────────────────────────────────
// Library of Morenita — Supabase Config
// ─────────────────────────────────────────────
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm'

const SUPABASE_URL = 'https://agekvrkqrwepdoeetpbx.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_kI_ZQE18Z5WRPhkzvaJoxQ_qvgV19_Y'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

// ── ROLES ──
export const ROLES = {
  LIBRARIAN: 'librarian',   // Amelia — full access
  CURATOR:   'curator',     // Inner team
  FELLOW:    'fellow',      // Journalists & artists
  READER:    'reader',      // Students / learners
}

// ── GET CURRENT USER + PROFILE ──
export async function getCurrentUser() {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  return { ...user, profile }
}

// ── ROLE CHECKS ──
export function isLibrarian(profile) { return profile?.role === ROLES.LIBRARIAN }
export function isCurator(profile)   { return profile?.role === ROLES.CURATOR || isLibrarian(profile) }
export function isFellow(profile)    { return profile?.role === ROLES.FELLOW || isCurator(profile) }
export function canPublish(profile)  { return isCurator(profile) }
export function canWrite(profile)    { return isFellow(profile) }

// ── SCROLL LIMIT (Readers: 20 articles/week) ──
export const WEEKLY_SCROLL_LIMIT = 20

export async function checkScrollLimit(userId) {
  const { data: profile } = await supabase
    .from('profiles')
    .select('scroll_count_this_week, scroll_reset_date, role')
    .eq('id', userId)
    .single()

  if (!profile) return { allowed: false, remaining: 0 }
  if (profile.role !== ROLES.READER) return { allowed: true, remaining: Infinity }

  // Reset weekly count if needed
  const resetDate = new Date(profile.scroll_reset_date)
  const now = new Date()
  const daysSinceReset = (now - resetDate) / (1000 * 60 * 60 * 24)

  if (daysSinceReset >= 7) {
    await supabase.from('profiles').update({
      scroll_count_this_week: 0,
      scroll_reset_date: now.toISOString()
    }).eq('id', userId)
    return { allowed: true, remaining: WEEKLY_SCROLL_LIMIT }
  }

  const remaining = WEEKLY_SCROLL_LIMIT - (profile.scroll_count_this_week || 0)
  return { allowed: remaining > 0, remaining: Math.max(0, remaining) }
}

export async function logScroll(userId, articleId) {
  await supabase.from('scroll_log').insert({ user_id: userId, article_id: articleId })
  await supabase.rpc('increment_scroll_count', { user_id_input: userId })
}

// ── SIGN OUT ──
export async function signOut() {
  await supabase.auth.signOut()
  window.location.href = 'index.html'
}
