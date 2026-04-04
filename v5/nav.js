// ─────────────────────────────────────────────
// nav.js — shared auth-aware nav for all pages
// ─────────────────────────────────────────────
import { supabase, getCurrentUser, signOut, ROLES } from './supabase.js'

export async function initNav(activePage) {
  const user = await getCurrentUser()
  const profile = user?.profile

  // Find nav actions placeholder
  const navActions = document.querySelector('.nav-actions')
  if (!navActions) return

  if (user) {
    // Logged in state
    const roleLabel = {
      librarian: '⬡ Librarian',
      curator:   '◈ Curator',
      fellow:    '✦ Fellow',
      reader:    '◻ Reader',
    }[profile?.role] || '◻ Reader'

    navActions.innerHTML = `
      <span style="font-size:10px;letter-spacing:0.08em;text-transform:uppercase;color:var(--ink-faint);">${roleLabel}</span>
      <a href="profile.html" class="btn-ghost">${profile?.display_name || 'Profile'}</a>
      <button class="btn-solid" onclick="window.__signOut()">Sign Out</button>
    `
    window.__signOut = signOut

    // Show librarian/curator controls if applicable
    if (profile?.role === ROLES.LIBRARIAN || profile?.role === ROLES.CURATOR) {
      injectLibrarianBadge()
    }

    // Show scroll count for readers
    if (profile?.role === ROLES.READER) {
      injectScrollBadge(profile)
    }

  } else {
    // Logged out state
    navActions.innerHTML = `
      <a href="auth.html" class="btn-ghost">Sign In</a>
      <a href="auth.html#join" class="btn-solid">Join</a>
    `
  }

  // Set active nav link
  document.querySelectorAll('.nav-links a').forEach(a => {
    a.classList.remove('active')
    if (a.getAttribute('href') === activePage) a.classList.add('active')
  })
}

function injectLibrarianBadge() {
  const existing = document.getElementById('librarian-bar')
  if (existing) return
  const bar = document.createElement('div')
  bar.id = 'librarian-bar'
  bar.style.cssText = `
    background:rgba(139,74,42,0.08);
    border-bottom:1px solid rgba(139,74,42,0.15);
    padding:6px 40px;
    font-size:10px;
    letter-spacing:0.1em;
    text-transform:uppercase;
    color:var(--sienna);
    display:flex;
    align-items:center;
    gap:20px;
  `
  bar.innerHTML = `
    <span>⬡ Librarian View</span>
    <a href="admin.html" style="color:var(--sienna);text-decoration:none;border-bottom:1px solid rgba(139,74,42,0.3);padding-bottom:1px;">Review Submissions</a>
    <a href="admin.html#tracks" style="color:var(--sienna);text-decoration:none;border-bottom:1px solid rgba(139,74,42,0.3);padding-bottom:1px;">Approve Tracks</a>
  `
  const nav = document.querySelector('nav')
  if (nav) nav.after(bar)
}

function injectScrollBadge(profile) {
  const remaining = 20 - (profile.scroll_count_this_week || 0)
  const existing = document.getElementById('scroll-badge')
  if (existing) existing.remove()
  const badge = document.createElement('div')
  badge.id = 'scroll-badge'
  badge.style.cssText = `
    position:fixed;
    bottom:24px;
    right:24px;
    background:var(--ink);
    color:rgba(247,243,238,0.8);
    font-size:10px;
    letter-spacing:0.08em;
    text-transform:uppercase;
    padding:8px 14px;
    border-radius:2px;
    z-index:200;
    display:flex;
    align-items:center;
    gap:8px;
  `
  const color = remaining > 10 ? '#5A9E6A' : remaining > 5 ? '#C49A3C' : '#9B4A3A'
  badge.innerHTML = `
    <span style="width:6px;height:6px;border-radius:50%;background:${color};display:inline-block;"></span>
    ${remaining} pages this week
  `
  document.body.appendChild(badge)
}
