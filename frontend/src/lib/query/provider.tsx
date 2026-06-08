import { QueryClientProvider } from '@tanstack/react-query';
import { useEffect, useRef } from 'react';
import { authClient } from '../auth-client';
import { queryClient } from './client';

export function useUserId(): string | undefined {
  const { data: session } = authClient.useSession();
  return session?.user?.id;
}

export function CacheManager() {
  const { data: session } = authClient.useSession();
  const prevSessionRef = useRef(session);

  useEffect(() => {
    const prev = prevSessionRef.current;
    const curr = session;

    if ((!prev && curr) || (prev && !curr)) {
      queryClient.clear();
    }

    prevSessionRef.current = curr;
  }, [session]);

  return null;
}

export function QueryProvider({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <CacheManager />
      {children}
    </QueryClientProvider>
  );
}
