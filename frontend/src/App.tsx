import React, { useState, useEffect } from 'react';
import ImportUpload from './components/ImportUpload';
import ImportStatus from './components/ImportStatus';

export default function App() {
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
    if (currentPath === '/import' || currentPath === '/') {
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
        />
      );
    }

    return (
      <div className="text-center p-8">
        <h2 className="text-2xl font-bold text-red-500">404 - Page Not Found</h2>
        <button
          onClick={() => navigateTo('/import')}
          className="mt-4 px-6 py-2 bg-blue-600 rounded-lg text-white font-medium"
        >
          Go to Imports
        </button>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between font-sans antialiased selection:bg-blue-500/30">
      {/* Header */}
      <header className="border-b border-slate-900 bg-slate-950/60 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-6 py-4 flex justify-between items-center">
          <div className="flex items-center space-x-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center font-bold text-white shadow-lg shadow-blue-500/20">
              F
            </div>
            <span className="text-lg font-extrabold tracking-tight text-white">
              Finance<span className="text-blue-500">Flow</span>
            </span>
          </div>
          <nav className="flex space-x-1">
            <button
              onClick={() => navigateTo('/import')}
              className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
                currentPath.startsWith('/import') || currentPath === '/'
                  ? 'bg-slate-900 text-blue-400'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              CSV Ingestion
            </button>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-grow flex items-center justify-center px-6 py-12">
        {renderContent()}
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-900/40 py-6 text-center text-xs text-slate-600">
        <p>&copy; {new Date().getFullYear()} FinanceFlow. All rights reserved.</p>
      </footer>
    </div>
  );
}
