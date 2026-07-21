import Link from 'next/link';

export default function NotFound() {
  return <section className="statePanel"><span className="stateIcon" aria-hidden="true">404</span><h1>Page not found</h1><p>The page may have moved or is not available to your role.</p><Link className="buttonLink" href="/">Return to overview</Link></section>;
}
