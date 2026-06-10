import React from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';

interface BalanceDataPoint {
  month: string;
  stan_konta: number | null;
  wartosc_netto?: number | null;
}

interface BalanceChartProps {
  data: BalanceDataPoint[];
  onMonthClick?: (month: string) => void;
  showNetWorth?: boolean;
  onToggleNetWorth?: () => void;
}

export default function BalanceChart({
  data,
  onMonthClick,
  showNetWorth = true,
  onToggleNetWorth,
}: BalanceChartProps) {
  const filteredData = showNetWorth
    ? data.filter((d) => d.stan_konta !== null || d.wartosc_netto !== null)
    : data.filter((d) => d.stan_konta !== null);

  const formatCurrency = (val: number) =>
    new Intl.NumberFormat('pl-PL', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(val);

  const formatYAxis = (val: number) =>
    new Intl.NumberFormat('pl-PL', {
      maximumFractionDigits: 0,
    }).format(val);

  const renderLegend = (props: any) => {
    const { payload } = props;
    if (!payload || payload.length === 0) return null;
    return (
      <div className="flex gap-4 justify-center mt-2">
        {payload.map((entry: any, index: number) => (
          <div key={`legend-${index}`} className="flex items-center gap-1.5">
            <span
              className="w-2.5 h-2.5 rounded-full inline-block"
              style={{ backgroundColor: entry.color }}
            />
            <span className="text-xs text-slate-400">{entry.value}</span>
          </div>
        ))}
      </div>
    );
  };

  if (filteredData.length < 2) {
    return (
      <div className="flex items-center justify-center h-[300px] border border-slate-800 rounded-xl bg-slate-900/40 text-slate-500 text-sm">
        Brak wystarczającej ilości danych do wyświetlenia wykresu
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center gap-2 mb-2">
        <label className="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={showNetWorth}
            onChange={onToggleNetWorth}
            className="rounded border-slate-800 bg-slate-950 text-blue-500 focus:ring-blue-500 focus:ring-offset-0"
          />
          <span className="text-xs text-slate-400">
            {showNetWorth ? 'Ukryj wartość netto' : 'Pokaż wartość netto'}
          </span>
        </label>
      </div>

      <ResponsiveContainer width="100%" height={300}>
        <LineChart
          data={filteredData}
          onClick={(state) => {
            if (state?.activeLabel && onMonthClick) {
              onMonthClick(state.activeLabel);
            }
          }}
          margin={{ top: 5, right: 20, bottom: 5, left: 0 }}
        >
          <CartesianGrid stroke="#334155" strokeDasharray="3 3" />
          <XAxis dataKey="month" stroke="#94a3b8" />
          <YAxis stroke="#94a3b8" tickFormatter={formatYAxis} />
          <Tooltip
            contentStyle={{
              backgroundColor: '#0f172a',
              borderColor: '#334155',
              color: '#f8fafc',
            }}
            formatter={(value: any, name: any) => [formatCurrency(Number(value)), name]}
          />
          <Legend content={renderLegend} />
          <Line
            type="monotone"
            dataKey="stan_konta"
            stroke="#3b82f6"
            strokeWidth={2}
            name="Stan konta"
            activeDot={{ r: 6 }}
          />
          {showNetWorth && (
            <Line
              type="monotone"
              dataKey="wartosc_netto"
              stroke="#a855f7"
              strokeWidth={2}
              name="Wartość netto"
              dot={false}
              connectNulls={false}
            />
          )}
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
