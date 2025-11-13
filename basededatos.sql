2.2. Pegar el SQL de la base de datos

Con el proyecto ventas creado:

En el panel izquierdo, ve a “SQL”.

Haz clic en “New query” o “+ New”.

En la ventana en blanco, pega este SQL COMPLETO:

-- ========================================================
-- 1) USUARIOS
-- Se relaciona 1 a 1 con auth.users (id = id de Supabase Auth)
-- ========================================================

create table if not exists public.usuarios (
  id uuid primary key
    references auth.users (id) on delete cascade,
  nombre text,
  telefono text,
  es_admin boolean default false,
  creado_en timestamptz default now()
);

-- ========================================================
-- 2) CATEGORIAS (JERÁRQUICAS)
-- parent_id = NULL  -> categoría principal
-- parent_id = id    -> subcategoría
-- incluye imagen_url
-- ========================================================

create table if not exists public.categorias (
  id bigserial primary key,
  parent_id bigint
    references public.categorias (id) on delete cascade,
  nombre text not null,
  slug text unique,
  descripcion text,
  imagen_url text,   -- <-- NUEVO CAMPO PARA IMÁGENES
  orden integer,
  activa boolean default true
);

-- ========================================================
-- 3) PRODUCTOS
-- Pertecen a categorías/subcategorías
-- ========================================================

create table if not exists public.productos (
  id bigserial primary key,
  categoria_id bigint not null
    references public.categorias (id),
  nombre text not null,
  descripcion text,
  precio numeric(10,2) not null,
  moneda char(3) not null default 'PEN',
  stock integer not null default 0,
  imagen_url text,
  activo boolean default true,
  creado_en timestamptz default now(),
  actualizado_en timestamptz default now()
);

-- ========================================================
-- 4) ORDENES
-- Todas las órdenes realizadas por usuarios
-- ========================================================

create table if not exists public.ordenes (
  id bigserial primary key,
  usuario_id uuid not null
    references public.usuarios (id),
  total numeric(10,2) not null,
  moneda char(3) not null default 'PEN',
  estado text not null check (
    estado in ('pendiente_pago', 'pagada', 'expirada', 'cancelada')
  ),
  metodo_pago text not null default 'YAPE',
  vence_en timestamptz not null,
  pagada_en timestamptz,
  cancelada_en timestamptz,
  motivo_cancelacion text,
  comentario_admin text,
  creado_en timestamptz default now(),
  actualizado_en timestamptz default now()
);

-- ========================================================
-- 5) ORDEN_ITEMS
-- Detalle de productos dentro de cada orden
-- ========================================================

create table if not exists public.orden_items (
  id bigserial primary key,
  orden_id bigint not null
    references public.ordenes (id) on delete cascade,
  producto_id bigint not null
    references public.productos (id),
  producto_nombre text not null,
  cantidad integer not null,
  precio_unitario numeric(10,2) not null,
  subtotal numeric(10,2) not null
);


Haz clic en “Run” (botón arriba a la derecha).

Si todo está bien, no verás errores y las tablas quedarán creadas.

Para verificar:

Ve a Database → Tables (o “Table editor”).

Deberías ver:

usuarios

categorias

productos

ordenes

orden_items

Listo, la BD ventas (tu proyecto) ya tiene su estructura.

2.3. Crear el bucket para las imágenes

En el menú de la izquierda, ve a “Storage”.

Haz clic en “Create bucket”.

Nombre del bucket: productos.

Marca como público (o luego le hacemos una policy pública de lectura).

Crea el bucket.

Cada vez que subas una imagen, Supabase te dará una URL pública.
Esa URL la vas a guardar en el campo imagen_url de la tabla productos.
