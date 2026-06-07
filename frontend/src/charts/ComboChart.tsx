import React from 'react';
import {
  ComposedChart,
  Bar,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

interface ComboDataPoint {
  month: string;
  expenses: number;
  income: number;
  balance: number | null;
}

interface PredictionPoint {
  monthIndex: number;
  value: number;
}

interface ComboChartProps {
  data: ComboDataPoint[];
  prediction: PredictionPoint[];
  aiForecast?: PredictionPoint[];
  onMonthClick?: (month: string) => void;
}

export default function ComboChart({ data, prediction, aiForecast, onMonthClick }: ComboChartProps) {
  const formatCurrency = (val: number) =>
    new Intl.NumberFormat('pl-PL', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(val);

  const formatYAxis = (val: number) =>
    new Intl.NumberFormat('pl-PL', {
      maximumFractionDigits: 0,
    }).format(val);

  if (!data || data.length === 0) {
    return (
      <div className="flex items-center justify-center h-[350px] border border-slate-800 rounded-xl bg-slate-900/40 text-slate-500 text-sm">
        Brak wystarczającej ilości danych do wyświetlenia wykresu
      </div>
    );
  }

  // Merge prediction values into the chart data
  const mergedData = data.map((d, index) => ({
    ...d,
    prediction: prediction[index]?.value ?? null,
    aiForecast: aiForecast?.find(p => p.monthIndex === index)?.value ?? null,
  }));

  // Add phantom next-month entry if AI forecast extends beyond data
  const nextMonthForecast = aiForecast?.find(p => p.monthIndex === data.length);
  if (nextMonthForecast) {
    const lastMonth = data[data.length - 1].month;
    const [y, m] = lastMonth.split('-').map(Number);
    const nextDate = new Date(y, m, 1);
    const nextLabel = `${nextDate.getFullYear()}-${String(nextDate.getMonth() + 1).padStart(2, '0')}`;
    mergedData.push({
      month: nextLabel,
      expenses: 0,
      income: 0,
      balance: null,
      prediction: null,
      aiForecast: nextMonthForecast.value,
    } as any);
  }

  return (
    <ResponsiveContainer width="100%" height={350}>
      <ComposedChart
        data={mergedData}
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
        <Legend
          wrapperStyle={{
            paddingTop: '10px',
          }}
        />
        <Bar dataKey="expenses" fill="#ef4444" name="Wydatki" radius={[4, 4, 0, 0]} />
        <Line type="monotone" dataKey="income" stroke="#22c55e" strokeWidth={2} name="Przychody" />
        <Line type="monotone" dataKey="balance" stroke="#3b82f6" strokeWidth={2} name="Stan konta" />
        <Line
          type="monotone"
          dataKey="prediction"
          stroke="#f59e0b"
          strokeWidth={2}
          strokeDasharray="8 4"
          connectNulls
          name="Predykcja (LR)"
        />
        <Line
          type="monotone"
          dataKey="aiForecast"
          stroke="#06b6d4"
          strokeWidth={2}
          strokeDasharray="4 4"
          connectNulls
          name="Predykcja (AI)"
        />
      </ComposedChart>
    </ResponsiveContainer>
  );
}
