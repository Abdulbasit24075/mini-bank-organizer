# Mini Bank Organizer / Family Billing App

## Project Title and Description

**Project Title:** Mini Bank Organizer / Family Billing App

Mini Bank Organizer, also called Family Billing App, is a Flutter and Firebase based mobile application designed to manage billing relationships between two roles: **Admin** and **Biller**.

The application works like a small ledger system. An admin can add billers, view each biller's ledger, pay combined amounts, check bill history, export statements, manage notebooks, and request history clearing. A biller can create bills, view ledger information, confirm manual online payment requests, and approve or reject clear-history requests.

The main purpose of this project is to keep billing records organized, transparent, and separated for every admin-biller relationship.

## Objectives of the Project

The objectives of this project are:

- To provide a simple digital billing system for admins and billers.
- To allow a biller to create bills for an assigned admin.
- To allow an admin to pay combined bill amounts.
- To maintain accurate ledger totals including total bills, total paid, and current balance.
- To keep payment history and bill history available for review.
- To support PDF statement export for admin-biller records.
- To provide notebook summaries before clearing history.
- To support manual online payment proof requests for JazzCash and Easypaisa without using real payment gateways.
- To allow history clearing only after confirmation from both sides.
- To keep records separated so one biller's data does not affect another biller's data.

## Scope of the Project

This project covers the following areas:

- User registration and login.
- Role-based access for Admin and Biller.
- Admin-to-biller linking.
- Ledger management for each admin-biller pair.
- Bill creation by billers.
- Combined payment by admins.
- Payment history tracking.
- Bill history tracking.
- Statistics screen for viewing summary information.
- PDF export for admin-biller statements.
- Personal notebook module for admins and billers.
- Manual online payment proof workflow.
- Clear history request and approval flow.

The project does not include real payment gateway integration. JazzCash and Easypaisa are used only as manual proof/request options. No merchant ID, secret key, gateway API, or Cloud Function payment integration is used.

The Gemini price checker/API-key feature has been removed from the project.

## Technology Stack

The project uses:

- **Flutter** for the mobile application frontend.
- **Dart** as the programming language.
- **Firebase Authentication** for user signup and login.
- **Cloud Firestore** as the database.
- **Firebase Core** for Firebase initialization.
- **Provider** where app state management support is needed.
- **PDF and Printing packages** for PDF statement generation and preview/share.
- **Intl package** for date and time formatting.

## Main Roles

### Admin

The admin is the person who manages billers and pays combined amounts. An admin can add billers, view linked billers, open a specific biller's account, pay amounts, send online payment proof requests, export PDF statements, use notebooks, and request clear history.

### Biller

The biller is the person who creates bills and confirms admin payment proof. A biller belongs to one admin. The biller can create bills, view ledger details, check history, use a personal notebook, confirm or reject online payment requests, and approve or reject clear-history requests.

## Firebase Collections

The application uses Cloud Firestore collections to store data.

### users

Stores registered user information.

Common fields:

- uid
- name
- email
- role

The role is either `admin` or `biller`.

### relations

Stores the relationship between an admin and a biller.

Important fields:

- createdBy
- linkedUserId
- linkedUserRole
- createdAt

This collection helps identify which billers belong to which admin.

### ledgers

Stores ledger totals for a specific admin-biller pair.

Important fields:

- adminId
- billerId
- totalBills
- totalPaid
- balance
- clearRequestPending

The ledger is the central summary of all bills and payments between one admin and one biller.

### bills

Stores bills created by billers.

Important fields:

- adminId
- billerId
- title
- totalAmount
- createdAt

When a biller creates a bill, the bill is stored here and the ledger total bills and balance are updated.

### payments

Stores payment history records.

Important fields:

- adminId
- billerId
- paidAmount
- balanceAfterPayment
- paidAt

Normal admin payments and confirmed online payment requests both create regular payment history using the same ledger payment logic.

### notebooks

Stores saved notes and summary snapshots.

Important fields:

- ownerId
- ownerRole
- adminId
- billerId
- billerName
- monthDetail
- comment
- totalBills
- totalPaid
- balance
- createdAt

The notebook allows admins and billers to save summaries before clearing history or whenever they want to keep a record.

### online_payment_requests

Stores manual online payment proof requests.

Important fields:

- adminId
- billerId
- amount
- paymentApp
- referenceNumber
- note
- status
- createdAt
- confirmedAt
- rejectedAt

The status can be:

- pending
- confirmed
- rejected

This collection is only for manual proof. It does not directly update the ledger until the biller confirms the request.

## Implementation Details

### Authentication

The app uses Firebase Authentication for login and signup. During signup, the user selects a role. The role decides whether the user opens the Admin Dashboard or the Biller Dashboard after login.

### Role-Based Navigation

After login:

- Admin users are sent to the Admin Dashboard.
- Biller users are sent to the Biller Dashboard.

This keeps the admin and biller workflows separate.

### Admin-Biller Relationship

