CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  sku VARCHAR(64) NOT NULL,
  name VARCHAR(160) NOT NULL,
  description VARCHAR(500),
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  inventory_quantity INTEGER NOT NULL CHECK (inventory_quantity >= 0),
  CONSTRAINT uk_products_sku UNIQUE (sku)
);

CREATE TABLE customer_orders (
  id BIGSERIAL PRIMARY KEY,
  customer_email VARCHAR(254) NOT NULL,
  status VARCHAR(32) NOT NULL,
  total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
  created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE order_items (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES customer_orders(id) ON DELETE CASCADE,
  product_id BIGINT NOT NULL REFERENCES products(id),
  product_name VARCHAR(160) NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
