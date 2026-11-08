TECHFORGE ADMIN DASHBOARD (PLAIN HTML/CSS/JAVASCRIPT)

This version does NOT require Node.js, npm, React, Vite, or TypeScript.
It connects directly to Firebase Authentication and Cloud Firestore using Firebase's browser SDK modules.
It does NOT use Firebase Storage. Product photos are displayed from image URLs.

SETUP
1. Open firebase-config.js in this folder.
2. Replace the placeholder values with your Firebase Web App configuration from Firebase Console > Project settings > Your apps.
3. Make sure Email/Password sign-in is enabled in Firebase Authentication.
4. Create your admin user in Authentication.
5. In Firestore, create users/{ADMIN_UID} with fields:
   fullName: "Administrator"
   email: "your-admin-email@example.com"
   role: "admin"
6. Publish the project's ../firebase/firestore.rules rules in Firestore Rules.
7. Run this folder using a local static web server (recommended) because browser ES modules may not work from file://.
   Easiest option: install the VS Code extension "Live Server", right-click index.html, choose "Open with Live Server".
   Or use any static hosting service such as Firebase Hosting.
8. Sign in using the admin email and password.

FEATURES
- Admin authentication and role verification
- Overview counts
- Product create, edit, delete
- Product image URL field (no Storage upload)
- Real-time orders list and status updates
- Customer list

FIRESTORE COLLECTIONS EXPECTED
users/{uid}: fullName, email, phoneNumber, role
products/{productId}: productName, brand, category, description, price, stock, imageUrl, createdAt, updatedAt
orders/{orderId}: userId, customerName, contactNumber, totalAmount, orderStatus, createdAt, items, etc.

SECURITY
Do not make Firestore rules public. The admin role must be assigned manually in Firestore by the project owner. The rules must enforce admin-only product writes and order status updates. A Firebase web config is not a service-account secret; never place service-account private keys in browser code.