An admin can add a biller by linking to an existing biller account. The app prevents adding non-biller users as billers. It also prevents a biller from being linked to more than one admin.

When a biller is added, a ledger is created for that admin-biller pair.

### Ledger Logic

The ledger stores:

- Total Bills
- Total Paid
- Balance

Balance is calculated from bills and payments.

If balance is positive, it means remaining amount exists.

If balance is negative, it means advance amount exists.

### Bill Creation

Billers create bills from their dashboard. When a bill is created:

1. A bill document is added to the `bills` collection.
2. The related ledger total bills increases.
3. The ledger balance increases.

Only the biller's assigned admin-biller relationship is affected.

### Normal Payment

Admin can pay a combined amount from the selected biller's ledger screen.

When the admin uses the normal Pay button:

1. The payment amount is validated.
2. A payment document is created in the `payments` collection.
3. The ledger total paid increases.
4. The ledger balance decreases.
5. Payment history is updated.

This is the main payment flow of the application.

### Manual Online Payment Proof

The app includes a manual online payment proof workflow for JazzCash and Easypaisa.

This is not real payment gateway integration.

Admin flow:

1. Admin opens a selected biller's ledger screen.
2. Admin taps Online Pay.
3. Admin selects JazzCash or Easypaisa.
4. Admin enters amount, reference number, and optional note.
5. A pending request is created in `online_payment_requests`.
6. Ledger is not updated yet.
7. Payment history is not created yet.

Biller flow:

1. Biller sees a badge count on the online payment request button.
2. Biller opens pending requests.
3. Biller can confirm or reject the request.

Confirm result:

- The app calls the existing normal payment logic.
- Ledger updates.
- Payment history is created.
- Online request status becomes confirmed.

Reject result:

- Request status becomes rejected.
- Ledger is not updated.
- Payment history is not created.

### Payment History

Payment history displays records from the `payments` collection. It remains unchanged and continues to show normal payment records. Confirmed online payment requests use the same normal payment logic, so they also appear as standard payment history after confirmation.

### Bill History

Bill history displays bills created between the selected admin and biller. Admins can view a selected biller's bill history, and billers can view their own bill history.

### Statistics

Statistics screens provide summarized information about bills, payments, and current ledger balance. This helps users understand account status quickly.

### PDF Export

The admin can export a PDF statement for a selected biller.

The PDF includes:

- Family Billing App heading
- Admin-Biller Statement title
- Generated date and time
- Admin name
- Biller name
- Ledger summary
- Bills history
- Payment history
- Final remaining or advance status

Statistics are not included in the PDF export.

### Notebook Module

The notebook module lets users save a snapshot of ledger information with a month detail and optional comment.

Admin notebook:

- Admin can access notebooks from the Admin Dashboard.
- Admin has a separate notebook for each biller.
- Admin notebook records are personal to the admin.

Biller notebook:

- Biller has a personal notebook from the Biller Dashboard.
- Biller notebook records are personal to the biller.

Notebook records can be:

- Created
- Edited
- Deleted

The notebook is useful before clearing history because users can save a summary first.

### Clear History Request

History clearing requires confirmation from both sides.

Admin flow:

1. Admin requests clear history for a selected biller.
2. The ledger marks that a clear request is pending.

Biller flow:

1. Biller sees the clear request.
2. Biller can approve or reject it.

If biller approves:

- Bills for that admin-biller pair are deleted.
- Payments for that admin-biller pair are deleted.
- Online payment requests for that admin-biller pair are deleted.
- Ledger totals are reset.

Other billers and other admin-biller relationships remain unaffected.

If biller rejects:

- History remains unchanged.
- Clear request status is removed.

## Features and Functionalities

### Admin Features

- Register as admin.
- Login as admin.
- View admin dashboard.
- Add biller accounts.
- View linked billers.
- Open a biller's ledger account.
- View total bills, total paid, remaining amount, or advance amount.
- View bill history of a selected biller.
- View statistics of a selected biller.
- Pay combined amount using the normal Pay button.
- Send manual online payment proof request.
- Export PDF statement for a selected biller.
- Request clear history.
- Open admin notebooks from dashboard.
- Create notebook summaries.
- Edit notebook records.
- Delete notebook records.

### Biller Features

- Register as biller.
- Login as biller.
- View biller dashboard.
- View assigned admin.
- Create bills.
- View own bill history.
- View ledger summary.
- View statistics.
- Open personal notebook.
- Create notebook summaries.
- Edit notebook records.
- Delete notebook records.
- Receive online payment request badge.
- Confirm online payment proof requests.
- Reject online payment proof requests.
- Approve clear history request.
- Reject clear history request.

## Important Workflows

### Workflow 1: Admin Adds Biller

1. Biller creates an account.
2. Admin logs in.
3. Admin opens Add Biller.
4. Admin links the biller.
5. App creates relationship record.
6. App creates ledger record.

### Workflow 2: Biller Creates Bill

