import { useEffect, useState, type FormEvent, type ReactNode } from 'react';
import type { Session } from '@supabase/supabase-js';
import { ArrowRight, LockKeyhole, ShieldCheck, UserPlus, Zap } from 'lucide-react';
import { supabase } from '@/lib/supabase';

interface AuthGateProps { children: ReactNode; }

export default function AuthGate({ children }: AuthGateProps) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [signUp, setSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('Nagaraj K H');
  const [message, setMessage] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    let mounted = true;
    supabase.auth.getSession().then(({ data }) => { if (mounted) { setSession(data.session); setLoading(false); } });
    const { data: listener } = supabase.auth.onAuthStateChange((_event, currentSession) => {
      setSession(currentSession);
      setLoading(false);
    });
    return () => { mounted = false; listener.subscription.unsubscribe(); };
  }, []);

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);
    setMessage('');
    const result = signUp
      ? await supabase.auth.signUp({ email, password, options: { data: { display_name: displayName } } })
      : await supabase.auth.signInWithPassword({ email, password });
    if (result.error) setMessage('We could not complete that request. Check your details and try again.');
    else if (signUp && !result.data.session) setMessage('Account created. Check your email if confirmation is required, then sign in.');
    setSubmitting(false);
  };

  if (loading) return <div className="auth-loading"><Zap size={20} /> Loading secure workspace…</div>;
  if (session) return <>{children}</>;
  return <main className="auth-screen"><div className="auth-orbit" /><section className="auth-card"><div className="auth-brand"><span><Zap size={18} /></span><strong>COMMIT<span>/</span>CREW</strong></div><div className="section-kicker"><ShieldCheck size={14} /> Secure administrator access</div><h1>{signUp ? 'Create your command account.' : 'Welcome back, operator.'}</h1><p>Manage every student, company and interview decision from one protected workspace.</p><form onSubmit={submit}>{signUp && <label>Display name<input value={displayName} onChange={(event) => setDisplayName(event.target.value)} required /></label>}<label>Administrator email<input type="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="admin@college.edu" required /></label><label>Password<input type="password" value={password} onChange={(event) => setPassword(event.target.value)} minLength={6} placeholder="At least 6 characters" required /></label>{message && <div className="auth-message">{message}</div>}<button className="primary-button auth-submit" disabled={submitting}>{submitting ? 'Connecting…' : signUp ? <><UserPlus size={15} /> Create account</> : <><LockKeyhole size={15} /> Enter workspace</>}<ArrowRight size={15} /></button></form><button className="auth-toggle" onClick={() => { setSignUp(!signUp); setMessage(''); }}>{signUp ? 'Already have an account? Sign in' : 'New administrator? Create an account'}</button></section></main>;
}
