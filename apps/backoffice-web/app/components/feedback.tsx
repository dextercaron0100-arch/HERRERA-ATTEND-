import { AlertCircle, CheckCircle2, LoaderCircle } from 'lucide-react';

export function LoadingPanel({ label = 'Loading live data…' }: { label?: string }) {
  return <div className="inlineState" role="status"><LoaderCircle className="spin" size={20}/><span>{label}</span></div>;
}

export function ErrorPanel({ message, retry }: { message: string; retry: () => void }) {
  return <div className="inlineState errorState" role="alert"><AlertCircle size={20}/><div><strong>Unable to load data</strong><span>{message}</span></div><button type="button" className="small secondary" onClick={retry}>Try again</button></div>;
}

export function SuccessMessage({ message }: { message: string }) {
  return <div className="successMessage" role="status"><CheckCircle2 size={16}/>{message}</div>;
}
