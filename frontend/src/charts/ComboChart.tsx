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
  wydatki: number;
  przychody: number;
  stan_konta: number | null;
}

interface PredictionPoint {
  monthIndex: number;
  value: number;
}

interface ComboChartProps {
  data: ComboDataPoint[];
  prediction: PredictionPoint[];
  onMonthClick?: (month: string) => void;
}

export default function ComboChart({ data, prediction, onMonthClick }: ComboChartProps) {
  if (!data || data.length === 0) {
    return (
      <div className="flex items-center justify-center h-[350px] border border-slate-800 rounded-xl bg-slate-900/40 text-slate-500 text-sm">
        Not enough data to display chart
      </div>
    );
  }

  // Merge prediction values into the chart data
  const mergedData = data.map((d, index) => ({
    ...d,
    prediction: prediction[index]?.value ?? null,
  }));

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
        <YAxis stroke="#94a3b8" />
        <Tooltip
          contentStyle={{
            backgroundColor: '#0f172a',
            borderColor: '#334155',
            color: '#f8fafc',
          }}
        />
        <Legend
          wrapperStyle={{
            paddingTop: '10px',
          }}
        />
        <Bar dataKey="wydatki" fill="#ef4444" name="Wydatki" radius={[4, 4, 0, 0]} />
        <Line type="monotone" dataKey="przychody" stroke="#22c55e" strokeWidth={2} name="Przychody" />
        <Line type="monotone" dataKey="stan_konta" stroke="#3b82f6" strokeWidth={2} name="Stan konta" />
        <Line
          type="monotone"
          dataKey="prediction"
          stroke="#f59e0b"
          strokeWidth={2}
          strokeDasharray="8 4"
          connectNulls
          name="Predykcja"
        />
      </ComposedChart>
    </ResponsiveContainer>
  );
}
