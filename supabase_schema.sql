-- AgendaMix 365 - Supabase Schema
-- Execute este script no SQL Editor do Supabase

-- =============================================
-- PROFILES
-- =============================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own profile" ON profiles
  FOR ALL USING (auth.uid() = id);

-- Trigger para criar profile ao registrar
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- =============================================
-- APPOINTMENTS (Compromissos)
-- =============================================
CREATE TABLE IF NOT EXISTS appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  location TEXT,
  category TEXT DEFAULT 'Pessoal',
  notes TEXT,
  repeat TEXT,
  notify_enabled BOOLEAN DEFAULT FALSE,
  notify_minutes_before INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own appointments" ON appointments
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- NOTES (Anotações)
-- =============================================
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT DEFAULT '',
  category TEXT DEFAULT 'Pessoal',
  tags TEXT[] DEFAULT '{}',
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own notes" ON notes
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- REMINDERS (Lembretes)
-- =============================================
CREATE TABLE IF NOT EXISTS reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  notes TEXT,
  due_date TIMESTAMPTZ NOT NULL,
  is_done BOOLEAN DEFAULT FALSE,
  alarm_enabled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own reminders" ON reminders
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- PEOPLE (Pessoas)
-- =============================================
CREATE TABLE IF NOT EXISTS people (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  photo_url TEXT,
  relationship TEXT,
  phone TEXT,
  whatsapp TEXT,
  email TEXT,
  address TEXT,
  notes TEXT,
  gift_ideas TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE people ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own people" ON people
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- SPECIAL DATES (Datas Especiais)
-- =============================================
CREATE TABLE IF NOT EXISTS special_dates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  person_id UUID REFERENCES people(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  type TEXT DEFAULT 'Aniversário',
  day INTEGER NOT NULL CHECK (day BETWEEN 1 AND 31),
  month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
  year INTEGER,
  alert_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE special_dates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own special_dates" ON special_dates
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- MEDICATIONS (Medicamentos)
-- =============================================
CREATE TABLE IF NOT EXISTS medications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  dosage TEXT,
  schedules TEXT[] DEFAULT '{}',
  stock_quantity INTEGER DEFAULT 0,
  stock_alert_at INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own medications" ON medications
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- HEALTH APPOINTMENTS (Consultas)
-- =============================================
CREATE TABLE IF NOT EXISTS health_appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  doctor_name TEXT,
  clinic TEXT,
  specialty TEXT,
  appointment_date TIMESTAMPTZ NOT NULL,
  coverage_type TEXT DEFAULT 'Particular',
  value NUMERIC(10,2),
  return_date TIMESTAMPTZ,
  notes TEXT,
  attachment_urls TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE health_appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own health_appointments" ON health_appointments
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- FINANCIAL ENTRIES (Lançamentos)
-- =============================================
CREATE TABLE IF NOT EXISTS financial_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  value NUMERIC(12,2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('receita', 'despesa', 'pagamento')),
  category TEXT DEFAULT 'Outros',
  date TIMESTAMPTZ NOT NULL,
  credit_card_id UUID,
  installments INTEGER,
  current_installment INTEGER,
  bank_name TEXT,
  notes TEXT,
  is_paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE financial_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own financial_entries" ON financial_entries
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- CREDIT CARDS (Cartões de Crédito)
-- =============================================
CREATE TABLE IF NOT EXISTS credit_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  bank TEXT NOT NULL,
  operator TEXT DEFAULT '',
  limit NUMERIC(12,2) NOT NULL DEFAULT 0,
  closing_day INTEGER NOT NULL CHECK (closing_day BETWEEN 1 AND 28),
  due_day INTEGER NOT NULL CHECK (due_day BETWEEN 1 AND 28),
  best_buy_day INTEGER NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE credit_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own credit_cards" ON credit_cards
  FOR ALL USING (auth.uid() = user_id);

-- FK de financial_entries para credit_cards
ALTER TABLE financial_entries
  ADD CONSTRAINT fk_credit_card
  FOREIGN KEY (credit_card_id) REFERENCES credit_cards(id) ON DELETE SET NULL;

-- =============================================
-- DOCUMENTS (Documentos)
-- =============================================
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  type TEXT DEFAULT 'Outros',
  file_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own documents" ON documents
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- STORAGE BUCKET
-- =============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can upload documents" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view own documents" ON storage.objects
  FOR SELECT USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own documents" ON storage.objects
  FOR DELETE USING (bucket_id = 'documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- =============================================
-- MEDICATION LOGS (Registro de doses tomadas)
-- =============================================
CREATE TABLE IF NOT EXISTS medication_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  taken_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  scheduled_time TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own medication_logs" ON medication_logs
  FOR ALL USING (auth.uid() = user_id);

-- =============================================
-- INDEXES para performance
-- =============================================
CREATE INDEX IF NOT EXISTS idx_appointments_user_date ON appointments (user_id, start_time);
CREATE INDEX IF NOT EXISTS idx_reminders_user_date ON reminders (user_id, due_date);
CREATE INDEX IF NOT EXISTS idx_notes_user ON notes (user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_special_dates_user ON special_dates (user_id, month, day);
CREATE INDEX IF NOT EXISTS idx_financial_entries_user_date ON financial_entries (user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_medications_user ON medications (user_id, name);
CREATE INDEX IF NOT EXISTS idx_medication_logs_user ON medication_logs (user_id, taken_at DESC);
CREATE INDEX IF NOT EXISTS idx_medication_logs_med ON medication_logs (medication_id, taken_at DESC);
