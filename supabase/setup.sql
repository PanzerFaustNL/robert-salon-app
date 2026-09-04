-- Robert Salon App - prototype Supabase setup
-- Run this in Supabase > SQL Editor after creating customers, services and appointments.
-- It keeps services readable by the app, but protects customer/appointment rows.
-- New appointment requests are written through one SECURITY DEFINER function.

alter table public.services enable row level security;
alter table public.customers enable row level security;
alter table public.appointments enable row level security;

-- Public app may only read active/bookable services.
drop policy if exists "Public can read bookable services" on public.services;
create policy "Public can read bookable services"
on public.services
for select
to anon, authenticated
using (active = true and bookable = true);

grant usage on schema public to anon, authenticated;
grant select on public.services to anon, authenticated;

-- Do not expose personal customer/appointment rows directly to anonymous users.
revoke all on table public.customers from anon;
revoke all on table public.appointments from anon;

create or replace function public.create_appointment_request(
  p_name text,
  p_email text,
  p_phone text,
  p_service_id bigint,
  p_starts_at timestamptz,
  p_idea text,
  p_placement text,
  p_consent_complete boolean
)
returns table (
  appointment_id bigint,
  customer_id bigint
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_customer_id bigint;
  v_appointment_id bigint;
begin
  select c.id
  into v_customer_id
  from public.customers c
  where lower(trim(c.email)) = lower(trim(p_email))
  order by c.id
  limit 1;

  if v_customer_id is null then
    insert into public.customers (name, email, phone)
    values (trim(p_name), lower(trim(p_email)), trim(p_phone))
    returning id into v_customer_id;
  else
    update public.customers
    set name = trim(p_name),
        phone = trim(p_phone)
    where id = v_customer_id;
  end if;

  insert into public.appointments (
    customer_id,
    service_id,
    starts_at,
    idea,
    placement,
    consent_complete,
    deposit_paid,
    status
  )
  values (
    v_customer_id,
    p_service_id,
    p_starts_at,
    trim(p_idea),
    trim(p_placement),
    coalesce(p_consent_complete, false),
    false,
    'requested'
  )
  returning id into v_appointment_id;

  return query select v_appointment_id, v_customer_id;
end;
$$;

revoke all on function public.create_appointment_request(
  text, text, text, bigint, timestamptz, text, text, boolean
) from public;

grant execute on function public.create_appointment_request(
  text, text, text, bigint, timestamptz, text, text, boolean
) to anon, authenticated;

-- NOTE:
-- The current prototype admin PIN is NOT database authentication.
-- Therefore customers/appointments are not opened for remote admin reading here.
-- Add Supabase Auth + an owner role before granting Robert full remote access.
