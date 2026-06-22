-- Component categories and parts
CREATE TABLE component_categories (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  icon TEXT,
  display_order INT DEFAULT 0
);

CREATE TABLE components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id INT REFERENCES component_categories(id),
  name TEXT NOT NULL,
  brand TEXT NOT NULL,
  model TEXT,
  specs JSONB NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  currency TEXT DEFAULT 'JOD',
  image_url TEXT,
  performance_score INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_components_category ON components(category_id);
CREATE INDEX idx_components_price ON components(price);

-- Saved builds
CREATE TABLE builds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  description TEXT,
  build_type TEXT CHECK (build_type IN ('gaming', 'workstation', 'budget', 'custom')),
  components JSONB NOT NULL,
  total_price DECIMAL(10,2),
  is_public BOOLEAN DEFAULT FALSE,
  likes_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_builds_user ON builds(user_id);
CREATE INDEX idx_builds_public ON builds(is_public);

-- Price history
CREATE TABLE price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  component_id UUID REFERENCES components(id) ON DELETE CASCADE,
  price DECIMAL(10,2) NOT NULL,
  store_name TEXT,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_price_history_component ON price_history(component_id);

-- Community features
CREATE TABLE build_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  build_id UUID REFERENCES builds(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE build_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  build_id UUID REFERENCES builds(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(build_id, user_id)
);

CREATE TABLE user_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID REFERENCES auth.users(id),
  following_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- Build challenges
CREATE TABLE challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  challenge_type TEXT CHECK (challenge_type IN ('budget', 'quiet', 'itx', 'performance')),
  constraints JSONB,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE challenge_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  build_id UUID REFERENCES builds(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  votes_count INT DEFAULT 0
);

-- Price alerts
CREATE TABLE price_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  component_id UUID REFERENCES components(id) ON DELETE CASCADE,
  target_price DECIMAL(10,2) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User profiles
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT UNIQUE,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE component_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE components ENABLE ROW LEVEL SECURITY;
ALTER TABLE builds ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE build_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE build_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Public read for components and categories
CREATE POLICY "read_categories" ON component_categories FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_components" ON components FOR SELECT TO authenticated USING (true);

-- Build policies
CREATE POLICY "read_own_builds" ON builds FOR SELECT TO authenticated 
  USING (auth.uid() = user_id OR is_public = true);
CREATE POLICY "insert_own_builds" ON builds FOR INSERT TO authenticated 
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update_own_builds" ON builds FOR UPDATE TO authenticated 
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_builds" ON builds FOR DELETE TO authenticated 
  USING (auth.uid() = user_id);

-- Profile policies
CREATE POLICY "read_profiles" ON profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "insert_own_profile" ON profiles FOR INSERT TO authenticated 
  WITH CHECK (auth.uid() = id);
CREATE POLICY "update_own_profile" ON profiles FOR UPDATE TO authenticated 
  USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Comments
CREATE POLICY "read_comments" ON build_comments FOR SELECT TO authenticated USING (true);
CREATE POLICY "insert_own_comments" ON build_comments FOR INSERT TO authenticated 
  WITH CHECK (auth.uid() = user_id);

-- Likes
CREATE POLICY "read_likes" ON build_likes FOR SELECT TO authenticated USING (true);
CREATE POLICY "insert_own_likes" ON build_likes FOR INSERT TO authenticated 
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_likes" ON build_likes FOR DELETE TO authenticated 
  USING (auth.uid() = user_id);

-- Follows
CREATE POLICY "read_follows" ON user_follows FOR SELECT TO authenticated USING (true);
CREATE POLICY "insert_own_follows" ON user_follows FOR INSERT TO authenticated 
  WITH CHECK (auth.uid() = follower_id);

-- Challenges
CREATE POLICY "read_challenges" ON challenges FOR SELECT TO authenticated USING (true);
CREATE POLICY "read_submissions" ON challenge_submissions FOR SELECT TO authenticated USING (true);

-- Price alerts
CREATE POLICY "read_own_alerts" ON price_alerts FOR SELECT TO authenticated 
  USING (auth.uid() = user_id);
CREATE POLICY "insert_own_alerts" ON price_alerts FOR INSERT TO authenticated 
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "delete_own_alerts" ON price_alerts FOR DELETE TO authenticated 
  USING (auth.uid() = user_id);

-- Insert default component categories
INSERT INTO component_categories (name, icon, display_order) VALUES
('CPU', 'cpu', 1),
('GPU', 'gpu', 2),
('RAM', 'memory', 3),
('Motherboard', 'motherboard', 4),
('SSD', 'storage', 5),
('PSU', 'power', 6),
('Case', 'case', 7),
('Cooler', 'cooling', 8);