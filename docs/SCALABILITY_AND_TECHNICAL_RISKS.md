# LaganStaff — Scalability Architecture & Technical Risk Mitigation

**Document Version:** 1.0.0  
**Status:** Approved for Phase 0 Planning  
**Target Profile:** Ghazipur MVP Launch scaling to 10,000+ Active Users  

---

## 1. Architectural Philosophy on Scalability

> [!IMPORTANT]
> **No Premature Optimization Rule:**  
> For the Ghazipur MVP, LaganStaff strictly rejects unnecessary operational complexity such as external Redis caches, Kafka clusters, or distributed microservices. A single, well-architected PostgreSQL instance paired with Supabase connection pooling (PgBouncer) easily supports 10,000+ active daily users and hundreds of concurrent bookings when proper indexing and transactions are in place.

---

## 2. Technical Risk Matrix & Architected Mitigations

| # | Technical Risk | Impact Level | Primary Vulnerability | Architected Mitigation (MVP Native) |
| :- | :--- | :---: | :--- | :--- |
| **1** | **Booking Race Conditions** | **CRITICAL** | Multiple workers accepting the last open slot simultaneously, resulting in over-allocation. | Atomic PostgreSQL stored procedure with `SELECT ... FOR UPDATE` row-level locks on the `jobs` row during applicant confirmation. |
| **2** | **Connection Exhaustion (1,000+ Users)** | **HIGH** | Peak wedding season traffic depletes direct PostgreSQL client connections. | Utilize Supabase's built-in **PgBouncer** in Transaction Mode. Mobile clients connect over stateless HTTPS PostgREST without holding open database sockets. |
| **3** | **Slow Mobile Internet in Ghazipur** | **HIGH** | Latency and connection drops on 2G/3G networks during profile creation or job feed loads. | 1. Implement client-side response caching with cache-first policies for static data (Categories, Skills).<br/>2. Paginated job feed fetching (`LIMIT 20 OFFSET X`).<br/>3. Network retry policies with exponential backoff. |
| **4** | **Unbounded Storage Growth (Selfies)** | **MEDIUM** | Large uncompressed camera images (5MB–10MB) rapidly exhaust Supabase Storage quotas and slow uploads. | Compulsory on-device image downscaling in Flutter using `flutter_image_compress` before transmission (target: $\le 300\text{ KB}$, WebP/JPEG, max 1080px dimension). |
| **5** | **SMS Gateway Latency & Indian DLT** | **HIGH** | SMS OTP delays or delivery failures due to Indian Telecom DLT filtering during peak registration. | 1. Implement 60-second resend cooldown timer on UI.<br/>2. DLT-registered transactional message template.<br/>3. Fallback SMS provider routing via Supabase Edge Function if primary fails. |
| **6** | **Database Query Degradation** | **MEDIUM** | Slow filtering on active jobs as the historical job count grows past tens of thousands. | Composite B-Tree indexes on `(status, shift_date)` and partial indexes on active listings: `CREATE INDEX ... WHERE status = 'published'`. |
| **7** | **Geographical Expansion Beyond Ghazipur** | **LOW (MVP)** | Simple string-matching on locality becomes inadequate as operations expand to Varanasi, Gorakhpur, Mau. | Schema is pre-designed with `city`, `latitude`, and `longitude` fields. Phase 0 uses bounding-box Haversine calculation in SQL; PostGIS spatial indexing (`ST_DWithin`) can be enabled seamlessly in later phases. |
| **8** | **Disaster Recovery & Data Loss** | **HIGH** | Accidental data corruption, catastrophic database drop, or bad script execution. | Supabase automated daily backups with **Point-In-Time-Recovery (PITR)** enabled, allowing restoration to any second within a 7-day window. |

---

## 3. High-Concurrency Application Flow (Deep Dive)

### 3.1 The Scenario
At 6:00 PM on the day before a major wedding date in Ghazipur, a banquet owner posts an urgent requirement for **15 Waiters**. A broadcast notification attracts **200 workers** within 5 minutes.

### 3.2 The Risk
If application or confirmation logic executes via multiple uncoordinated client calls:
- Owner clicks "Accept" on 15 workers rapidly.
- Network latency causes multiple clicks to overlap.
- Workers accept simultaneously.

### 3.3 The Native PostgreSQL Solution
LaganStaff resolves this natively inside PostgreSQL via a deterministic RPC:

```sql
-- Architecture specification for future implementation (Phase 8/9)
CREATE OR REPLACE FUNCTION accept_worker_booking(
  p_job_id UUID,
  p_application_id UUID,
  p_owner_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_needed INT;
  v_confirmed INT;
  v_worker_id UUID;
  v_business_id UUID;
  v_wage NUMERIC;
BEGIN
  -- 1. Exclusively lock the job row to serialize concurrent actions
  SELECT workers_needed, workers_confirmed, business_id, wage_amount
  INTO v_needed, v_confirmed, v_business_id, v_wage
  FROM jobs
  WHERE id = p_job_id
  FOR UPDATE;

  -- 2. Verify authorization
  IF NOT EXISTS (
    SELECT 1 FROM business_members 
    WHERE business_id = v_business_id AND user_id = p_owner_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
  END IF;

  -- 3. Check capacity boundary
  IF v_confirmed >= v_needed THEN
    RETURN jsonb_build_object('success', false, 'error', 'CAPACITY_REACHED');
  END IF;

  -- 4. Get worker profile id
  SELECT worker_profile_id INTO v_worker_id
  FROM job_applications
  WHERE id = p_application_id AND job_id = p_job_id;

  -- 5. Atomically increment confirmed count
  UPDATE jobs 
  SET workers_confirmed = workers_confirmed + 1,
      status = CASE WHEN (workers_confirmed + 1) >= v_needed THEN 'filled'::job_status ELSE status END,
      updated_at = NOW()
  WHERE id = p_job_id;

  -- 6. Update application status
  UPDATE job_applications 
  SET status = 'accepted', updated_at = NOW() 
  WHERE id = p_application_id;

  -- 7. Insert booking record
  INSERT INTO bookings (job_id, application_id, worker_profile_id, business_id, agreed_wage, status)
  VALUES (p_job_id, p_application_id, v_worker_id, v_business_id, v_wage, 'confirmed');

  RETURN jsonb_build_object('success', true, 'remaining_slots', v_needed - (v_confirmed + 1));
END;
$$;
```

---

## 4. Multi-City Expansion Roadmap

```
┌────────────────────────────────────────────────────────┐
│                   PHASE 0-9: GHAZIPUR                  │
│  - Single district focus (Ghazipur town & rural blocks)│
│  - Text locality matching with basic GPS capture       │
│  - Single operations team managing first-job queue     │
└────────────────────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│             PHASE 10+: PURVANCHAL REGION               │
│  - Varanasi, Mau, Ballia, Gorakhpur                    │
│  - Enable PostGIS ST_DWithin for 15km radius matching  │
│  - City-level admin moderation roles                   │
│  - Vernacular localization (Bhojpuri voice prompts)    │
└────────────────────────────────────────────────────────┘
```
