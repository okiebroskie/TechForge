# Manual Firebase setup for TechForge (no Firebase Storage required)

## 1. Create/use your Firebase project
1. Go to https://console.firebase.google.com/.
2. Open your TechForge project: `techforge-e-commerce-system`.
3. Use this same project for the Flutter app and the web admin dashboard.

## 2. Enable Authentication
1. Open Build → Authentication → Get started.
2. Under Sign-in method, enable Email/Password.
3. Create your administrator login under Authentication → Users → Add user.
4. Copy the administrator user's UID.

## 3. Create Cloud Firestore
1. Open Build → Firestore Database → Create database.
2. Choose production mode and select a database location.

## 4. Register/check the web app configuration
1. Open Project settings → General → Your apps.
2. Check that the registered web app belongs to `techforge-e-commerce-system`.
3. The provided `admin/firebase-config.js` is already filled with the web config you supplied. If you use another Firebase project, replace those values with that project's Web App config.

## 5. Add the admin role document
1. Open Firestore → Data.
2. Create/open collection `users`.
3. Create a document whose ID is the administrator Authentication UID exactly.
4. Add fields:
   - `fullName` — string — `TechForge Administrator`
   - `email` — string — the admin email
   - `role` — string — `admin`
5. Save. The admin dashboard checks this role before showing its pages.

For normal customers, the Flutter app should create `users/{uid}` with `role: customer`. Never let a public user assign themselves the admin role.

## 6. Publish Firestore security rules
1. Open Firestore Database → Rules.
2. Replace the rules with the contents of `firebase/firestore.rules`.
3. Click Publish.

## 7. Configure Flutter mobile app
1. Install Flutter SDK and Android Studio.
2. Open a terminal in `mobile/`.
3. If the Flutter platform folders are missing, run `flutter create .`.
4. Run `flutter pub get`.
5. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`.
6. Run `flutterfire configure` and select the same TechForge Firebase project and Android app.
7. Run `flutter run`.

## 8. Run the HTML/CSS/JavaScript admin dashboard (no Node/npm)
1. Open the `admin/` folder in Visual Studio Code.
2. Install the VS Code extension **Live Server**.
3. Right-click `admin/index.html` and choose **Open with Live Server**.
4. Sign in with the administrator email and password created in Firebase Authentication.

You do not need Node.js, npm, React, Vite, TypeScript, or Firebase Storage for this admin dashboard. It loads Firebase's browser SDK modules from Google's CDN, so an internet connection is required.

## 9. Test both applications
1. Register a customer in the Flutter app.
2. Add a product through the admin dashboard.
3. Confirm the product appears in the Flutter catalog.
4. Place a test order from Flutter.
5. Confirm it appears in Admin → Orders.
6. Change the order status in the admin dashboard.
7. Confirm the customer app reflects the updated status.

## Firestore data fields
- `users/{uid}`: `fullName`, `email`, `phoneNumber`, `role` (`customer` or `admin`), `createdAt`
- `products/{productId}`: `productName`, `brand`, `category`, `description`, `price` (number), `stock` (integer), `imageUrl`, `createdAt`, `updatedAt`
- `orders/{orderId}`: `userId`, `customerName`, `contactNumber`, `deliveryAddress`, `items`, `totalAmount`, `paymentMethod`, `orderStatus`, `createdAt`, `updatedAt`

## Product images without Firebase Storage
The product form accepts an image URL. Use an image URL that can be opened publicly in a browser. The dashboard stores only that URL in Firestore; it does not upload or host the image.

## Common problems
- `permission-denied`: check that Firestore rules are published and that the admin account has a `users/{AUTH_UID}` document with `role: admin`.
- Admin access denied: ensure the Firestore document ID is exactly the Authentication UID.
- Blank page/module error: use Live Server or another local HTTP server instead of opening `index.html` directly with `file://`; check internet connectivity.
- Products missing in Flutter: confirm both apps use the same Firebase project and `products` collection.
