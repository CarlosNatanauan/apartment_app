Rent Payment Tracking + Landlord Dashboard + New Features
Context

RoomLease already stores monthlyRent, rentStartDate, and paymentDueDay.

There is currently no model to record whether a tenant has actually paid for a given month. This plan adds a RentPayment model for month-by-month payment records, landlord endpoints to view and mark payments, and tenant endpoints to see their own status. It also proposes two lightweight new features.

Critical Files to Modify

prisma/schema.prisma — add RentPayment model

src/room-leases/room-leases.service.ts — markPaid, getPayments

src/room-leases/room-leases.controller.ts — new payment routes

New module: src/payments/ — landlord dashboard aggregations

1. Schema: RentPayment Model

Add to prisma/schema.prisma:

model RentPayment {
  id          String    @id @default(uuid())
  roomLeaseId String
  periodYear  Int       // e.g. 2026
  periodMonth Int       // 1–12
  amount      Int       // copy of monthlyRent at time of payment (in smallest unit, e.g. cents)
  paidAt      DateTime?             // null = not yet paid
  markedByUserId String?            // landlord who marked it
  note        String?               // optional note from landlord

  createdAt   DateTime  @default(now())

  roomLease   RoomLease @relation(fields: [roomLeaseId], references: [id], onDelete: Restrict)
  markedBy    User?     @relation("PaymentMarkedBy", fields: [markedByUserId], references: [id])

  @@unique([roomLeaseId, periodYear, periodMonth])  // one record per lease per month
  @@index([roomLeaseId])
  @@index([paidAt])
  @@index([periodYear, periodMonth])
}

Also add back-relations:

model RoomLease {
  ...
  rentPayments RentPayment[]
}

model User {
  ...
  markedPayments RentPayment[] @relation("PaymentMarkedBy")
}

Migration note:
amount Int copies the lease's monthlyRent at the time of creation. This preserves the historical value if rent later changes.

2. Business Logic
Auto-generate payment records

When the current month's payment record doesn't exist yet for an ACTIVE lease, create it on-demand (lazy creation) when:

Landlord views the dashboard

Landlord marks a tenant as paid

Tenant views their payment status

This avoids needing a cron job for now.

"Mark as paid" flow (landlord)

POST /room-leases/:leaseId/payments/mark-paid

Body:

{ "periodYear": 2026, "periodMonth": 2, "note": "Cash" }

Upserts a RentPayment record

Sets paidAt = now()

Sets markedByUserId = actorId

Sets amount = lease.monthlyRent

Returns:

{ leaseId, periodYear, periodMonth, paidAt, note }
Determine overdue

A payment is overdue when:

Today's date > paymentDueDay of the current month

The current month's RentPayment record has paidAt = null (or doesn't exist yet)

No new model field needed — computed at query time.

3. Endpoints
3a. Landlord dashboard summary

GET /spaces/:spaceId/payments/summary
Role: LANDLORD, ADMIN

Returns:

{
  "ok": true,
  "data": {
    "periodYear": 2026,
    "periodMonth": 2,
    "totalExpected": 450000,
    "totalPaid": 150000,
    "totalUnpaid": 300000,
    "overdueCount": 2,
    "tenants": [
      {
        "spaceMembershipId": "uuid",
        "tenant": {
          "userId": "uuid",
          "firstName": "Ana",
          "lastName": "Reyes",
          "email": "..."
        },
        "roomLeases": [
          {
            "leaseId": "uuid",
            "roomNumber": "101",
            "monthlyRent": 150000,
            "paymentDueDay": 15,
            "payment": {
              "paymentId": "uuid",
              "paidAt": "2026-02-10T...",
              "note": "Cash"
            },
            "isOverdue": false
          }
        ]
      }
    ]
  }
}

Query accepts optional:

?year=2026&month=2
3b. Mark as paid

POST /room-leases/:leaseId/payments/mark-paid
Role: LANDLORD, ADMIN

Body:

{ "periodYear": 2026, "periodMonth": 2, "note": "Bank transfer" }
3c. Unmark as paid (correction)

POST /room-leases/:leaseId/payments/unmark-paid
Role: LANDLORD, ADMIN

Body:

{ "periodYear": 2026, "periodMonth": 2 }

Sets paidAt = null on the record.

3d. Tenant: view own payment status

GET /memberships/me/payments?year=2026&month=2
Role: TENANT

Returns:

{
  "ok": true,
  "data": [
    {
      "leaseId": "uuid",
      "spaceName": "Maple Apartments",
      "roomNumber": "101",
      "monthlyRent": 150000,
      "paymentDueDay": 15,
      "payment": { "paidAt": null },
      "isOverdue": true
    }
  ]
}
3e. Lease payment history

