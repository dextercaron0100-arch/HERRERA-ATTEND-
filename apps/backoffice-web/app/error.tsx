'use client';

export default function ErrorPage({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return <section className="statePanel" role="alert"><span className="stateIcon" aria-hidden="true">!</span><h1>We couldn’t load this page</h1><p>The service may be temporarily unavailable. Try the request again.</p><button type="button" onClick={reset}>Try again</button></section>;
}
