import React from 'react';

export interface Category {
  id: string;
  name: string;
}

interface CategoryDropdownProps {
  categories: Category[];
  value: string;
  onChange: (categoryId: string) => void;
  label?: string;
  includeUncategorized?: boolean;
  id?: string;
}

export default function CategoryDropdown({
  categories,
  value,
  onChange,
  label,
  includeUncategorized = false,
  id = 'category-select',
}: CategoryDropdownProps) {
  return (
    <div className="w-full">
      {label && (
        <label
          htmlFor={id}
          className="text-slate-300 text-sm font-semibold mb-2 block"
        >
          {label}
        </label>
      )}
      <select
        id={id}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full bg-slate-950 border border-slate-800 rounded-lg px-4 py-3 text-slate-200 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 transition-colors text-sm"
      >
        {categories.length === 0 ? (
          <option value="" disabled>
            Loading categories...
          </option>
        ) : (
          <>
            {includeUncategorized && (
              <option value="">— (uncategorized)</option>
            )}
            {categories.map((cat) => (
              <option key={cat.id} value={cat.id}>
                {cat.name}
              </option>
            ))}
          </>
        )}
      </select>
    </div>
  );
}
