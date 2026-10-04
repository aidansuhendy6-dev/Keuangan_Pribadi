-- 1. Tabel Wallets (Dompet)
CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  balance DECIMAL(15,2) DEFAULT 0,
  icon_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Tabel Savings (Tabungan)
CREATE TABLE savings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  current_amount DECIMAL(15,2) DEFAULT 0,
  target_amount DECIMAL(15,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Tabel Deposits (Deposit)
CREATE TABLE deposits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  amount DECIMAL(15,2) DEFAULT 0,
  interest_rate DECIMAL(5,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Tabel Debts (Hutang)
CREATE TABLE debts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  total_amount DECIMAL(15,2) DEFAULT 0,
  remaining_amount DECIMAL(15,2) DEFAULT 0,
  due_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Tabel Transactions (Semua riwayat keluar-masuk uang)
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  amount DECIMAL(15,2) NOT NULL,
  description TEXT,
  category_type TEXT NOT NULL, -- 'wallet', 'saving', 'deposit', 'debt'
  category_id UUID NOT NULL,
  date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Insert Data Dummy sesuai gambar referensi Aidan
INSERT INTO wallets (name, balance) VALUES ('BCA', 2559500), ('Cash', 863000), ('Shopeepay', 358048);
INSERT INTO savings (name, current_amount) VALUES ('Tabungan Argand', 2610000), ('Khitan Argand', 3500000), ('Bayar Spaylater', 2800000);
INSERT INTO deposits (name, amount) VALUES ('Tagihan koko', 4400000), ('Deposit', 15412065);
INSERT INTO debts (name, total_amount, remaining_amount) VALUES ('Kartu Kredit BCA', 500000, 15000000), ('Spaylater', 8200000, 18000000);