GET /room-leases/:leaseId/payments
Role: LANDLORD or TENANT

Returns all RentPayment rows for that lease, ordered by year/month desc.

4. New Feature Recommendations
Feature A — Space Notices / Announcements

Why: Landlord needs to communicate with all tenants at once (water shutdown, rule changes, community events). Currently no broadcast channel exists.

Schema addition:
model SpaceNotice {
  id        String    @id @default(uuid())
  spaceId   String
  authorId  String
  title     String
  content   String
  expiresAt DateTime?
  createdAt DateTime  @default(now())

  space  Space @relation(fields: [spaceId], references: [id])
  author User  @relation(fields: [authorId], references: [id])

  @@index([spaceId])
  @@index([createdAt])
}
Endpoints:

POST /spaces/:spaceId/notices — LANDLORD/ADMIN creates

GET /spaces/:spaceId/notices — any member reads (active + non-expired)

DELETE /spaces/:spaceId/notices/:noticeId — LANDLORD/ADMIN deletes

Flutter UI: Notices feed on tenant home screen; bell icon for landlord to post.

Feature B — Upcoming Due Dates Widget (no new model)

Why: Landlord wants a quick list of who is due in the next N days.

GET /spaces/:spaceId/payments/upcoming?days=7
Role: LANDLORD, ADMIN

No new schema. Queries ACTIVE leases where paymentDueDay falls within the next days calendar days and paidAt = null for the current month.

{
  "ok": true,
  "data": [
    {
      "leaseId": "uuid",
      "tenant": { "firstName": "Ana", "lastName": "Reyes" },
      "roomNumber": "101",
      "monthlyRent": 150000,
      "dueDateThisMonth": "2026-02-25",
      "daysUntilDue": 4
    }
  ]
}

Flutter UI: Card on landlord dashboard.
"4 payments due in the next 7 days."

5. Implementation Order

Schema — Add RentPayment model + back-relations in prisma/schema.prisma

Migration — npx prisma migrate dev --name add_rent_payment

RoomLeasesService — add markPaid, unmarkPaid, getPayments methods

RoomLeasesController — add payment routes

Dashboard endpoint — add getSummary + getUpcoming in spaces module

Tenant payments endpoint — add myPayments method

SpaceNotice feature — new src/notices/ module

6. What Gets Added (Full Summary)
New DB table

RentPayment — one row per lease per calendar month

New endpoints (9 total)
Method	URL	Role	Purpose
GET	/spaces/:spaceId/payments/summary	LANDLORD	Dashboard: all tenants + payment status
GET	/spaces/:spaceId/payments/upcoming	LANDLORD	Tenants due in next N days
POST	/room-leases/:leaseId/payments/mark-paid	LANDLORD	Mark a month as paid
POST	/room-leases/:leaseId/payments/unmark-paid	LANDLORD	Undo a mistaken mark
GET	/room-leases/:leaseId/payments	LANDLORD or TENANT	Full payment history
GET	/memberships/me/payments	TENANT	Tenant's own payment status
POST	/spaces/:spaceId/notices	LANDLORD	Post an announcement
GET	/spaces/:spaceId/notices	Any member	Read announcements
DELETE	/spaces/:spaceId/notices/:noticeId	LANDLORD	Delete announcement
7. Impact on Existing Features

None of the existing endpoints are modified.

All new models are additive.

8. Postman Testing Guide
Setup Environment Variables
baseUrl = http://localhost:3000
landlordToken = (login as LANDLORD, copy JWT)
tenantToken   = (login as TENANT, copy JWT)
spaceId       = (spaceId with at least one ACTIVE tenant)
leaseId       = (leaseId of one ACTIVE RoomLease)
Landlord Flow

View payment dashboard
GET /spaces/{{spaceId}}/payments/summary

View upcoming due dates
GET /spaces/{{spaceId}}/payments/upcoming?days=30

Mark tenant as paid
POST /room-leases/{{leaseId}}/payments/mark-paid

Re-run dashboard

Undo mark
POST /room-leases/{{leaseId}}/payments/unmark-paid

View full payment history
GET /room-leases/{{leaseId}}/payments

Post a notice
POST /spaces/{{spaceId}}/notices

Tenant Flow

Check own payment status
GET /memberships/me/payments?year=2026&month=2

View payment history
GET /room-leases/{{leaseId}}/payments

Read notices
GET /spaces/{{spaceId}}/notices

Error Cases to Test
Scenario	Expected
Tenant tries to mark-paid	403 Forbidden
Landlord marks wrong space lease	403 Forbidden
Mark paid twice	Upsert updates, no 409
GET /memberships/me/payments as LANDLORD	403 Forbidden
View another tenant lease history	403 Forbidden