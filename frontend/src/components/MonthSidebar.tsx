import React from 'react';

interface IncomeSource {
  category: string;
  amount: number;
}

interface MonthSidebarProps {
  openingBalance: string | null;
  incomeByCategory: IncomeSource[];
  fixedCostTotal: number;
  nonFixedExpenses: number;
}

const fmt = (val: number | string | null): string => {
  if (val === null) return '—';
  const num = typeof val === 'string' ? parseFloat(val) : val;
  if (isNaN(num)) return '—';
  return new Intl.NumberFormat('pl-PL', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(num);
};

export default function MonthSidebar({
  openingBalance,
  incomeByCategory,
  fixedCostTotal,
  nonFixedExpenses,
}: MonthSidebarProps) {
  const totalIncome = incomeByCategory.reduce((sum, item) => sum + item.amount, 0);
  const totalExpenses = fixedCostTotal + nonFixedExpenses;

  const hasData =
    openingBalance !== null ||
    incomeByCategory.length > 0 ||
    fixedCostTotal > 0 ||
    nonFixedExpenses > 0;

  if (!hasData) {
    return (
      <div className="bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl p-6 text-center text-slate-500 text-sm">
        Brak danych dla tego miesiąca
      </div>
    );
  }

  return (
    <div className="bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl p-6 shadow-xl space-y-6">
      {/* Opening Balance */}
      <div>
        <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">
          Saldo otwarcia
        </h3>
        <p className="text-2xl font-semibold text-blue-400 font-mono">
          {fmt(openingBalance)}
        </p>
      </div>

      <hr className="border-slate-800" />

      {/* Income Sources */}
      <div>
        <div className="flex justify-between items-baseline mb-3">
          <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            Przychody
          </h3>
          {totalIncome > 0 && (
            <span className="text-xs font-mono text-green-400 font-medium">
              Suma: +{fmt(totalIncome)}
            </span>
          )}
        </div>
        {incomeByCategory.length === 0 ? (
          <p className="text-xs text-slate-500">Brak przychodów</p>
        ) : (
          <ul className="space-y-2 max-h-40 overflow-y-auto pr-1">
            {incomeByCategory.map((item) => (
              <li key={item.category} className="flex justify-between text-sm">
                <span className="text-slate-400">{item.category}</span>
                <span className="font-mono text-green-400 font-medium">
                  +{fmt(item.amount)}
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>

      <hr className="border-slate-800" />

      {/* Fixed Costs & Expenses */}
      <div>
        <div className="flex justify-between items-baseline mb-3">
          <h3 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            Koszty stałe i wydatki
          </h3>
          {totalExpenses > 0 && (
            <span className="text-xs font-mono text-red-400 font-medium">
              Suma: -{fmt(totalExpenses)}
            </span>
          )}
        </div>
        <div className="space-y-3">
          <div className="flex justify-between text-sm">
            <span className="text-slate-400 font-medium">Koszty stałe (ZUS, VAT, itp.)</span>
            <span className="font-mono text-red-400 font-medium">
              -{fmt(fixedCostTotal)}
            </span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-slate-400 font-medium">Pozostałe wydatki</span>
            <span className="font-mono text-red-400 font-medium">
              -{fmt(nonFixedExpenses)}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
