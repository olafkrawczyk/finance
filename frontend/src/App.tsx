import React, { useState, useEffect } from 'react';
import ImportUpload from './components/ImportUpload';
import ImportStatus from './components/ImportStatus';
import DashboardPage from './pages/DashboardPage';
import SummaryPage from './pages/SummaryPage';
import MonthlyPage from './pages/MonthlyPage';
import CategorizePage from './pages/CategorizePage';
import AddTransactionPage from './pages/AddTransactionPage';
import InsightsPage from './pages/InsightsPage';
import AssetsPage from './pages/AssetsPage';
import AccountPage from './pages/AccountPage';
import MigrationPage from './pages/MigrationPage';
import { authClient } from './lib/auth-client';
import LoginPage from './pages/LoginPage';

export default function App() {
  const { data: session, isPending } = authClient.useSession();
  const [currentPath, setCurrentPath] = useState<string>(window.location.pathname);

  useEffect(() => {
    const handleLocationChange = () => {
      setCurrentPath(window.location.pathname);
    };

    window.addEventListener('popstate', handleLocationChange);
    return () => {
      window.removeEventListener('popstate', handleLocationChange);
    };
  }, []);

  const navigateTo = (path: string) => {
    window.history.pushState(null, '', path);
    setCurrentPath(path);
  };

  // Minimal Router
  const renderContent = () => {
    if (currentPath === '/login') {
      return <LoginPage onSuccess={() => navigateTo('/dashboard')} />;
    }

    if (currentPath === '/dashboard' || currentPath === '/') {
      return <DashboardPage onMonthClick={(month: string) => navigateTo(`/month/${month}`)} onAssetsClick={() => navigateTo('/assets')} />;
    }

    if (currentPath === '/assets') {
      return <AssetsPage />;
    }

    if (currentPath === '/accounts') {
      return <AccountPage />;
    }

    if (currentPath === '/summary') {
      return <SummaryPage />;
    }

    if (currentPath.startsWith('/month/')) {
      const yearMonth = currentPath.substring('/month/'.length);
      return <MonthlyPage yearMonth={yearMonth} />;
    }

    if (currentPath === '/categorize') {
      return <CategorizePage />;
    }

    if (currentPath.startsWith('/transactions/') && currentPath.endsWith('/edit')) {
      const segments = currentPath.split('/');
      const transactionId = segments[2];
      return <AddTransactionPage transactionId={transactionId} onSuccess={() => navigateTo('/dashboard')} />;
    }

    if (currentPath === '/add') {
      return <AddTransactionPage onSuccess={() => navigateTo('/dashboard')} />;
    }

    if (currentPath === '/insights') {
      return <InsightsPage />;
    }

    if (currentPath === '/migration') {
      return <MigrationPage onMigrationComplete={() => navigateTo('/dashboard')} />;
    }

    if (currentPath === '/import') {
      return (
        <ImportUpload
          onImportStarted={(jobId) => {
            navigateTo(`/import/${jobId}`);
          }}
        />
      );
    }

    if (currentPath.startsWith('/import/')) {
      const jobId = currentPath.substring('/import/'.length);
      return (
        <ImportStatus
          jobId={jobId}
          onBack={() => navigateTo('/import')}
          onCategorize={() => navigateTo('/categorize')}
        />
      );
    }

    return (
      <div className="text-center p-8">
        <h2 className="text-2xl font-bold text-red-500">404 - Nie znaleziono strony</h2>
        <button
          onClick={() => navigateTo('/dashboard')}
          className="mt-4 px-6 py-2 bg-blue-600 rounded-lg text-white font-medium"
        >
          Przejdź do Dashboardu
        </button>
      </div>
    );
  };

  // Auth guard — loading state
  if (isPending) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-500" />
      </div>
    );
  }

  // Auth guard — no session, show login page only (no header, no footer)
  if (!session) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <LoginPage onSuccess={() => navigateTo('/dashboard')} />
      </div>
    );
  }

  // Authenticated — full app layout with header (nav + email + logout) and footer
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between font-sans antialiased selection:bg-blue-500/30">
      {/* Header */}
      <header className="border-b border-slate-900 bg-slate-950/60 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-6 py-4 flex justify-between items-center">
          <div className="flex items-center space-x-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center font-bold text-white shadow-lg shadow-blue-500/20">
              F
            </div>
            <span className="text-lg font-semibold tracking-tight text-white">
              Finance<span className="text-blue-500">Flow</span>
            </span>
          </div>
          <div className="flex items-center space-x-1">
            <nav className="flex flex-wrap space-x-1">
              <button
                onClick={() => navigateTo('/dashboard')}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                  currentPath === '/dashboard' || currentPath === '/'
                    ? 'bg-slate-900 text-blue-400'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Dashboard
              </button>
              <button
                onClick={() => navigateTo('/assets')}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                  currentPath === '/assets'
                    ? 'bg-slate-900 text-blue-400'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Aktywa
              </button>
              <button
                onClick={() => navigateTo('/accounts')}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                  currentPath === '/accounts'
                    ? 'bg-slate-900 text-blue-400'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Konta
              </button>
              <button
                onClick={() => navigateTo('/summary')}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                  currentPath.startsWith('/summary')
                    ? 'bg-slate-900 text-blue-400'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Zbiorczy
              </button>
              <button
                onClick={() => navigateTo('/categorize')}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                  currentPath.startsWith('/categorize')
                    ? 'bg-slate-900 text-blue-400'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Kategoryzuj
              </button>
              <button
                onClick={() => navigateTo('/add')}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                  currentPath.startsWith('/add')
                    ? 'bg-slate-900 text-blue-400'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Dodaj
              </button>
              <button
                onClick={() => navigateTo('/import')}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                  currentPath.startsWith('/import')
                    ? 'bg-slate-900 text-blue-400'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Import CSV
              </button>
              <button
                onClick={() => navigateTo('/insights')}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                  currentPath.startsWith('/insights')
                    ? 'bg-slate-900 text-blue-400'
                    : 'text-slate-400 hover:text-slate-200'
                }`}
              >
                Analizy
              </button>
            </nav>
            {/* User info + logout */}
            <div className="flex items-center space-x-3 ml-4">
              <span className="text-sm text-slate-400">{session.user.email}</span>
              <button
                onClick={async () => {
                  await authClient.signOut();
                }}
                className="text-sm text-slate-500 hover:text-slate-300 transition-colors"
              >
                Wyloguj
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-grow px-6 py-12 max-w-6xl mx-auto w-full">
        {renderContent()}
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-900/40 py-6 text-center text-xs text-slate-600">
        <p>&copy; {new Date().getFullYear()} FinanceFlow. Wszelkie prawa zastrzeżone.</p>
      </footer>
    </div>
  );
}