1. Biller opens Create Bill.
2. Biller enters bill title and amount.
3. App saves bill in Firestore.
4. Ledger total bills increases.
5. Ledger balance increases.

### Workflow 3: Admin Pays Normally

1. Admin opens selected biller ledger.
2. Admin enters payment amount.
3. Admin taps Pay.
4. App creates payment history.
5. App updates total paid.
6. App updates balance.

### Workflow 4: Admin Sends Online Payment Proof

1. Admin opens selected biller ledger.
2. Admin taps Online Pay.
3. Admin selects JazzCash or Easypaisa.
4. Admin enters amount and reference number.
5. App creates pending online payment request.
6. Ledger is not changed.
7. Payment history is not changed.

### Workflow 5: Biller Confirms Online Payment

1. Biller sees pending request badge.
2. Biller opens online payment requests.
3. Biller reviews amount, app name, reference number, note, and date.
4. Biller taps Confirm.
5. App uses normal payment logic.
6. Ledger updates.
7. Payment history is created.
8. Request status becomes confirmed.

### Workflow 6: Biller Rejects Online Payment

1. Biller opens pending request.
2. Biller taps Reject.
3. Request status becomes rejected.
4. Ledger remains unchanged.
5. Payment history remains unchanged.

### Workflow 7: Save Notebook Summary

1. User opens notebook.
2. User taps Create Summary.
3. User enters month detail.
4. User optionally adds comment.
5. App captures current ledger snapshot.
6. Summary is saved in personal notebook.

### Workflow 8: Clear History

1. Admin requests clear history.
2. Biller receives request.
3. Biller approves or rejects.
4. If approved, records for only that admin-biller pair are cleared.
5. Other billers and other histories remain safe.

## Data Separation

The project keeps data separated by using both `adminId` and `billerId`.

This means:

- One admin's records with one biller are separate from the same admin's records with another biller.
- One biller's records do not affect another biller's records.
- Clearing history affects only the selected admin-biller pair.
- PDF export is generated only for the selected admin-biller relationship.
- Online payment requests are shown only to the correct biller.

## Safety Notes

- The project does not use real JazzCash API.
- The project does not use real Easypaisa API.
- The project does not use payment gateway keys.
- The online payment feature is only a manual proof/request system.
- Ledger updates only after biller confirmation for online payment proof.
- Normal Pay button remains the main direct payment workflow.
- Existing payment history structure remains unchanged.
- Gemini price checker and API-key related code has been removed.

## Instructions for Running the Project

### Step 1: Open the Project

Open Android Studio and open this folder:

`C:\src\mini_bank_organizer`

### Step 2: Get Packages

Open the terminal inside Android Studio and run:

```bash
flutter pub get
```

This downloads the Flutter packages used by the app.

### Step 3: Connect Device

Connect an Android phone with USB debugging enabled.

You can also use an Android emulator if available.

### Step 4: Check Devices

Run:

```bash
flutter devices
```

Make sure your Android device appears in the list.

### Step 5: Analyze the Project

Run:

```bash
flutter analyze
```

This checks the project for code issues.

### Step 6: Run the App

Use the Run button in Android Studio, or run:

```bash
flutter run
```

If more than one device is connected, choose the Android mobile device.

### Step 7: Test Admin Flow

1. Signup or login as admin.
2. Add a biller.
3. Open the linked biller.
4. View ledger.
5. Pay combined amount.
6. Export PDF.
7. Open notebooks.
8. Send online payment request.
9. Request clear history.

### Step 8: Test Biller Flow

1. Signup or login as biller.
2. Confirm the biller is linked with admin.
3. Create a bill.
4. View bill history.
5. View ledger and statistics.
6. Open notebook.
7. Confirm or reject online payment requests.
8. Approve or reject clear history request.

## Testing Checklist

Use this checklist to verify the project:

- Admin can register and login.
- Biller can register and login.
- Admin can add a biller.
- Biller cannot be added to multiple admins.
- Biller can create a bill.
- Ledger updates after bill creation.
- Admin can pay combined amount.
- Payment history is created after normal payment.
- Admin can send online payment proof request.
- Biller receives pending request badge.
- Biller can confirm online payment request.
- Ledger updates after confirmation.
- Payment history is created after confirmation.
- Biller can reject online payment request.
- Rejected request does not update ledger.
- Admin can view bill history.
- Biller can view bill history.
- Statistics screen works.
- Admin can export PDF.
- Admin notebook works.
- Biller notebook works.
- Notebook records can be edited and deleted.
- Admin can request clear history.
- Biller can approve clear history.
- Clear history affects only the selected admin-biller pair.
- Other billers' histories remain unchanged.

## Conclusion

Mini Bank Organizer / Family Billing App is a complete Flutter and Firebase based ledger application for managing admin-biller billing relationships. It supports bill creation, combined payments, ledger tracking, history management, PDF export, notebooks, manual online payment proof requests, and controlled history clearing.

The project is designed to keep records clear, separated, and easy to review for both admins and billers.
