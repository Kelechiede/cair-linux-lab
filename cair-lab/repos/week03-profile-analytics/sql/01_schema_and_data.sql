-- Week 3: CAIR-style "Profile Analytics" mini schema
CREATE SCHEMA IF NOT EXISTS profiling;

DROP TABLE IF EXISTS profiling.sample_people;
CREATE TABLE profiling.sample_people (
  id            BIGSERIAL PRIMARY KEY,
  full_name     TEXT,
  email         TEXT,
  age           INT,
  city          TEXT,
  created_at    TIMESTAMP DEFAULT now()
);

INSERT INTO profiling.sample_people (full_name, email, age, city) VALUES
('Ada Lovelace','ada@example.com',36,'St. John''s'),
('Alan Turing','alan@example.com',41,'St. John''s'),
('Grace Hopper',NULL,85,'Mount Pearl'),
(NULL,'bad-email',-5,'St. John''s'),
('John Doe','john@example.com',NULL,NULL);

CREATE INDEX IF NOT EXISTS idx_sample_people_city ON profiling.sample_people(city);
CREATE INDEX IF NOT EXISTS idx_sample_people_email ON profiling.sample_people(email);
